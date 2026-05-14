import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/admin_models.dart';
import '../providers/admin_providers.dart';

/// Admin service catalog management screen.
class AdminServicesScreen extends ConsumerWidget {
  const AdminServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(adminServiceCatalogProvider);
    final actionState = ref.watch(adminActionControllerProvider);

    return catalogAsync.when(
      data: (catalog) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Services',
              subtitle: 'Service catalog controls are mobile-usable now and should eventually expand into a broader desktop pricing workspace.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            FilledButton.icon(
              onPressed: actionState.isLoading || catalog.isEmpty
                  ? null
                  : () => _showServiceDialog(context, ref, categories: catalog),
              icon: const Icon(Icons.add),
              label: const Text('Create service'),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (catalog.isEmpty)
              EmptyState(
                title: 'No service categories found',
                description: 'Run the service seed migration or create categories before adding services.',
                icon: Icons.design_services_outlined,
                actionLabel: 'Refresh',
                onActionPressed: () => ref.invalidate(adminServiceCatalogProvider),
              )
            else
              ...catalog.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name, style: Theme.of(context).textTheme.titleLarge),
                        if (category.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(category.description!),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        if (category.services.isEmpty)
                          const Text('No services in this category yet.')
                        else
                          ...category.services.map(
                            (service) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service.name, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(service.description ?? 'No description'),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text('${service.durationMinutes} min · ${formatMoneyCents(service.basePriceCents)} · ${_titleCase(service.status)}'),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.xs,
                                    children: [
                                      TextButton(
                                        onPressed: actionState.isLoading
                                            ? null
                                            : () => _showServiceDialog(
                                                  context,
                                                  ref,
                                                  categories: catalog,
                                                  service: service,
                                                ),
                                        child: const Text('Edit'),
                                      ),
                                      TextButton(
                                        onPressed: actionState.isLoading
                                            ? null
                                            : () => ref
                                                .read(adminActionControllerProvider.notifier)
                                                .toggleServiceStatus(
                                                  serviceId: service.id,
                                                  enable: service.status != 'active',
                                                ),
                                        child: Text(
                                          service.status == 'active' ? 'Disable' : 'Enable',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: EmptyState(
          title: 'Could not load services',
          description: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.design_services_outlined,
          actionLabel: 'Retry',
          onActionPressed: () => ref.invalidate(adminServiceCatalogProvider),
        ),
      ),
    );
  }
}

Future<void> _showServiceDialog(
  BuildContext context,
  WidgetRef ref, {
  required List<AdminServiceCategoryGroup> categories,
  AdminServiceSummary? service,
}) async {
  final nameController = TextEditingController(text: service?.name ?? '');
  final descriptionController = TextEditingController(text: service?.description ?? '');
  final durationController = TextEditingController(
    text: service?.durationMinutes.toString() ?? '',
  );
  final priceController = TextEditingController(
    text: service?.basePriceCents == null ? '' : (service!.basePriceCents! ~/ 100).toString(),
  );
  String selectedCategoryId = service?.serviceCategoryId ?? categories.first.id;
  String selectedStatus = service?.status ?? 'active';

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(service == null ? 'Create service' : 'Edit service'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    items: categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Service name'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(labelText: 'Duration minutes'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Base price in dollars'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != true) {
    return;
  }

  final durationMinutes = int.tryParse(durationController.text.trim());
  if (durationMinutes == null || durationMinutes <= 0) {
    return;
  }

  final dollars = int.tryParse(priceController.text.trim());
  await ref.read(adminActionControllerProvider.notifier).saveService(
        serviceId: service?.id,
        serviceCategoryId: selectedCategoryId,
        name: nameController.text,
        description: descriptionController.text,
        durationMinutes: durationMinutes,
        basePriceCents: dollars == null ? null : dollars * 100,
        status: selectedStatus,
      );
}

String _titleCase(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}