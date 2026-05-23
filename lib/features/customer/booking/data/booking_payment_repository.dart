import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client_provider.dart';

typedef PaymentFunctionInvoker = Future<FunctionResponse> Function({
  required String functionName,
  required Map<String, dynamic> body,
});

final bookingPaymentRepositoryProvider = Provider<BookingPaymentRepository>((ref) {
  return BookingPaymentRepository(ref.watch(supabaseClientProvider));
});

class BookingPaymentRepository {
  BookingPaymentRepository(
    this._client, {
    PaymentFunctionInvoker? invoker,
  }) : _invoker = invoker;

  final SupabaseClient? _client;
  final PaymentFunctionInvoker? _invoker;

  Future<BookingPaymentIntent> createPaymentIntent({
    required String appointmentId,
    int? amountCents,
  }) async {
    final response = await _invokePaymentFunction(
      functionName: 'create-booking-payment-intent',
      body: {
        'appointmentId': appointmentId,
        ...?amountCents == null ? null : {'amountCents': amountCents},
      },
    );

    final rawData = response.data;
    if (rawData is! Map) {
      throw Exception('Unexpected payment function response.');
    }

    final data = Map<String, dynamic>.from(rawData.cast<Object?, Object?>());
    if (response.status >= 400) {
      throw Exception((data['error'] as String?) ?? 'Unable to create payment intent.');
    }

    final clientSecret = data['clientSecret'] as String?;
    final paymentIntentId = data['paymentIntentId'] as String?;
    if (clientSecret == null || paymentIntentId == null) {
      throw Exception('Payment function did not return a usable client secret.');
    }

    return BookingPaymentIntent(
      paymentIntentId: paymentIntentId,
      clientSecret: clientSecret,
      amountCents: (data['amountCents'] as num?)?.toInt() ?? amountCents ?? 0,
      currencyCode: (data['currencyCode'] as String?) ?? 'USD',
    );
  }

  SupabaseClient _requireClient() {
    if (_client == null) {
      throw Exception(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY before testing payments.',
      );
    }

    return _client;
  }

  Future<FunctionResponse> _invokePaymentFunction({
    required String functionName,
    required Map<String, dynamic> body,
  }) async {
    final invoker = _invoker;
    if (invoker != null) {
      return invoker(functionName: functionName, body: body);
    }

    return _requireClient().functions.invoke(functionName, body: body);
  }
}

class BookingPaymentIntent {
  const BookingPaymentIntent({
    required this.paymentIntentId,
    required this.clientSecret,
    required this.amountCents,
    required this.currencyCode,
  });

  final String paymentIntentId;
  final String clientSecret;
  final int amountCents;
  final String currencyCode;
}