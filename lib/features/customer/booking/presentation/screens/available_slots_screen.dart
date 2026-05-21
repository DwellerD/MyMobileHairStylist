import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../data/availability_repository.dart';
import '../../domain/availability_slot.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// Step 7 of 9 — date-picker + real availability-based slot list.
///
/// The customer picks a date from the next 60 days, the screen loads all open
/// slots across bookable stylists (or just the requested stylist) and presents
/// them grouped by time of day. Tapping a slot saves it to state and advances
/// to the payment step.
class AvailableSlotsScreen extends ConsumerStatefulWidget {
  const AvailableSlotsScreen({super.key});

  @override
  ConsumerState<AvailableSlotsScreen> createState() =>
      _AvailableSlotsScreenState();
}

class _AvailableSlotsScreenState extends ConsumerState<AvailableSlotsScreen> {
  late DateTime _selectedDate;
  AvailableTimeSlot? _pendingSlot;

  @override
  void initState() {
    super.initState();
    // Default to tomorrow — today is excluded because there's rarely enough
    // notice for a same-day booking in the MVP flow.
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day + 1);
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);

    return bookingAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Something went wrong: $e')),
      ),
      data: (bookingState) {
        final marketId = bookingState.marketId;
        if (marketId == null) {
          return const Scaffold(
            body: Center(child: Text('Unable to determine market.')),
          );
        }

        final query = _SlotsQuery(
          date: _selectedDate,
          durationMinutes: bookingState.estimatedDurationMinutes,
          marketId: marketId,
          requestedStylistId: bookingState.requestedStylistId,
        );

        final slotsAsync = ref.watch(_availableSlotsProvider(query));

        return BookingStepScaffold(
          displayStep: 3,
          stepNumber: 3,
          totalSteps: 5,
          title: 'Choose your appointment time',
          subtitle: bookingState.requestedStylistId != null
              ? 'Showing availability for ${bookingState.requestedStylistName ?? 'your preferred stylist'}.'
              : 'Showing available times for any stylist in your area.',
          primaryLabel: _pendingSlot != null ? 'Confirm this time' : 'Select a time to continue',
          onPrimaryPressed: _pendingSlot != null
              ? () {
                  final slot = _pendingSlot!;
                  ref
                      .read(bookingFlowControllerProvider.notifier)
                      .setSelectedSlot(
                        slot.startAt,
                        slot.durationMinutes,
                      );
                  context.go('/customer/book/details');
                }
              : null,
          secondaryLabel: 'Back',
          onSecondaryPressed: () => context.go('/customer/book/services'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DatePickerRow(
                selectedDate: _selectedDate,
                onDateChanged: (d) {
                  setState(() {
                    _selectedDate = d;
                    _pendingSlot = null;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              slotsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                  title: 'Could not load availability',
                  description: e.toString(),
                  icon: Icons.warning_amber_rounded,
                ),
                data: (slots) {
                  if (slots.isEmpty) {
                    return EmptyState(
                      title: 'No times available',
                      description:
                          'No available times on ${_selectedDate.month}/${_selectedDate.day}. '
                          'Try a different date.',
                      icon: Icons.calendar_today_outlined,
                    );
                  }

                  return _SlotList(
                    slots: slots.cast<AvailableTimeSlot>(),
                    selectedSlot: _pendingSlot,
                    onSlotTap: (slot) {
                      setState(() => _pendingSlot = slot);
                    },
                    showStylistName:
                        bookingState.requestedStylistId == null,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Date picker row ─────────────────────────────────────────────────────────

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day + 1);
    final lastDate = firstDate.add(const Duration(days: 59));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                '${_monthName(selectedDate.month)} ${selectedDate.day}, '
                '${selectedDate.year}',
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (picked != null) {
                  onDateChanged(picked);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }
}

// ─── Slot list ───────────────────────────────────────────────────────────────

class _SlotList extends StatelessWidget {
  const _SlotList({
    required this.slots,
    required this.selectedSlot,
    required this.onSlotTap,
    required this.showStylistName,
  });

  final List<AvailableTimeSlot> slots;
  final AvailableTimeSlot? selectedSlot;
  final ValueChanged<AvailableTimeSlot> onSlotTap;
  final bool showStylistName;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selectedSlot?.startAt == slot.startAt &&
            selectedSlot?.stylistId == slot.stylistId;

        return AppCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSlotTap(slot),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.timeLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : null,
                              ),
                        ),
                        if (showStylistName) ...[
                          const SizedBox(height: 2),
                          Text(
                            'with ${slot.stylistName}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 22,
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Scoped providers ────────────────────────────────────────────────────────

class _SlotsQuery {
  const _SlotsQuery({
    required this.date,
    required this.durationMinutes,
    required this.marketId,
    this.requestedStylistId,
  });

  final DateTime date;
  final int durationMinutes;
  final String marketId;
  final String? requestedStylistId;

  @override
  bool operator ==(Object other) =>
      other is _SlotsQuery &&
      other.date == date &&
      other.durationMinutes == durationMinutes &&
      other.marketId == marketId &&
      other.requestedStylistId == requestedStylistId;

  @override
  int get hashCode => Object.hash(date, durationMinutes, marketId, requestedStylistId);
}

final _availableSlotsProvider = FutureProvider.autoDispose
    .family<List<AvailableTimeSlot>, _SlotsQuery>((ref, query) async {
  return ref.watch(availabilityRepositoryProvider).getAvailableSlots(
        date: query.date,
        durationMinutes: query.durationMinutes,
        marketId: query.marketId,
        requestedStylistId: query.requestedStylistId,
      );
});
