import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'insurance_form_sheet.dart';
import 'warranty_form_sheet.dart';

class AssetDetailPage extends StatefulWidget {
  final Asset asset;

  const AssetDetailPage({super.key, required this.asset});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  late Asset _asset;

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
  }

  Future<void> _refreshAsset() async {
    try {
      // Folosim getMyAssets (GET /Assets/my) care returnează datele complete cu warranty/insurance
      final allAssets = await sl<InventoryRepository>().getAssets();
      final updated = allAssets.where((a) => a.id == _asset.id).firstOrNull;
      if (updated != null && mounted) {
        setState(() => _asset = updated);
      }
    } catch (_) {}
  }

  Future<void> _navigateToEdit() async {
    final result = await context.push<bool>('/inventory/edit', extra: _asset);
    if (result == true && mounted) {
      await _refreshAsset();
    }
  }

  Future<void> _showWarrantySheet() async {
    final assetId = int.tryParse(_asset.id);
    if (assetId == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WarrantyFormSheet(assetId: assetId),
    );
    if (mounted) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Garanția a fost actualizată!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      await _refreshAsset();
    }
  }

  Future<void> _showInsuranceSheet() async {
    final assetId = int.tryParse(_asset.id);
    if (assetId == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InsuranceFormSheet(assetId: assetId),
    );
    if (mounted) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Asigurarea a fost actualizată!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      await _refreshAsset();
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
      case AssetCategory.documents:
        return Icons.description_rounded;
      case AssetCategory.other:
        return Icons.category_rounded;
    }
  }

  Color _warrantyColor(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return const Color(0xFF4F46E5);
      case WarrantyStatus.expiringSoon:
        return const Color(0xFFFB923C);
      case WarrantyStatus.expired:
        return const Color(0xFFEF4444);
      case WarrantyStatus.unknown:
        return const Color(0xFF9CA3AF);
    }
  }

  Color _insuranceColor(InsuranceStatus status) {
    switch (status) {
      case InsuranceStatus.active:
        return const Color(0xFF22C55E);
      case InsuranceStatus.expiringSoon:
        return const Color(0xFFFBBF24);
      case InsuranceStatus.expired:
        return const Color(0xFFEF4444);
      case InsuranceStatus.notStarted:
        return const Color(0xFF9CA3AF);
      case InsuranceStatus.unknown:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'ro_RO', symbol: 'RON', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMMM yyyy', 'ro');
    final asset = _asset;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 180,
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
                      if (value == 'edit') {
                        _navigateToEdit();
                      } else if (value == 'delete') {
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          asset.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                          style: TextStyle(color: Colors.white70, fontSize: 14),
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

                  // Informații Generale
                  Text('Informații Generale', style: Theme.of(context).textTheme.titleLarge),
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
                        label: 'Spațiu',
                        value: asset.location,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.shopping_cart_rounded,
                        label: AppStrings.assetPurchaseDate,
                        value: dateFormatter.format(asset.purchaseDate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Garanție
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🛡️ Garanție', style: Theme.of(context).textTheme.titleLarge),
                      TextButton.icon(
                        onPressed: _showWarrantySheet,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Editează'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _DetailCard(
                    children: [
                      _StatusRow(
                        icon: Icons.verified_rounded,
                        label: 'Status garanție',
                        value: asset.warrantyStatusLabel,
                        color: _warrantyColor(asset.warrantyStatus),
                      ),
                      if (asset.warrantyStartDate != null) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Început garanție',
                          value: dateFormatter.format(asset.warrantyStartDate!),
                        ),
                      ],
                      if (asset.warrantyEndDate != null) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.event_rounded,
                          label: 'Sfârșit garanție',
                          value: dateFormatter.format(asset.warrantyEndDate!),
                        ),
                      ],
                      if (asset.warrantyProvider != null && asset.warrantyProvider!.isNotEmpty) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.business_rounded,
                          label: 'Furnizor garanție',
                          value: asset.warrantyProvider!,
                        ),
                      ],
                      if (asset.warrantyDaysLeft != null) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.timer_rounded,
                          label: 'Zile rămase',
                          value: '${asset.warrantyDaysLeft} zile',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Asigurare
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📄 Asigurare', style: Theme.of(context).textTheme.titleLarge),
                      TextButton.icon(
                        onPressed: _showInsuranceSheet,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Editează'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _DetailCard(
                    children: [
                      _StatusRow(
                        icon: Icons.security_rounded,
                        label: 'Status asigurare',
                        value: asset.insuranceStatusLabel,
                        color: _insuranceColor(asset.insuranceStatus),
                      ),
                      if (asset.insuranceStartDate != null) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Început asigurare',
                          value: dateFormatter.format(asset.insuranceStartDate!),
                        ),
                      ],
                      if (asset.insuranceEndDate != null) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.event_rounded,
                          label: 'Sfârșit asigurare',
                          value: dateFormatter.format(asset.insuranceEndDate!),
                        ),
                      ],
                      if (asset.insuranceCompany != null && asset.insuranceCompany!.isNotEmpty) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.business_rounded,
                          label: 'Companie asigurări',
                          value: asset.insuranceCompany!,
                        ),
                      ],
                      if (asset.insuranceValue != null) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.attach_money_rounded,
                          label: 'Valoare asigurare',
                          value: formatter.format(asset.insuranceValue),
                        ),
                      ],
                      if (asset.insuranceDaysLeft != null) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.timer_rounded,
                          label: 'Zile rămase',
                          value: '${asset.insuranceDaysLeft} zile',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Descriere
                  if (asset.description != null && asset.description!.isNotEmpty) ...[
                    Text(AppStrings.assetDescription, style: Theme.of(context).textTheme.titleLarge),
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
                          onPressed: _navigateToEdit,
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
                          onPressed: () => _showDeleteDialog(context),
                          icon: const Icon(Icons.delete_rounded, color: Colors.white),
                          label: const Text('Șterge', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
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
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(AppStrings.deleteAsset),
        content: const Text(AppStrings.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await sl<InventoryRepository>().deleteAsset(_asset.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Bunul a fost șters cu succes!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Eroare la ștergere: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.delete, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DETAIL WIDGETS
// ═══════════════════════════════════════════════════════════════════

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
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
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
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatusRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

