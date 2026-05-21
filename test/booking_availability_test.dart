import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_hair_salon/core/theme/app_theme.dart';
import 'package:mobile_hair_salon/features/customer/booking/data/availability_repository.dart';
import 'package:mobile_hair_salon/features/customer/booking/domain/availability_slot.dart';
import 'package:mobile_hair_salon/features/customer/booking/domain/booking_flow_state.dart';
import 'package:mobile_hair_salon/features/customer/booking/presentation/providers/booking_flow_controller.dart';
import 'package:mobile_hair_salon/features/customer/booking/presentation/screens/available_slots_screen.dart';
import 'package:mobile_hair_salon/features/customer/booking/presentation/screens/stylist_selection_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Fake availability repository
// ──────────────────────────────────────────────────────────────────────────────

class FakeAvailabilityRepository extends AvailabilityRepository {
  FakeAvailabilityRepository({
    List<BookableStylist> stylists = const [],
    List<AvailableTimeSlot> slots = const [],
  })  : _stylists = stylists,
        _slots = slots,
        super(null);

  final List<BookableStylist> _stylists;
  final List<AvailableTimeSlot> _slots;

  @override
  Future<List<BookableStylist>> loadBookableStylists({
    required String marketId,
    String? requestedStylistId,
  }) async =>
      _stylists;

  @override
  Future<List<AvailableTimeSlot>> getAvailableSlots({
    required DateTime date,
    required int durationMinutes,
    required String marketId,
    String? requestedStylistId,
  }) async =>
      _slots;
}

// ──────────────────────────────────────────────────────────────────────────────
// Test controller
// ──────────────────────────────────────────────────────────────────────────────

class TestBookingController extends BookingFlowController {
  TestBookingController(this._seed);

  final BookingFlowState _seed;

  String? capturedStylistId;
  String? capturedStylistName;
  DateTime? capturedSlotStart;
  int? capturedSlotDuration;

  @override
  Future<BookingFlowState> build() async => _seed;

  @override
  void setRequestedStylist({
    required String? stylistId,
    required String? stylistName,
  }) {
    capturedStylistId = stylistId;
    capturedStylistName = stylistName;
    state = AsyncData(
      state.requireValue.copyWith(
        requestedStylistId: stylistId,
        requestedStylistName: stylistName,
        clearRequestedStylist: stylistId == null,
      ),
    );
  }

