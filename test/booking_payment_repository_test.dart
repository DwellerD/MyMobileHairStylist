import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_hair_salon/features/customer/booking/data/booking_payment_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('BookingPaymentRepository.createPaymentIntent', () {
    test('returns parsed payment intent details on success', () async {
      final repository = BookingPaymentRepository(
        null,
        invoker: ({required functionName, required body}) async {
          expect(functionName, 'create-booking-payment-intent');
          expect(body['appointmentId'], 'appt-123');
          expect(body['amountCents'], 12500);
          return FunctionResponse(
            data: {
              'clientSecret': 'pi_abc_secret_123',
              'paymentIntentId': 'pi_abc',
              'amountCents': 12500,
              'currencyCode': 'USD',
            },
            status: 200,
          );
        },
      );

      final intent = await repository.createPaymentIntent(
        appointmentId: 'appt-123',
        amountCents: 12500,
      );

      expect(intent.clientSecret, 'pi_abc_secret_123');
      expect(intent.paymentIntentId, 'pi_abc');
      expect(intent.amountCents, 12500);
      expect(intent.currencyCode, 'USD');
    });

    test('omits amountCents when not provided', () async {
      final repository = BookingPaymentRepository(
        null,
        invoker: ({required functionName, required body}) async {
          expect(functionName, 'create-booking-payment-intent');
          expect(body['appointmentId'], 'appt-456');
          expect(body.containsKey('amountCents'), isFalse);
          return FunctionResponse(
            data: {
              'clientSecret': 'pi_def_secret_123',
              'paymentIntentId': 'pi_def',
              'amountCents': 9800,
              'currencyCode': 'USD',
            },
            status: 200,
          );
        },
      );

      final intent = await repository.createPaymentIntent(appointmentId: 'appt-456');

      expect(intent.amountCents, 9800);
      expect(intent.currencyCode, 'USD');
    });

    test('throws when function returns non-map payload', () async {
      final repository = BookingPaymentRepository(
        null,
        invoker: ({required functionName, required body}) async {
          return FunctionResponse(data: 'bad payload', status: 200);
        },
      );

      await expectLater(
        () => repository.createPaymentIntent(appointmentId: 'appt-789'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Unexpected payment function response'),
          ),
        ),
      );
    });

    test('throws function error from response payload', () async {
      final repository = BookingPaymentRepository(
        null,
        invoker: ({required functionName, required body}) async {
          return FunctionResponse(
            data: {'error': 'not authorized'},
            status: 403,
          );
        },
      );

      await expectLater(
        () => repository.createPaymentIntent(appointmentId: 'appt-777'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('not authorized'),
          ),
        ),
      );
    });

    test('throws if client secret or payment intent id is missing', () async {
      final repository = BookingPaymentRepository(
        null,
        invoker: ({required functionName, required body}) async {
          return FunctionResponse(
            data: {'paymentIntentId': 'pi_missing_secret'},
            status: 200,
          );
        },
      );

      await expectLater(
        () => repository.createPaymentIntent(appointmentId: 'appt-000'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('did not return a usable client secret'),
          ),
        ),
      );
    });

    test('throws configuration error when supabase client is unavailable', () async {
      final repository = BookingPaymentRepository(null);

      await expectLater(
        () => repository.createPaymentIntent(appointmentId: 'appt-no-client'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Supabase is not configured'),
          ),
        ),
      );
    });
  });
}
