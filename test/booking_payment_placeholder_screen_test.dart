import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_hair_salon/features/customer/booking/domain/booking_flow_state.dart';
import 'package:mobile_hair_salon/features/customer/booking/presentation/providers/booking_flow_controller.dart';
import 'package:mobile_hair_salon/features/customer/booking/presentation/screens/booking_payment_placeholder_screen.dart';

void main() {
  testWidgets('submits request and resets payment status when live payments are unavailable', (
    tester,
  ) async {
    final controller = TestBookingFlowController(_seedState());

    await tester.pumpWidget(_buildTestApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit request'));
    await tester.pumpAndSettle();

    expect(find.text('submitted screen'), findsOneWidget);

    final updatedState = controller.state.valueOrNull;
    expect(updatedState, isNotNull);
    expect(updatedState!.submittedAppointmentId, 'appointment-123');
    expect(updatedState.paymentStatus, 'not_started');
  });

  testWidgets('goes directly to submitted when already authorized', (tester) async {
    final controller = TestBookingFlowController(
      _seedState().copyWith(
        submittedAppointmentId: 'appointment-existing',
        paymentStatus: 'authorized',
      ),
    );

    await tester.pumpWidget(_buildTestApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View submitted request').first);
    await tester.pumpAndSettle();

    expect(find.text('submitted screen'), findsOneWidget);

    final updatedState = controller.state.valueOrNull;
    expect(updatedState, isNotNull);
    expect(updatedState!.submittedAppointmentId, 'appointment-existing');
    expect(updatedState.paymentStatus, 'authorized');
  });

  testWidgets('shows error and marks failed when submission step throws', (
    tester,
  ) async {
    final controller = ThrowingBookingFlowController(_seedState());

    await tester.pumpWidget(_buildTestApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit request'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to create appointment for payment.'), findsOneWidget);
    expect(find.text('submitted screen'), findsNothing);

    final updatedState = controller.state.valueOrNull;
    expect(updatedState, isNotNull);
    expect(updatedState!.paymentStatus, 'failed');
    expect(updatedState.submittedAppointmentId, isNull);
  });
}

Widget _buildTestApp(TestBookingFlowController controller) {
  final router = GoRouter(
    initialLocation: '/customer/book/payment',
    routes: [
      GoRoute(
        path: '/customer/book/payment',
        builder: (context, state) => const BookingPaymentPlaceholderScreen(),
      ),
      GoRoute(
        path: '/customer/book/review',
        builder: (context, state) => const Scaffold(body: Text('review screen')),
      ),
      GoRoute(
        path: '/customer/book/submitted',
        builder: (context, state) => const Scaffold(body: Text('submitted screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      bookingFlowControllerProvider.overrideWith(() => controller),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class TestBookingFlowController extends BookingFlowController {
  TestBookingFlowController(this.seedState);

  final BookingFlowState seedState;

  @override
  Future<BookingFlowState> build() async => seedState;

  @override
  Future<void> submitBookingRequest() async {
    state = AsyncData(
      state.requireValue.copyWith(submittedAppointmentId: 'appointment-123'),
    );
  }
}

class ThrowingBookingFlowController extends TestBookingFlowController {
  ThrowingBookingFlowController(super.seedState);

  @override
  Future<String> ensureSubmittedAppointmentId() {
    throw Exception('Unable to create appointment for payment.');
  }
}

BookingFlowState _seedState() {
  const service = BookingServiceOption(
    id: 'service-1',
    name: 'Precision Haircut',
    description: 'A complete haircut service.',
    durationMinutes: 60,
    basePriceCents: 9500,
    allowsMultipleParticipants: false,
  );

  return BookingFlowState(
    householdId: 'household-1',
    householdName: 'The Smith Family',
    addresses: const [
      BookingAddressOption(
        id: 'address-1',
        marketId: 'market-1',
        territoryId: 'territory-1',
        label: 'Home',
        line1: '123 Main St',
        city: 'Mesa',
        state: 'AZ',
        postalCode: '85201',
        serviceAreaStatus: 'serviceable',
      ),
    ],
    householdMembers: const [
      BookingHouseholdMemberOption(
        id: 'member-1',
        firstName: 'Lena',
        lastName: 'Smith',
        dateOfBirth: null,
        generalNotes: null,
        sensoryNotes: null,
        hairNotes: null,
      ),
    ],
    services: const [service],
    selectedAddressId: 'address-1',
    selectedMemberIds: const {'member-1'},
    serviceItems: const [
      BookingServiceItem(
        id: 'item-1',
        service: service,
        assignedMemberId: 'member-1',
      ),
    ],
    customerNotes: '',
    preferredDate: DateTime(2026, 5, 20),
    preferredTimeWindow: 'morning',
    paymentStatus: 'failed',
    acceptedPolicy: true,
    submittedAppointmentId: null,
  );
}
