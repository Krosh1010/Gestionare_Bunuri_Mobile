import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/asset.dart';

class AssetDetailPage extends StatelessWidget {
  final String assetId;

  const AssetDetailPage({super.key, required this.assetId});

  // Date demo - în producție se va lua din bloc/repository
  Asset get _demoAsset => Asset(
        id: assetId,
        name: 'Laptop Dell XPS 15',
        description:
            'Laptop performant pentru dezvoltare software cu procesor Intel Core i9, 32GB RAM, 1TB SSD, ecran OLED 3.5K.',
        serialNumber: 'DL-XPS-2024-001',
        category: AssetCategory.electronics,
        status: AssetStatus.active,
        location: 'Birou 101',
        value: 7500.00,
        purchaseDate: DateTime(2024, 3, 15),
        lastUpdated: DateTime(2024, 12, 20),
        assignedTo: 'Ion Popescu',
      );

  Color _statusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.active:
        return AppColors.success;
      case AssetStatus.inRepair:
        return AppColors.warning;
      case AssetStatus.decommissioned:
        return AppColors.error;
      case AssetStatus.transferred:
        return AppColors.accent;
    }
  }

  IconData _categoryIcon(AssetCategory category) {
    switch (category) {
      case AssetCategory.electronics:
        return Icons.devices_rounded;
      case AssetCategory.furniture:
        return Icons.chair_rounded;
      case AssetCategory.vehicles:
        return Icons.directions_car_rounded;
      case AssetCategory.equipment:
        return Icons.build_rounded;
      case AssetCategory.other:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = _demoAsset;
    final formatter = NumberFormat.currency(locale: 'ro_RO', symbol: 'RON', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMMM yyyy', 'ro');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 10),
                            Text(AppStrings.edit),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                            SizedBox(width: 10),
                            Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _categoryIcon(asset.category),
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        asset.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(asset.status).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          asset.statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Value Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Valoare Estimată',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatter.format(asset.value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details Section
                  Text(
                    'Informații Generale',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _DetailCard(
                    children: [
                      _DetailRow(
                        icon: Icons.category_rounded,
                        label: AppStrings.assetCategory,
                        value: asset.categoryLabel,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.location_on_rounded,
                        label: AppStrings.assetLocation,
                        value: asset.location,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.qr_code_rounded,
                        label: AppStrings.assetSerialNumber,
                        value: asset.serialNumber ?? '-',
                      ),
                      if (asset.assignedTo != null) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.person_rounded,
                          label: 'Atribuit',
                          value: asset.assignedTo!,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dates Section
                  Text(
                    'Date Importante',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _DetailCard(
                    children: [
                      _DetailRow(
                        icon: Icons.shopping_cart_rounded,
                        label: AppStrings.assetPurchaseDate,
                        value: dateFormatter.format(asset.purchaseDate),
                      ),
                      if (asset.lastUpdated != null) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.update_rounded,
                          label: 'Ultima actualizare',
                          value: dateFormatter.format(asset.lastUpdated!),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (asset.description != null && asset.description!.isNotEmpty) ...[
                    Text(
                      AppStrings.assetDescription,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        asset.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text(AppStrings.edit),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Transfer'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(AppStrings.deleteAsset),
        content: const Text(AppStrings.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

