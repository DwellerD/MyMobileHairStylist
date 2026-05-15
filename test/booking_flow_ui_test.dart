import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_hair_salon/core/theme/app_theme.dart';
import 'package:mobile_hair_salon/features/customer/booking/domain/booking_flow_state.dart';
import 'package:mobile_hair_salon/features/customer/booking/presentation/providers/booking_flow_controller.dart';
import 'package:mobile_hair_salon/features/customer/booking/presentation/screens/booking_review_screen.dart';
import 'package:mobile_hair_salon/features/customer/booking/presentation/screens/service_selection_screen.dart';

void main() {
  testWidgets('service selection filters categories and continues to notes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final seedState = _buildSeedState();

    await tester.pumpWidget(
      _buildTestApp(
        initialLocation: '/customer/book/services',
        controller: TestBookingFlowController(seedState),
      ),
    );
    await tester.pumpAndSettle();

    final bookingList = find.byType(ListView).first;

    expect(find.text('Bob / Lob Haircut'), findsOneWidget);
    expect(find.text("Men's Haircut"), findsNothing);

    await tester.drag(bookingList, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Men'));
    await tester.pumpAndSettle();

    expect(find.text("Men's Haircut"), findsOneWidget);
    expect(find.text('Bob / Lob Haircut'), findsNothing);

    await tester.tap(find.text("Men's Haircut"));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue to notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to notes'));
    await tester.pumpAndSettle();

    expect(find.text('notes screen'), findsOneWidget);
  });

  testWidgets('message us button shows guidance snackbar', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final seedState = _buildSeedState();

    await tester.pumpWidget(
      _buildTestApp(
        initialLocation: '/customer/book/services',
        controller: TestBookingFlowController(seedState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Message Us'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message Us'));
    await tester.pump();

    expect(
      find.text(
        'Select a service or continue to notes if you want to describe what you need.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('review screen submits after policy acceptance', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final seedState = _buildSeedState().copyWith(
      selectedMemberIds: <String>{'member-1'},
      selectedServiceIds: <String>{'service-1'},
      preferredDate: DateTime(2026, 5, 20),
      preferredTimeWindow: 'morning',
      paymentStatus: 'not_started',
      acceptedPolicy: false,
    );

    await tester.pumpWidget(
      _buildTestApp(
        initialLocation: '/customer/book/review',
        controller: TestBookingFlowController(seedState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Submit booking request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit booking request'));
    await tester.pumpAndSettle();

    expect(find.text('submitted screen'), findsOneWidget);
  });
}

Widget _buildTestApp({
  required String initialLocation,
  required TestBookingFlowController controller,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/customer/book/services',
        builder: (context, state) => const ServiceSelectionScreen(),
      ),
      GoRoute(
        path: '/customer/book/household-members',
        builder: (context, state) => const Scaffold(body: Text('household screen')),
      ),
      GoRoute(
        path: '/customer/book/notes',
        builder: (context, state) => const Scaffold(body: Text('notes screen')),
      ),
      GoRoute(
        path: '/customer/book/review',
        builder: (context, state) => const BookingReviewScreen(),
      ),
      GoRoute(
        path: '/customer/book/payment',
        builder: (context, state) => const Scaffold(body: Text('payment screen')),
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
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
    ),
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

BookingFlowState _buildSeedState() {
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
    services: const [
      BookingServiceOption(
        id: 'service-1',
        name: 'Bob / Lob Haircut',
        description: 'Precision cut with a polished finish.',
        durationMinutes: 60,
        basePriceCents: 9500,
        allowsMultipleParticipants: false,
      ),
      BookingServiceOption(
        id: 'service-2',
        name: "Men's Haircut",
        description: 'Classic cut, taper, fade, or scissor finish.',
        durationMinutes: 45,
        basePriceCents: 7500,
        allowsMultipleParticipants: false,
      ),
      BookingServiceOption(
        id: 'service-3',
        name: 'Kids Haircut – Boys',
        description: 'Friendly in-home haircut for younger clients.',
        durationMinutes: 30,
        basePriceCents: 4500,
        allowsMultipleParticipants: false,
      ),
      BookingServiceOption(
        id: 'service-4',
        name: 'Scalp Treatment',
        description: 'Relaxing add-on for the appointment.',
        durationMinutes: 15,
        basePriceCents: 1500,
        allowsMultipleParticipants: false,
      ),
    ],
    selectedAddressId: 'address-1',
    selectedMemberIds: const <String>{},
    selectedServiceIds: const <String>{},
    customerNotes: '',
    photoDrafts: const <BookingPhotoDraft>[],
    preferredDate: null,
    preferredTimeWindow: null,
    paymentStatus: 'not_started',
    acceptedPolicy: false,
    submittedAppointmentId: null,
  );
}
