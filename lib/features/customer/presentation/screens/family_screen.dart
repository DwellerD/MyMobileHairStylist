import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/profile_avatar_placeholder.dart';
import '../../data/customer_account_repository.dart';
import '../../domain/customer_account_summary.dart';
import '../providers/customer_account_providers.dart';

/// Customer household members and notes.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  void _showMemberSheet(BuildContext context, WidgetRef ref, String? householdId,
      CustomerHouseholdMemberSummary? member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberSheet(
        householdId: householdId,
        member: member,
        onSave: () => ref.invalidate(customerAccountSummaryProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(customerAccountSummaryProvider);

    return accountAsync.when(
      data: (account) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                _showMemberSheet(context, ref, account.primaryHouseholdId, null),
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppScreenHeader(
                title: 'Family',
                subtitle: account.primaryHouseholdName == null
                    ? 'Your household members will appear here after your first booking setup.'
                    : 'Manage notes and member context for ${account.primaryHouseholdName}.',
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.primaryHouseholdName ?? 'No household yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${account.householdCount} household${account.householdCount == 1 ? '' : 's'} · ${account.householdMemberCount} member${account.householdMemberCount == 1 ? '' : 's'} · ${account.addressCount} address${account.addressCount == 1 ? '' : 'es'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              const AppSectionHeader(
                title: 'Household members',
                subtitle: 'These profiles now come from your Supabase household records.',
              ),
              const SizedBox(height: AppSpacing.md),
              if (account.householdMembers.isEmpty)
                const EmptyState(
                  title: 'No household members yet',
                  description: 'Start a booking and add family members to build your reusable household list.',
                  icon: Icons.groups_outlined,
                )
              else
                ...account.householdMembers.map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _FamilyMemberTile(
                      member: member,
                      onTap: () => _showMemberSheet(
                          context, ref, account.primaryHouseholdId, member),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: EmptyState(
            title: 'Could not load your household',
            description: error.toString().replaceFirst('Exception: ', ''),
            icon: Icons.group_off_outlined,
            actionLabel: 'Retry',
            onActionPressed: () => ref.invalidate(customerAccountSummaryProvider),
          ),
        ),
      ),
    );
  }
}

class _FamilyMemberTile extends StatelessWidget {
  const _FamilyMemberTile({
    required this.member,
    required this.onTap,
  });

  final CustomerHouseholdMemberSummary member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        child: Row(
          children: [
            ProfileAvatarPlaceholder(name: member.name),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(member.relationshipLabel,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(member.detail, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit member bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _MemberSheet extends ConsumerStatefulWidget {
  const _MemberSheet({
    required this.householdId,
    required this.member,
    required this.onSave,
  });

  final String? householdId;
  final CustomerHouseholdMemberSummary? member;
  final VoidCallback onSave;

  @override
  ConsumerState<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends ConsumerState<_MemberSheet> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _generalNotesController = TextEditingController();
  final _sensoryNotesController = TextEditingController();
  final _hairNotesController = TextEditingController();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    if (m != null) {
      final parts = m.name.split(' ');
      _firstNameController.text = parts.first;
      if (parts.length > 1) {
        _lastNameController.text = parts.skip(1).join(' ');
      }
      // Pre-fill notes if available from detail
      if (m.detail.startsWith('Hair notes: ')) {
        _hairNotesController.text = m.detail.replaceFirst('Hair notes: ', '');
      } else if (m.detail.startsWith('Sensory notes: ')) {
        _sensoryNotesController.text = m.detail.replaceFirst('Sensory notes: ', '');
      } else if (m.detail.startsWith('General notes: ')) {
        _generalNotesController.text = m.detail.replaceFirst('General notes: ', '');
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _generalNotesController.dispose();
    _sensoryNotesController.dispose();
    _hairNotesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) return;
    setState(() => _isBusy = true);
    try {
      final repo = ref.read(customerAccountRepositoryProvider);
      if (widget.member != null) {
        await repo.updateHouseholdMember(
          memberId: widget.member!.id,
          firstName: firstName,
          lastName: _lastNameController.text.trim().isEmpty
              ? null
              : _lastNameController.text.trim(),
          generalNotes: _generalNotesController.text.trim().isEmpty
              ? null
              : _generalNotesController.text.trim(),
          sensoryNotes: _sensoryNotesController.text.trim().isEmpty
              ? null
              : _sensoryNotesController.text.trim(),
          hairNotes: _hairNotesController.text.trim().isEmpty
              ? null
              : _hairNotesController.text.trim(),
        );
      } else {
        final householdId = widget.householdId;
        if (householdId == null) return;
        await repo.createHouseholdMember(
          householdId: householdId,
          firstName: firstName,
          lastName: _lastNameController.text.trim().isEmpty
              ? null
              : _lastNameController.text.trim(),
          generalNotes: _generalNotesController.text.trim().isEmpty
              ? null
              : _generalNotesController.text.trim(),
          sensoryNotes: _sensoryNotesController.text.trim().isEmpty
              ? null
              : _sensoryNotesController.text.trim(),
          hairNotes: _hairNotesController.text.trim().isEmpty
              ? null
              : _hairNotesController.text.trim(),
        );
      }
      widget.onSave();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.member != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? 'Edit member' : 'Add member',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First name *'),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _generalNotesController,
            decoration: const InputDecoration(labelText: 'General notes'),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sensoryNotesController,
            decoration: const InputDecoration(labelText: 'Sensory notes'),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hairNotesController,
            decoration: const InputDecoration(labelText: 'Hair notes'),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isBusy ? null : _save,
              child: _isBusy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Save changes' : 'Add member'),
            ),
          ),
        ],
      ),
    );
  }
}