import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/domain/app_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_flow_state.dart';

/// Stateful booking controller shared by every customer booking step.
final bookingFlowControllerProvider = AutoDisposeAsyncNotifierProvider<
    BookingFlowController, BookingFlowState>(BookingFlowController.new);

class BookingFlowController extends AutoDisposeAsyncNotifier<BookingFlowState> {
  BookingRepository get _repository => ref.read(bookingRepositoryProvider);

  @override
  Future<BookingFlowState> build() async {
    final appUser = await _requireAppUser();
    return _repository.loadInitialState(appUser: appUser);
  }

  void selectAddress(String addressId) {
    state = AsyncData(_requireState().copyWith(selectedAddressId: addressId));
  }

  void toggleMember(String memberId) {
    final current = _requireState();
    final selected = Set<String>.from(current.selectedMemberIds);
    if (!selected.add(memberId)) {
      selected.remove(memberId);
    }

    state = AsyncData(current.copyWith(selectedMemberIds: selected));
  }

  void toggleService(String serviceId) {
    final current = _requireState();
    final existingIndex =
        current.serviceItems.indexWhere((item) => item.service.id == serviceId);
    if (existingIndex >= 0) {
      final updated = List<BookingServiceItem>.from(current.serviceItems)
        ..removeAt(existingIndex);
      state = AsyncData(current.copyWith(serviceItems: updated));
    } else {
      final service =
          current.services.firstWhere((s) => s.id == serviceId);
      final autoMemberId = current.selectedMemberIds.length == 1
          ? current.selectedMemberIds.first
          : null;
      final newItem = BookingServiceItem(
        id: '${serviceId}_${DateTime.now().microsecondsSinceEpoch}',
        service: service,
        assignedMemberId: autoMemberId,
      );
      state = AsyncData(
        current.copyWith(
          serviceItems: [...current.serviceItems, newItem],
        ),
      );
    }
  }

  /// Add a service item with optional member assignment, notes, and photos.
  void addServiceItem({
    required BookingServiceOption service,
    String? assignedMemberId,
    String notes = '',
    List<BookingPhotoDraft> photos = const [],
  }) {
    final current = _requireState();
    final newItem = BookingServiceItem(
      id: '${service.id}_${DateTime.now().microsecondsSinceEpoch}',
      service: service,
      assignedMemberId: assignedMemberId,
      notes: notes,
      photos: photos,
    );
    state = AsyncData(
      current.copyWith(serviceItems: [...current.serviceItems, newItem]),
    );
  }

  /// Remove a service item by its [itemId].
  void removeServiceItem(String itemId) {
    final current = _requireState();
    state = AsyncData(
      current.copyWith(
        serviceItems: current.serviceItems
            .where((item) => item.id != itemId)
            .toList(growable: false),
      ),
    );
  }

