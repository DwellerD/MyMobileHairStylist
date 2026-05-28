import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/availability_models.dart';
import '../providers/stylist_availability_providers.dart';

/// Lets stylists view and manage their availability blocks for a given week.
///
/// Route: /stylist/availability
class StylistAvailabilityScreen extends ConsumerStatefulWidget {
  const StylistAvailabilityScreen({super.key});

  @override
  ConsumerState<StylistAvailabilityScreen> createState() =>
      _StylistAvailabilityScreenState();
}

class _StylistAvailabilityScreenState
    extends ConsumerState<StylistAvailabilityScreen> {
  // Monday of the currently-displayed week.
  late DateTime _weekOf;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekOf = now.subtract(Duration(days: (now.weekday - 1) % 7));
    _weekOf = DateTime(_weekOf.year, _weekOf.month, _weekOf.day);
  }

  @override
  Widget build(BuildContext context) {
    final blocksAsync = ref.watch(stylistAvailabilityBlocksProvider(_weekOf));
    final controller =
        ref.watch(stylistAvailabilityControllerProvider.notifier);
    final mutationState =
        ref.watch(stylistAvailabilityControllerProvider);
    final mutationError =
      mutationState is AsyncError<void>
        ? mutationState.error
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppScreenHeader(
              title: 'My Availability',
              subtitle: 'Add or remove availability blocks for your schedule.',
            ),
            _WeekNavigator(
              weekOf: _weekOf,
              onPrevious: () => setState(() {
                _weekOf = _weekOf.subtract(const Duration(days: 7));
              }),
              onNext: () => setState(() {
                _weekOf = _weekOf.add(const Duration(days: 7));
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (mutationError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Error: $mutationError',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            Expanded(
              child: blocksAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                  title: 'Could not load availability',
                  description: e.toString(),
                  icon: Icons.warning_amber_rounded,
                ),
                data: (blocks) {
                  final availabilityBlocks = blocks
                      .where((block) => block.isAvailable)
                      .toList(growable: false);

                  if (availabilityBlocks.isEmpty) {
                    return const EmptyState(
                      title: 'No blocks this week',
                      description:
                          'No availability blocks this week. Tap + to add your first block.',
                      icon: Icons.calendar_today_outlined,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: availabilityBlocks.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final block = availabilityBlocks[index];
                      return _AvailabilityBlockCard(
                        block: block,
                        onEdit: () => _showBlockSheet(context, controller,
                            existing: block),
                        onDelete: () async {
                          final confirm =
                              await _confirmDelete(context);
                          if (confirm == true) {
                            await controller.deleteBlock(
                              blockId: block.id,
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBlockSheet(context, controller),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add availability'),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove block?'),
        content: const Text(
          'This availability block will be deleted. Existing confirmed appointments are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showBlockSheet(
    BuildContext context,
    StylistAvailabilityController controller, {
    AvailabilityBlock? existing,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BlockFormSheet(
        existing: existing,
        defaultDate: _weekOf,
        controller: controller,
      ),
    );
  }
}

// ─── Week navigator ──────────────────────────────────────────────────────────

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.weekOf,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime weekOf;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final end = weekOf.add(const Duration(days: 6));
    final label =
        '${_fmt(weekOf)} – ${_fmt(end)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrevious,
            color: AppColors.primary,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month]} ${d.day}';
  }
}

// ─── Block card ──────────────────────────────────────────────────────────────

class _AvailabilityBlockCard extends StatelessWidget {
  const _AvailabilityBlockCard({
    required this.block,
    required this.onEdit,
    required this.onDelete,
  });

  final AvailabilityBlock block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isAvailable = block.isAvailable;
    final color = isAvailable
        ? AppColors.success
        : block.isAppointmentHold
            ? AppColors.info
            : AppColors.warning;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.typeLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${block.dateLabel}  •  ${block.timeRangeLabel}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  if (block.notes != null && block.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      block.notes!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Appointment holds cannot be edited here — only cancelling the
            // appointment itself removes the hold.
            if (!block.isAppointmentHold) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                color: AppColors.primary,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: onDelete,
                color: AppColors.danger,
                tooltip: 'Remove',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Add/edit block bottom sheet ─────────────────────────────────────────────

class _BlockFormSheet extends ConsumerStatefulWidget {
  const _BlockFormSheet({
    required this.controller,
    this.existing,
    required this.defaultDate,
  });

  final StylistAvailabilityController controller;
  final AvailabilityBlock? existing;
  final DateTime defaultDate;

  @override
  ConsumerState<_BlockFormSheet> createState() => _BlockFormSheetState();
}

class _BlockFormSheetState extends ConsumerState<_BlockFormSheet> {
  late DateTime _startAt;
  late DateTime _endAt;
  final TextEditingController _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _startAt = existing.startAt;
      _endAt = existing.endAt;
      _notesController.text = existing.notes ?? '';
    } else {
      final d = widget.defaultDate;
      _startAt = DateTime(d.year, d.month, d.day, 9, 0);
      _endAt = DateTime(d.year, d.month, d.day, 17, 0);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null
                ? 'Add availability'
                : 'Edit availability',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),

          // Start
          Text('Starts at', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          _DateTimeTile(
            dateTime: _startAt,
            onTap: () => _pickDateTime(
              initial: _startAt,
              onPicked: (dt) => setState(() {
                _startAt = dt;
                if (!_endAt.isAfter(_startAt)) {
                  _endAt = _startAt.add(const Duration(hours: 1));
                }
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // End
          Text('Ends at', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          _DateTimeTile(
            dateTime: _endAt,
            onTap: () => _pickDateTime(
              initial: _endAt,
              onPicked: (dt) => setState(() => _endAt = dt),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime({
    required DateTime initial,
    required void Function(DateTime) onPicked,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    onPicked(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _save() async {
    if (!_endAt.isAfter(_startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final notes = _notesController.text.trim();
      if (widget.existing != null) {
        await widget.controller.updateBlock(
          blockId: widget.existing!.id,
          blockType: 'available',
          startAt: _startAt,
          endAt: _endAt,
          notes: notes.isEmpty ? null : notes,
        );
      } else {
        await widget.controller.createBlock(
          blockType: 'available',
          startAt: _startAt,
          endAt: _endAt,
          notes: notes.isEmpty ? null : notes,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.dateTime, required this.onTap});

  final DateTime dateTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    final label =
        '${months[dateTime.month]} ${dateTime.day}, ${dateTime.year}  $hour:$minute $suffix';

    return OutlinedButton.icon(
      icon: const Icon(Icons.access_time_rounded, size: 18),
      label: Text(label),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}
