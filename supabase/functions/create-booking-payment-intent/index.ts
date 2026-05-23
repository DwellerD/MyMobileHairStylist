import Stripe from 'https://esm.sh/stripe@14.25.0?target=deno';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type PaymentIntentRequest = {
  appointmentId: string;
  amountCents?: number;
};

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed.' }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SERVICE_ROLE_KEY');
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY');

    if (!supabaseUrl || !serviceRoleKey || !stripeSecretKey) {
      return jsonResponse(
        {
          error:
            'Missing required environment variables. Configure SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (or SERVICE_ROLE_KEY), and STRIPE_SECRET_KEY before invoking this function.',
        },
        500,
      );
    }

    const authorization = request.headers.get('Authorization');
    if (!authorization?.startsWith('Bearer ')) {
      return jsonResponse({ error: 'Missing bearer token.' }, 401);
    }

    const jwt = authorization.replace('Bearer ', '');
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });
    const stripe = new Stripe(stripeSecretKey, {
      apiVersion: '2024-04-10',
      httpClient: Stripe.createFetchHttpClient(),
    });

    const { data: authData, error: authError } = await supabase.auth.getUser(jwt);
    if (authError || !authData.user) {
      return jsonResponse({ error: 'Invalid auth token.' }, 401);
    }

    const payload = (await request.json()) as PaymentIntentRequest;
    if (!payload.appointmentId) {
      return jsonResponse({ error: 'appointmentId is required.' }, 400);
    }

    const actorProfile = await loadActorProfile(supabase, authData.user.id);
    if (!actorProfile) {
      return jsonResponse({ error: 'User profile not found.' }, 403);
    }

    const appointment = await loadAppointmentScope(supabase, payload.appointmentId);
    if (!appointment) {
      return jsonResponse({ error: 'Appointment not found.' }, 404);
    }

    const isOwner = appointment.customer_profile.user_profile_id === actorProfile.id;
    const isScopedAdmin = await hasScopedAdminAccess(
      supabase,
      actorProfile.id,
      appointment.market_id,
      appointment.territory_id,
    );

    if (!isOwner && !isScopedAdmin) {
      return jsonResponse({ error: 'You do not have access to create a payment intent for this appointment.' }, 403);
    }

    const amountCents = payload.amountCents ?? appointment.estimated_total_cents;
    if (typeof amountCents !== 'number' || amountCents <= 0) {
      return jsonResponse(
        {
          error:
            'A positive amountCents is required when the appointment does not already have an estimated total.',
        },
        400,
      );
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountCents,
      currency: 'usd',
      automatic_payment_methods: { enabled: true },
      metadata: {
        appointment_id: appointment.id,
        market_id: appointment.market_id ?? '',
        territory_id: appointment.territory_id ?? '',
        customer_profile_id: appointment.customer_profile_id,
      },
      description: `My Mobile Hair Stylist booking ${appointment.id}`,
      receipt_email: appointment.customer_profile.user_profile.email,
    });

    const { error: paymentError } = await supabase.from('payments_placeholder').update({
      amount_cents: amountCents,
      currency_code: 'USD',
      status: 'pending',
      provider: 'stripe',
      payment_kind: 'deposit',
      payment_reference_type: 'payment_intent',
      external_reference: paymentIntent.id,
      payment_summary: 'Server-created Stripe PaymentIntent prepared for Payment Sheet.',
      updated_at: new Date().toISOString(),
    }).eq('appointment_id', appointment.id);

    if (paymentError) {
      return jsonResponse({ error: paymentError.message }, 500);
    }

    return jsonResponse({
      paymentIntentId: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      amountCents,
      currencyCode: 'USD',
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error.';
    return jsonResponse({ error: message }, 500);
  }
});

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

async function loadActorProfile(
  supabase: ReturnType<typeof createClient>,
  authUserId: string,
) {
  const { data, error } = await supabase
      .from('user_profiles')
      .select('id, default_market_id, default_territory_id')
      .eq('auth_user_id', authUserId)
      .maybeSingle();

  if (error) {
    throw error;
  }

  return data;
}

async function loadAppointmentScope(
  supabase: ReturnType<typeof createClient>,
  appointmentId: string,
) {
  const { data, error } = await supabase
      .from('appointments')
      .select(`
id,
market_id,
territory_id,
customer_profile_id,
estimated_total_cents,
customer_profile:customer_profiles!appointments_customer_profile_id_fkey(
  user_profile_id,
  user_profile:user_profiles!customer_profiles_user_profile_id_fkey(email)
)
`)
      .eq('id', appointmentId)
      .maybeSingle();

  if (error) {
    throw error;
  }

  return data;
}

async function hasScopedAdminAccess(
  supabase: ReturnType<typeof createClient>,
  actorUserProfileId: string,
  marketId: string | null,
  territoryId: string | null,
) {
  const { data, error } = await supabase
      .from('user_roles')
      .select('role, market_id, territory_id, status')
      .eq('user_profile_id', actorUserProfileId)
      .eq('status', 'active');

  if (error) {
    throw error;
  }

  return (data ?? []).some((role) => {
    if (role.role === 'corporate_admin') {
      return true;
    }

    if (role.role !== 'admin' && role.role !== 'franchisee') {
      return false;
    }

    if (marketId != null && role.market_id != null && role.market_id !== marketId) {
      return false;
    }

    if (territoryId != null && role.territory_id != null && role.territory_id !== territoryId) {
      return false;
    }

    return true;
  });
}