  /// Update an existing service item's member assignment, notes, or photos.
  void updateServiceItem(
    String itemId, {
    String? assignedMemberId,
    bool clearAssignedMember = false,
    String? notes,
    List<BookingPhotoDraft>? photos,
  }) {
    final current = _requireState();
    final updated = current.serviceItems.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(
        assignedMemberId: assignedMemberId,
        clearAssignedMember: clearAssignedMember,
        notes: notes,
        photos: photos,
      );
    }).toList(growable: false);
    state = AsyncData(current.copyWith(serviceItems: updated));
  }

  /// Set the customer's contact phone number.
  void setPhone(String phone) {
    state = AsyncData(
      _requireState().copyWith(customerPhone: phone.trim()),
    );
  }

  void setNotes(String notes) {
    state = AsyncData(_requireState().copyWith(customerNotes: notes.trim()));
  }

  void setPreferredDate(DateTime date) {
    state = AsyncData(_requireState().copyWith(preferredDate: date));
  }

  void setPreferredTimeWindow(String windowKey) {
    state = AsyncData(
      _requireState().copyWith(preferredTimeWindow: windowKey),
    );
  }

  /// Set a specific stylist the customer wants to book with.
  /// Pass null for both arguments to clear the preference (no preference).
  void setRequestedStylist({required String? stylistId, required String? stylistName}) {
    final current = _requireState();
    if (stylistId == null) {
      state = AsyncData(current.copyWith(clearRequestedStylist: true, clearSelectedSlot: true));
    } else {
      state = AsyncData(
        current.copyWith(
          requestedStylistId: stylistId,
          requestedStylistName: stylistName,
          clearSelectedSlot: true,
        ),
      );
    }
  }

  /// Set the specific time slot the customer chose in the slot picker.
  ///
  /// Also synchronises [BookingFlowState.preferredDate] and
  /// [BookingFlowState.preferredTimeWindow] so the review screen and database
  /// row continue to work without changes.
  void setSelectedSlot(DateTime slotStartAt, int durationMinutes) {
    final slotEndAt = slotStartAt.add(Duration(minutes: durationMinutes));
    final timeLabel =
        '${_formatSlotTime(slotStartAt)} – ${_formatSlotTime(slotEndAt)}';

    state = AsyncData(
      _requireState().copyWith(
        selectedSlotStartAt: slotStartAt,
        preferredDate: slotStartAt,
        preferredTimeWindow: timeLabel,
      ),
    );
  }

  void setPaymentStatus(String paymentStatus) {
    state = AsyncData(_requireState().copyWith(paymentStatus: paymentStatus));
  }

  void setPolicyAccepted(bool value) {
    state = AsyncData(_requireState().copyWith(acceptedPolicy: value));
  }

  /// Photos are now stored per service item. These methods are kept for
  /// backward compatibility with legacy screens but have no effect.
  void addPhotoDrafts(List<BookingPhotoDraft> newDrafts) {}
  void removePhotoDraft(String fileName) {}

  Future<void> createAddress({
    required String label,
    required String line1,
    required String city,
    required String stateCode,
    required String postalCode,
  }) async {
    final previous = _requireState();
    state = const AsyncLoading<BookingFlowState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final appUser = await _requireAppUser();
      final newAddress = await _repository.createAddress(
        appUser: appUser,
        householdId: previous.householdId,
        label: label,
        line1: line1,
        city: city,
        state: stateCode,
        postalCode: postalCode,
      );

      return previous.copyWith(
        addresses: <BookingAddressOption>[...previous.addresses, newAddress],
        selectedAddressId: newAddress.id,
      );
    });
  }

  Future<void> createHouseholdMember({
    required String firstName,
    required String? lastName,
    required DateTime? dateOfBirth,
    required String? generalNotes,
    required String? sensoryNotes,
    required String? hairNotes,
  }) async {
    final previous = _requireState();
    state = const AsyncLoading<BookingFlowState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final member = await _repository.createHouseholdMember(
        householdId: previous.householdId,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        generalNotes: generalNotes,
        sensoryNotes: sensoryNotes,
        hairNotes: hairNotes,
      );

      return previous.copyWith(
        householdMembers: <BookingHouseholdMemberOption>[
          ...previous.householdMembers,
          member,
        ],
        selectedMemberIds: <String>{...previous.selectedMemberIds, member.id},
      );
    });
  }

  Future<void> submitBookingRequest() async {
    final previous = _requireState();
    if (!previous.acceptedPolicy) {
      throw Exception('Accept the in-home and cancellation policy before submitting.');
    }

    state = const AsyncLoading<BookingFlowState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final appUser = await _requireAppUser();
      final appointmentId = await _repository.submitBookingRequest(
        appUser: appUser,
        bookingState: previous,
      );

      return previous.copyWith(submittedAppointmentId: appointmentId);
    });
  }

  Future<void> resetFlow() async {
    final current = _requireState();
    state = AsyncData(
      current.copyWith(
        selectedMemberIds: <String>{},
        serviceItems: const <BookingServiceItem>[],
        customerNotes: '',
        clearCustomerPhone: true,
        clearPreferredDate: true,
        clearPreferredTimeWindow: true,
        paymentStatus: 'not_started',
        acceptedPolicy: false,
        clearSubmittedAppointmentId: true,
        clearRequestedStylist: true,
        clearSelectedSlot: true,
      ),
    );
  }

  Future<void> retryLoad() async {
    ref.invalidateSelf();
    await future;
  }

  BookingFlowState _requireState() {
    final current = state.valueOrNull;
    if (current == null) {
      throw Exception('Booking details are still loading.');
    }

    return current;
  }

  Future<AppUser> _requireAppUser() async {
    final appUser = await ref.read(currentAppUserProvider.future);
    if (appUser == null) {
      throw Exception('Please sign in again to continue your booking request.');
    }

    return appUser;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

String _formatSlotTime(DateTime dt) {
  final hour =
      dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
  final minute = dt.minute.toString().padLeft(2, '0');
  final suffix = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}