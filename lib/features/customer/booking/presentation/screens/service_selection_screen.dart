import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/booking_service_catalog.dart';
import '../../domain/booking_flow_state.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

// Matches the booking-flow primary defined in booking_step_scaffold.dart
const Color _kPrimary    = Color(0xFF8B3838);
const Color _kTextDark   = Color(0xFF1A1212);
const Color _kTextMid    = Color(0xFF6B6260);
const Color _kHeroBg     = Color(0xFFF5EDE4);
const Color _kPlaceImg   = Color(0xFFE0D8D0);
const Color _kDivider    = Color(0xFFF0EAE4);

// ─────────────────────────────────────────────────────────────────────────────
class ServiceSelectionScreen extends ConsumerStatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  ConsumerState<ServiceSelectionScreen> createState() =>
      _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState
    extends ConsumerState<ServiceSelectionScreen> {
  BookingServiceCategory _selectedCategory = BookingServiceCategory.women;

  void _openServiceModal(
      BuildContext context, BookingFlowState bookingState, BookingServiceOption service) {
    final existingItems = bookingState.serviceItems
        .where((i) => i.service.id == service.id)
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ServiceModal(
        service: service,
        existingItems: existingItems,
        householdMembers: bookingState.householdMembers,
        onAdd: (String? memberId, String notes) {
          ref
              .read(bookingFlowControllerProvider.notifier)
              .addServiceItem(service: service, assignedMemberId: memberId, notes: notes);
        },
        onRemove: (String itemId) {
          ref
              .read(bookingFlowControllerProvider.notifier)
              .removeServiceItem(itemId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Build per-category lists preserving catalog sort order
    final servicesByCategory =
        <BookingServiceCategory, List<BookingServiceOption>>{
      for (final cat in BookingServiceCategory.values)
        cat: bookingState.services
            .where((s) => _categorizeService(s) == cat)
            .toList(growable: false)
          ..sort(_compareServicesWithinCategory),
    };

    final activeServices = servicesByCategory[_selectedCategory] ?? const [];
    final hasSelection = bookingState.serviceItems.isNotEmpty;

    return BookingStepScaffold(
      displayStep: 2,
      stepNumber: 2,
      totalSteps: 5,
      title: 'Choose your services',
      subtitle: 'Tap a service to add it. You can add multiple services.',
      heroWidget: Image.asset(
        'assets/images/topservicesbanner.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
      ),
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading,
      secondaryLabel: 'Back',
      onSecondaryPressed: () => context.go('/customer/book'),
      primaryLabel: 'CONTINUE',
      onPrimaryPressed:
          hasSelection ? () => context.go('/customer/book/time') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category filter pills ──────────────────────────────────────
          _CategoryPillsBar(
            selectedCategory: _selectedCategory,
            onCategoryTap: (cat) => setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 20),

          // ── Service list ───────────────────────────────────────────────
          if (bookingState.services.isEmpty)
            const _EmptyCatalog()
          else if (activeServices.isEmpty)
            _EmptyCategory(category: _selectedCategory)
          else
            Column(
              children: [
                for (int i = 0; i < activeServices.length; i++)
                  _ServiceTile(
                    service: activeServices[i],
                    addedCount: bookingState.serviceItems
                        .where((item) => item.service.id == activeServices[i].id)
                        .length,
                    showDivider: i < activeServices.length - 1,
                    onTap: () => _openServiceModal(
                        context, bookingState, activeServices[i]),
                  ),
              ],
            ),

          const SizedBox(height: 28),

          // ── Selected summary (if any) ──────────────────────────────────
          if (hasSelection)
            _ServiceItemsSummary(
              serviceItems: bookingState.serviceItems,
              memberNames: {
                for (final m in bookingState.householdMembers)
                  m.id: m.displayName,
              },
              onRemove: (itemId) => ref
                  .read(bookingFlowControllerProvider.notifier)
                  .removeServiceItem(itemId),
            ),

          const SizedBox(height: 20),

          // ── Support section ────────────────────────────────────────────
          const _SupportSection(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service add/edit modal
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceModal extends StatefulWidget {
  const _ServiceModal({
    required this.service,
    required this.existingItems,
    required this.householdMembers,
    required this.onAdd,
    required this.onRemove,
  });

  final BookingServiceOption service;
  final List<BookingServiceItem> existingItems;
  final List<BookingHouseholdMemberOption> householdMembers;
  final void Function(String? memberId, String notes) onAdd;
  final void Function(String itemId) onRemove;

  @override
  State<_ServiceModal> createState() => _ServiceModalState();
}

class _ServiceModalState extends State<_ServiceModal> {
  String? _selectedMemberId;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Add ${widget.service.name}',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.service.durationMinutes} min  ·  Starting at ${widget.service.priceLabel}',
            style: GoogleFonts.manrope(fontSize: 13, color: _kTextMid),
          ),
          const SizedBox(height: 20),

          // For whom?
          if (widget.householdMembers.isNotEmpty) ...[
            Text(
              'For whom?',
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kTextDark),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.householdMembers.map((m) {
                final selected = _selectedMemberId == m.id;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedMemberId = selected ? null : m.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? _kPrimary : const Color(0xFFD0C8C0),
                      ),
                    ),
                    child: Text(
                      m.displayName,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : _kTextDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Notes
          Text(
            'Notes (optional)',
            style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kTextDark),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Length preferences, allergies, inspiration photos…',
              hintStyle: GoogleFonts.manrope(fontSize: 13, color: _kTextMid),
              filled: true,
              fillColor: _kHeroBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            style: GoogleFonts.manrope(fontSize: 13, color: _kTextDark),
          ),
          const SizedBox(height: 20),

          // Existing items with remove
          if (widget.existingItems.isNotEmpty) ...[
            Text(
              'Already added',
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kTextDark),
            ),
            const SizedBox(height: 8),
            ...widget.existingItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: _kPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.notes.isEmpty
                              ? widget.service.name
                              : '${widget.service.name} — ${item.notes}',
                          style: GoogleFonts.manrope(
                              fontSize: 12, color: _kTextMid),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.onRemove(item.id);
                          Navigator.of(context).pop();
                        },
                        child: const Icon(Icons.close,
                            size: 18, color: _kTextMid),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onAdd(_selectedMemberId, _notesController.text.trim());
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Add service',
                      style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category pills
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryPillsBar extends StatelessWidget {
  const _CategoryPillsBar({
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final BookingServiceCategory selectedCategory;
  final ValueChanged<BookingServiceCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final cat in BookingServiceCategory.values) ...[
            _CategoryPill(
              icon: _categoryIcon(cat),
              label: _displayLabel(cat),
              isSelected: selectedCategory == cat,
              onTap: () => onCategoryTap(cat),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? _kPrimary : const Color(0xFFD0C8C0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF8B8178)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : _kTextDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service tile
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.addedCount,
    required this.onTap,
    this.showDivider = true,
  });

  final BookingServiceOption service;
  final int addedCount;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Image placeholder ──────────────────────────────────
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: addedCount > 0
                        ? const Color(0xFFEDD8D8)
                        : _kPlaceImg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: addedCount > 0
                      ? Center(
                          child: addedCount == 1
                              ? const Icon(Icons.check,
                                  color: _kPrimary, size: 26)
                              : Text(
                                  '×$addedCount',
                                  style: GoogleFonts.manrope(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _kPrimary),
                                ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // ── Text ───────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kTextDark,
                        ),
                      ),
                      if ((service.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          service.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: _kTextMid,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${service.durationMinutes} min',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                              width: 1,
                              height: 11,
                              color: const Color(0xFFD8CFC8)),
                          const SizedBox(width: 6),
                          Text(
                            'Starting at ${service.priceLabel}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Trailing icon ──────────────────────────────────────
                const SizedBox(width: 8),
                Icon(
                  addedCount > 0
                      ? Icons.check_circle
                      : Icons.chevron_right,
                  size: 22,
                  color: addedCount > 0
                      ? _kPrimary
                      : const Color(0xFFB8B0A8),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(height: 1, color: _kDivider),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected service items summary
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceItemsSummary extends StatelessWidget {
  const _ServiceItemsSummary({
    required this.serviceItems,
    required this.memberNames,
    required this.onRemove,
  });

  final List<BookingServiceItem> serviceItems;
  final Map<String, String> memberNames;
  final void Function(String itemId) onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEED8D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected services',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...serviceItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: _kPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [
                        '${item.service.name}  ·  ${item.service.durationMinutes} min  ·  ${item.service.priceLabel}',
                        if (item.assignedMemberId != null)
                          'For: ${memberNames[item.assignedMemberId] ?? 'Unknown'}',
                        if (item.notes.isNotEmpty) item.notes,
                      ].join('\n'),
                      style: GoogleFonts.manrope(fontSize: 12, color: _kTextMid),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onRemove(item.id),
                    child: const Icon(Icons.close, size: 18, color: _kTextMid),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Support / help section
// ─────────────────────────────────────────────────────────────────────────────
class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kHeroBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2D8D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border:
                  Border.all(color: const Color(0xFFD8D0C8)),
            ),
            child: const Icon(Icons.chat_bubble_outline,
                size: 18, color: _kTextMid),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not sure what to book?',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Message us and we'll help you choose the perfect service.",
                  style: GoogleFonts.manrope(
                      fontSize: 12, color: _kTextMid, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Select a service or continue to notes if you want to describe what you need.',
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(0, 36),
              textStyle: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            child: const Text('MESSAGE US',
                style: TextStyle(color: _kPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty states
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.content_cut_outlined,
              size: 40, color: Color(0xFFD0C8C0)),
          const SizedBox(height: 12),
          Text(
            'No services published yet',
            style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kTextMid),
          ),
          const SizedBox(height: 4),
          Text(
            'Run the seed migration or add services in Supabase.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 13, color: _kTextMid),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.category});

  final BookingServiceCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'No ${_displayLabel(category).toLowerCase()} services are currently available.',
        style: GoogleFonts.manrope(fontSize: 13, color: _kTextMid),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category helpers
// ─────────────────────────────────────────────────────────────────────────────
String _displayLabel(BookingServiceCategory cat) {
  switch (cat) {
    case BookingServiceCategory.women:
      return 'Haircut & Styling';
    case BookingServiceCategory.hairColor:
      return 'Hair Color';
    case BookingServiceCategory.men:
      return 'Men';
    case BookingServiceCategory.kids:
      return 'Kids';
    case BookingServiceCategory.addOns:
      return 'Add-Ons';
    case BookingServiceCategory.specialEventWedding:
      return 'Special Event / Wedding';
  }
}

IconData _categoryIcon(BookingServiceCategory cat) {
  switch (cat) {
    case BookingServiceCategory.women:
      return Icons.content_cut;
    case BookingServiceCategory.hairColor:
      return Icons.color_lens_outlined;
    case BookingServiceCategory.men:
      return Icons.face_outlined;
    case BookingServiceCategory.kids:
      return Icons.child_care_outlined;
    case BookingServiceCategory.addOns:
      return Icons.add_circle_outline;
    case BookingServiceCategory.specialEventWedding:
      return Icons.local_florist_outlined;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service categorization logic (preserved from original)
// ─────────────────────────────────────────────────────────────────────────────
BookingServiceCategory _categorizeService(BookingServiceOption service) {
  final name = service.name.toLowerCase();
  final exactCategory = bookingServiceCategoryByName[name];
  if (exactCategory != null) return exactCategory;

  if (name.contains('highlight') ||
      name.contains('balayage') ||
      name.contains('root retouch') ||
      name.contains('all over color') ||
      name.contains('color correction')) {
    return BookingServiceCategory.hairColor;
  }
  if (name.contains('bridal') ||
      name.contains('wedding') ||
      name.contains('bridesmaid') ||
      name.contains('flower girl') ||
      name.contains('updo') ||
      name.contains('hollywood waves') ||
      name.contains('event hair')) {
    return BookingServiceCategory.specialEventWedding;
  }
  if (name.contains('kid') ||
      name.contains('child') ||
      name.contains('youth')) {
    return BookingServiceCategory.kids;
  }
  if (name.contains('men') ||
      name.contains('beard') ||
      name.contains('fade') ||
      name.contains('taper') ||
      name.contains('undercut')) {
    return BookingServiceCategory.men;
  }
  if (name.contains('toner') ||
      name.contains('gloss') ||
      name.contains('conditioning') ||
      name.contains('massage') ||
      name.contains('hot tool') ||
      name.contains('tinsel') ||
      name.contains('extension blend') ||
      name.contains('extra styling') ||
      name.contains('treatment')) {
    return BookingServiceCategory.addOns;
  }
  return BookingServiceCategory.women;
}

int _compareServicesWithinCategory(
  BookingServiceOption left,
  BookingServiceOption right,
) {
  final category = _categorizeService(left);
  final order = bookingServiceNamesByCategory[category] ?? const <String>[];
  final leftIndex = order.indexOf(left.name);
  final rightIndex = order.indexOf(right.name);

  if (leftIndex != -1 && rightIndex != -1) return leftIndex.compareTo(rightIndex);
  if (leftIndex != -1) return -1;
  if (rightIndex != -1) return 1;
  return left.name.compareTo(right.name);
}
