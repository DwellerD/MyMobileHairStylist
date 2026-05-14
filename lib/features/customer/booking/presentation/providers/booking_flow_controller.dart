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
    final selected = Set<String>.from(current.selectedServiceIds);
    if (!selected.add(serviceId)) {
      selected.remove(serviceId);
    }

    state = AsyncData(current.copyWith(selectedServiceIds: selected));
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

  void setPaymentStatus(String paymentStatus) {
    state = AsyncData(_requireState().copyWith(paymentStatus: paymentStatus));
  }

  void setPolicyAccepted(bool value) {
    state = AsyncData(_requireState().copyWith(acceptedPolicy: value));
  }

  void addPhotoDrafts(List<BookingPhotoDraft> newDrafts) {
    final current = _requireState();
    state = AsyncData(
      current.copyWith(
        photoDrafts: <BookingPhotoDraft>[
          ...current.photoDrafts,
          ...newDrafts,
        ],
      ),
    );
  }

  void removePhotoDraft(String fileName) {
    final current = _requireState();
    state = AsyncData(
      current.copyWith(
        photoDrafts: current.photoDrafts
            .where((draft) => draft.fileName != fileName)
            .toList(growable: false),
      ),
    );
  }

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
        selectedServiceIds: <String>{},
        customerNotes: '',
        photoDrafts: const <BookingPhotoDraft>[],
        clearPreferredDate: true,
        clearPreferredTimeWindow: true,
        paymentStatus: 'not_started',
        acceptedPolicy: false,
        clearSubmittedAppointmentId: true,
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