  @override
  void setSelectedSlot(DateTime slotStartAt, int durationMinutes) {
    capturedSlotStart = slotStartAt;
    capturedSlotDuration = durationMinutes;
    state = AsyncData(
      state.requireValue.copyWith(
        selectedSlotStartAt: slotStartAt,
        preferredDate: slotStartAt,
        preferredTimeWindow: '9:00 AM – 10:00 AM',
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widget builder helpers
// ──────────────────────────────────────────────────────────────────────────────

Widget _buildStylistSelectionApp({
  required TestBookingController controller,
  required FakeAvailabilityRepository repo,
  String? currentRoute,
}) {
  final router = GoRouter(
    initialLocation: currentRoute ?? '/customer/book/stylist',
    routes: [
      GoRoute(
        path: '/customer/book/stylist',
        builder: (_, __) => const StylistSelectionScreen(),
      ),
      GoRoute(
        path: '/customer/book/photos',
        builder: (_, __) => const Scaffold(body: Text('photos screen')),
      ),
      GoRoute(
        path: '/customer/book/time',
        builder: (_, __) => const Scaffold(body: Text('time screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      bookingFlowControllerProvider.overrideWith(() => controller),
      availabilityRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
    ),
  );
}

Widget _buildSlotsApp({
  required TestBookingController controller,
  required FakeAvailabilityRepository repo,
}) {
  final router = GoRouter(
    initialLocation: '/customer/book/time',
    routes: [
      GoRoute(
        path: '/customer/book/time',
        builder: (_, __) => const AvailableSlotsScreen(),
      ),
      GoRoute(
        path: '/customer/book/services',
        builder: (_, __) => const Scaffold(body: Text('services screen')),
      ),
      GoRoute(
        path: '/customer/book/details',
        builder: (_, __) => const Scaffold(body: Text('details screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      bookingFlowControllerProvider.overrideWith(() => controller),
      availabilityRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
    ),
  );
}

BookingFlowState _seedState({
  String? requestedStylistId,
  String? requestedStylistName,
}) {
  return BookingFlowState(
    householdId: 'household-1',
    householdName: 'The Tester Family',
    addresses: const [
      BookingAddressOption(
        id: 'address-1',
        marketId: 'market-1',
        territoryId: 'territory-1',
        label: 'Home',
        line1: '123 Main St',
        city: 'American Fork',
        state: 'UT',
        postalCode: '84003',
        serviceAreaStatus: 'serviceable',
      ),
    ],
    householdMembers: const [
      BookingHouseholdMemberOption(
        id: 'member-1',
        firstName: 'Sam',
        lastName: 'Tester',
        dateOfBirth: null,
        generalNotes: null,
        sensoryNotes: null,
        hairNotes: null,
      ),
    ],
    services: const [
      BookingServiceOption(
        id: 'service-1',
        name: 'Haircut',
        description: 'Precision cut.',
        durationMinutes: 60,
        basePriceCents: 9500,
        allowsMultipleParticipants: false,
      ),
    ],
    selectedAddressId: 'address-1',
    selectedMemberIds: {'member-1'},
    serviceItems: [
      BookingServiceItem(
        id: 'item-1',
        service: const BookingServiceOption(
          id: 'service-1',
          name: 'Bob / Lob Haircut',
          description: 'Precision cut.',
          durationMinutes: 60,
          basePriceCents: 9500,
          allowsMultipleParticipants: false,
        ),
      ),
    ],
    customerNotes: '',
    preferredDate: null,
    preferredTimeWindow: null,
    paymentStatus: 'not_started',
    acceptedPolicy: false,
    submittedAppointmentId: null,
    requestedStylistId: requestedStylistId,
    requestedStylistName: requestedStylistName,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Stylist Selection Screen tests
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  group('StylistSelectionScreen', () {
    testWidgets('shows subtitle and No preference button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository();

      await tester.pumpWidget(_buildStylistSelectionApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      // The subtitle is rendered inside the BookingStepScaffold (title is not
      // rendered as visible text — it's a scaffold parameter used elsewhere).
      expect(find.textContaining('optional'), findsOneWidget);
      // The primary button is always rendered regardless of scroll position
      // because we can find it via finder even if off-screen.
      expect(find.text('No preference, continue'), findsOneWidget);
    });

    testWidgets('shows empty state when no stylists returned', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository(stylists: []); // empty

      await tester.pumpWidget(_buildStylistSelectionApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No stylists available'), findsOneWidget);
    });

    testWidgets('lists stylists returned by repository', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const stylists = [
        BookableStylist(
          id: 'stylist-1',
          displayName: 'Alice Johnson',
          bio: 'Expert colorist.',
          specialties: ['Color', 'Balayage'],
        ),
        BookableStylist(
          id: 'stylist-2',
          displayName: 'Beth Kim',
          bio: null,
          specialties: [],
        ),
      ];

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository(stylists: stylists);

      await tester.pumpWidget(_buildStylistSelectionApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Beth Kim'), findsOneWidget);
    });

    testWidgets('tapping a stylist card calls setRequestedStylist and navigates',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const stylists = [
        BookableStylist(
          id: 'stylist-1',
          displayName: 'Alice Johnson',
          bio: null,
          specialties: ['Color'],
        ),
      ];

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository(stylists: stylists);

      await tester.pumpWidget(_buildStylistSelectionApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      // Scroll the stylist card into view before tapping (scaffold uses ListView)
      await tester.ensureVisible(find.text('Alice Johnson'));
      await tester.pump();
      await tester.tap(find.text('Alice Johnson'));
      await tester.pumpAndSettle();

      // Controller captured the selection
      expect(controller.capturedStylistId, 'stylist-1');
      expect(controller.capturedStylistName, 'Alice Johnson');

      // Navigated to time screen
      expect(find.text('time screen'), findsOneWidget);
    });

    testWidgets(
        '"No preference, continue" clears stylist and navigates to time',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Start with a previously selected stylist
      final controller = TestBookingController(_seedState(
        requestedStylistId: 'stylist-1',
        requestedStylistName: 'Alice Johnson',
      ));
      final repo = FakeAvailabilityRepository(stylists: const [
        BookableStylist(
          id: 'stylist-1',
          displayName: 'Alice Johnson',
          bio: null,
          specialties: [],
        ),
      ]);

      await tester.pumpWidget(_buildStylistSelectionApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      // The primary button is in the footer section — scroll it into view.
      await tester.ensureVisible(find.text('No preference, continue'));
      await tester.pump();
      await tester.tap(find.text('No preference, continue'));
      await tester.pumpAndSettle();

      expect(controller.capturedStylistId, isNull);
      expect(find.text('time screen'), findsOneWidget);
    });

    testWidgets('selected stylist shows checkmark', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const stylists = [
        BookableStylist(
          id: 'stylist-1',
          displayName: 'Alice Johnson',
          bio: null,
          specialties: [],
        ),
        BookableStylist(
          id: 'stylist-2',
          displayName: 'Beth Kim',
          bio: null,
          specialties: [],
        ),
      ];

      // Alice is already the requested stylist
      final controller = TestBookingController(_seedState(
        requestedStylistId: 'stylist-1',
        requestedStylistName: 'Alice Johnson',
      ));
      final repo = FakeAvailabilityRepository(stylists: stylists);

      await tester.pumpWidget(_buildStylistSelectionApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.check_circle_rounded),
        findsOneWidget,
      );
    });

    testWidgets('"Back" navigates to photos screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository();

      await tester.pumpWidget(_buildStylistSelectionApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      // Back button is in the footer — scroll it into view.
      await tester.ensureVisible(find.text('Back'));
      await tester.pump();
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('photos screen'), findsOneWidget);
    });
  });

  // ─── AvailableSlotsScreen ────────────────────────────────────────────────

  group('AvailableSlotsScreen', () {
    testWidgets('shows subtitle and date picker button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository(slots: []);

      await tester.pumpWidget(_buildSlotsApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      // The title parameter is not rendered as visible text in BookingStepScaffold.
      // Check the rendered subtitle and date picker UI instead.
      expect(find.textContaining('any stylist'), findsOneWidget);
      // Date picker button exists somewhere in the tree
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    });

    testWidgets('shows empty state when no slots available', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository(slots: []);

      await tester.pumpWidget(_buildSlotsApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No times available'), findsOneWidget);
    });

    testWidgets('shows available slots in the list', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final slotStart = DateTime(
          tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final slots = [
        AvailableTimeSlot(
          startAt: slotStart,
          endAt: slotEnd,
          stylistId: 'stylist-1',
          stylistName: 'Alice Johnson',
        ),
      ];

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository(slots: slots);

      await tester.pumpWidget(_buildSlotsApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      // Should show the time label "9:00 AM – 10:00 AM"
      expect(find.text('9:00 AM – 10:00 AM'), findsOneWidget);
    });

    testWidgets('shows stylist name when no preference set', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final slotStart = DateTime(
          tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final slots = [
        AvailableTimeSlot(
          startAt: slotStart,
          endAt: slotEnd,
          stylistId: 'stylist-1',
          stylistName: 'Alice Johnson',
        ),
      ];

      final controller = TestBookingController(_seedState()); // no preference
      final repo = FakeAvailabilityRepository(slots: slots);

      await tester.pumpWidget(_buildSlotsApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Alice Johnson'), findsOneWidget);
    });

    testWidgets('tapping a slot enables the confirm button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final slotStart = DateTime(
          tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final slots = [
        AvailableTimeSlot(
          startAt: slotStart,
          endAt: slotEnd,
          stylistId: 'stylist-1',
          stylistName: 'Alice Johnson',
        ),
      ];

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository(slots: slots);

      await tester.pumpWidget(_buildSlotsApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      // Before tapping, button label is "Select a time to continue"
      expect(find.text('Select a time to continue'), findsOneWidget);

      // Scroll slot into view before tapping
      await tester.ensureVisible(find.text('9:00 AM – 10:00 AM'));
      await tester.pump();
      await tester.tap(find.text('9:00 AM – 10:00 AM'));
      await tester.pumpAndSettle();

      // After tapping, label changes to "Confirm this time"
      expect(find.text('Confirm this time'), findsOneWidget);
    });

    testWidgets('confirming a slot calls setSelectedSlot and navigates',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final slotStart = DateTime(
          tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final slots = [
        AvailableTimeSlot(
          startAt: slotStart,
          endAt: slotEnd,
          stylistId: 'stylist-1',
          stylistName: 'Alice Johnson',
        ),
      ];

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository(slots: slots);

      await tester.pumpWidget(_buildSlotsApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      // Scroll slot into view and tap to select it
      await tester.ensureVisible(find.text('9:00 AM – 10:00 AM'));
      await tester.pump();
      await tester.tap(find.text('9:00 AM – 10:00 AM'));
      await tester.pumpAndSettle();

      // Scroll confirm button into view and tap it
      await tester.ensureVisible(find.text('Confirm this time'));
      await tester.pump();
      await tester.tap(find.text('Confirm this time'));
      await tester.pumpAndSettle();

      // Controller should have been called
      expect(controller.capturedSlotStart, slotStart);
      expect(controller.capturedSlotDuration, 60);

      // Should have navigated to details
      expect(find.text('details screen'), findsOneWidget);
    });

    testWidgets('"Back" navigates to services screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TestBookingController(_seedState());
      final repo = FakeAvailabilityRepository(slots: []);

      await tester.pumpWidget(_buildSlotsApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      // Back button is in the footer section — scroll it into view.
      await tester.ensureVisible(find.text('Back'));
      await tester.pump();
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('services screen'), findsOneWidget);
    });

    testWidgets('shows preferred stylist name in subtitle when set',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TestBookingController(_seedState(
        requestedStylistId: 'stylist-1',
        requestedStylistName: 'Alice Johnson',
      ));
      final repo = FakeAvailabilityRepository(slots: []);

      await tester.pumpWidget(_buildSlotsApp(
        controller: controller,
        repo: repo,
      ));
      await tester.pumpAndSettle();

      // The subtitle renders the stylist name when a preference is set
      expect(find.textContaining('Alice Johnson'), findsWidgets);
    });
  });
}
