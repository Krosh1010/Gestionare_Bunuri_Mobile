import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/asset.dart';
import '../bloc/asset_detail_cubit.dart';

class AssetDetailPage extends StatelessWidget {
  final String assetId;

  const AssetDetailPage({super.key, required this.assetId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetDetailCubit, AssetDetailState>(
      builder: (context, state) {
        if (state is AssetDetailLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Se încarcă detaliile...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is AssetDetailError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nu s-au putut încărca datele',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.read<AssetDetailCubit>().loadAssetDetail(assetId),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reîncearcă'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is AssetDetailLoaded) {
          return _AssetDetailView(asset: state.asset);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
class _AssetDetailView extends StatefulWidget {
  final Asset asset;
  const _AssetDetailView({required this.asset});

  @override
  State<_AssetDetailView> createState() => _AssetDetailViewState();
}

class _AssetDetailViewState extends State<_AssetDetailView> {
  Asset get asset => widget.asset;

  Future<void> _navigateToEdit() async {
    final result = await context.push('/inventory/edit', extra: asset);
    if (result == true && mounted) {
      context.read<AssetDetailCubit>().loadAssetDetail(asset.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildQuickStats(),
                _buildBasicInfoSection(),
                _buildWarrantySection(),
                _buildInsuranceSection(),
                _buildCustomTrackerSection(),
                _buildMetadataSection(),
                // Bottom action row
                _buildBottomActions(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SLIVER APP BAR ──────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      surfaceTintColor: AppColors.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: _navigateToEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Editează',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 36),
                _buildCategoryIcon(),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    asset.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        asset.categoryLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            asset.location,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    IconData icon;
    List<Color> colors;
    switch (asset.category) {
      case AssetCategory.electronics:
        icon = Icons.devices_rounded;
        colors = [const Color(0xFF818CF8), const Color(0xFF6366F1)];
        break;
      case AssetCategory.furniture:
        icon = Icons.chair_rounded;
        colors = [const Color(0xFF34D399), const Color(0xFF10B981)];
        break;
      case AssetCategory.vehicles:
        icon = Icons.directions_car_rounded;
        colors = [const Color(0xFFFBBF24), const Color(0xFFF59E0B)];
        break;
      case AssetCategory.documents:
        icon = Icons.description_rounded;
        colors = [const Color(0xFF60A5FA), const Color(0xFF3B82F6)];
        break;
      case AssetCategory.other:
        icon = Icons.category_rounded;
        colors = [const Color(0xFFC084FC), const Color(0xFFA855F7)];
        break;
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [colors[0].withValues(alpha: 0.35), colors[1].withValues(alpha: 0.25)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Icon(icon, size: 30, color: Colors.white),
    );
  }

  // ─── QUICK STATS ─────────────────────────────────────────────
  Widget _buildQuickStats() {
    final formatted = NumberFormat('#,##0', 'ro_RO').format(asset.value);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF10B981),
                label: 'Valoare',
                value: '$formatted RON',
              ),
            ),
            Container(width: 1, height: 40, color: AppColors.divider),
            Expanded(
              child: _StatItem(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF6366F1),
                label: 'Achiziționat',
                value: DateFormat('dd MMM yyyy', 'ro').format(asset.purchaseDate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BASIC INFO ──────────────────────────────────────────────
  Widget _buildBasicInfoSection() {
    final hasDescription = asset.description != null && asset.description!.isNotEmpty;
    if (!hasDescription) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Descriere',
      icon: Icons.notes_rounded,
      iconColor: const Color(0xFF6366F1),
      children: [
        Text(
          asset.description!,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ─── WARRANTY ────────────────────────────────────────────────
  Widget _buildWarrantySection() {
    final hasWarranty = asset.warrantyStatus != WarrantyStatus.unknown &&
        asset.warrantyStatus != WarrantyStatus.notStarted;
    final statusColor = _getWarrantyStatusColor(asset.warrantyStatus);

    return _SectionCard(
      title: 'Garanție',
      icon: Icons.verified_user_rounded,
      iconColor: const Color(0xFF3B82F6),
      statusBadge: _StatusPill(
        label: asset.warrantyStatusLabel,
        color: statusColor,
        showDot: hasWarranty,
      ),
      children: hasWarranty
          ? [
              if (asset.warrantyProvider != null)
                _InfoTile(
                  icon: Icons.business_rounded,
                  label: 'Furnizor',
                  value: asset.warrantyProvider!,
                ),
              if (asset.warrantyStartDate != null && asset.warrantyEndDate != null)
                _DateRangeRow(
                  start: asset.warrantyStartDate!,
                  end: asset.warrantyEndDate!,
                  daysLeft: asset.warrantyDaysLeft,
                  statusColor: statusColor,
                ),
            ]
          : [
              _EmptyHint(
                  message: 'Nicio garanție înregistrată',
                  icon: Icons.verified_user_rounded),
            ],
    );
  }

  // ─── INSURANCE ───────────────────────────────────────────────
  Widget _buildInsuranceSection() {
    final hasInsurance = asset.insuranceStatus != InsuranceStatus.unknown;
    final statusColor = _getInsuranceStatusColor(asset.insuranceStatus);

    return _SectionCard(
      title: 'Asigurare',
      icon: Icons.shield_rounded,
      iconColor: const Color(0xFF10B981),
      statusBadge: _StatusPill(
        label: asset.insuranceStatusLabel,
        color: statusColor,
        showDot: hasInsurance,
      ),
      children: hasInsurance
          ? [
              if (asset.insuranceCompany != null)
                _InfoTile(
                  icon: Icons.apartment_rounded,
                  label: 'Companie',
                  value: asset.insuranceCompany!,
                ),
              if (asset.insuranceValue != null)
                _InfoTile(
                  icon: Icons.savings_rounded,
                  label: 'Valoare Asigurată',
                  value:
                      '${NumberFormat('#,##0', 'ro_RO').format(asset.insuranceValue)} RON',
                  highlight: true,
                ),
              if (asset.insuranceStartDate != null && asset.insuranceEndDate != null)
                _DateRangeRow(
                  start: asset.insuranceStartDate!,
                  end: asset.insuranceEndDate!,
                  daysLeft: asset.insuranceDaysLeft,
                  statusColor: statusColor,
                ),
            ]
          : [
              _EmptyHint(
                  message: 'Nicio asigurare înregistrată',
                  icon: Icons.shield_rounded),
            ],
    );
  }

  // ─── CUSTOM TRACKER ──────────────────────────────────────────
  Widget _buildCustomTrackerSection() {
    final hasTracker = asset.customTrackerStatus != CustomTrackerStatus.unknown;
    final statusColor = _getTrackerStatusColor(asset.customTrackerStatus);

    return _SectionCard(
      title: asset.customTrackerName ?? 'Tracker Personalizat',
      icon: Icons.track_changes_rounded,
      iconColor: const Color(0xFFF59E0B),
      statusBadge: _StatusPill(
        label: asset.customTrackerStatusLabel,
        color: statusColor,
        showDot: hasTracker,
      ),
      children: hasTracker
          ? [
              if (asset.customTrackerEndDate != null)
                _InfoTile(
                  icon: Icons.event_busy_rounded,
                  label: 'Data Expirare',
                  value: DateFormat('dd MMMM yyyy', 'ro').format(asset.customTrackerEndDate!),
                ),
              if (asset.customTrackerDaysLeft != null)
                _DaysLeftBar(
                  daysLeft: asset.customTrackerDaysLeft!,
                  color: statusColor,
                ),
            ]
          : [
              _EmptyHint(
                message: 'Niciun tracker înregistrat',
                icon: Icons.track_changes_rounded,
              ),
            ],
    );
  }

  // ─── METADATA ────────────────────────────────────────────────
  Widget _buildMetadataSection() {
    if (asset.createdAt == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textHint),
          const SizedBox(width: 5),
          Text(
            'Adăugat în sistem: ${DateFormat('dd MMM yyyy', 'ro').format(asset.createdAt!)}',
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM ACTIONS ──────────────────────────────────────────
  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          // Delete button
          Expanded(
            child: _ActionButton(
              label: 'Șterge',
              icon: Icons.delete_outline_rounded,
              color: AppColors.error,
              outlined: true,
              onTap: () => _confirmDelete(context),
            ),
          ),
          const SizedBox(width: 12),
          // Edit button
          Expanded(
            flex: 2,
            child: _ActionButton(
              label: 'Editează Bunul',
              icon: Icons.edit_rounded,
              color: AppColors.primary,
              outlined: false,
              onTap: _navigateToEdit,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Șterge bunul',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'Ești sigur că vrei să ștergi '),
              TextSpan(
                text: '"${asset.name}"',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '? Această acțiune nu poate fi anulată.'),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(
                        color: AppColors.divider.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Anulează'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    _deleteAsset(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Șterge',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteAsset(BuildContext context) async {
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final cubit = context.read<AssetDetailCubit>();
    final success = await cubit.deleteAsset(asset.id);

    if (!context.mounted) return;
    Navigator.pop(context); // close loading

    if (success) {
      context.pop(); // go back to inventory list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Nu s-a putut șterge bunul. Încearcă din nou.')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ─── COLOR HELPERS ───────────────────────────────────────────
  Color _getWarrantyStatusColor(WarrantyStatus s) {
    switch (s) {
      case WarrantyStatus.notStarted: return AppColors.textHint;
      case WarrantyStatus.active: return AppColors.success;
      case WarrantyStatus.expiringSoon: return AppColors.warning;
      case WarrantyStatus.expired: return AppColors.error;
      case WarrantyStatus.unknown: return AppColors.textHint;
    }
  }

  Color _getInsuranceStatusColor(InsuranceStatus s) {
    switch (s) {
      case InsuranceStatus.active: return AppColors.success;
      case InsuranceStatus.expiringSoon: return AppColors.warning;
      case InsuranceStatus.expired: return AppColors.error;
      case InsuranceStatus.notStarted: return AppColors.textHint;
      case InsuranceStatus.unknown: return AppColors.textHint;
    }
  }

  Color _getTrackerStatusColor(CustomTrackerStatus s) {
    switch (s) {
      case CustomTrackerStatus.active: return AppColors.success;
      case CustomTrackerStatus.expiringSoon: return AppColors.warning;
      case CustomTrackerStatus.expired: return AppColors.error;
      case CustomTrackerStatus.notStarted: return AppColors.textHint;
      case CustomTrackerStatus.unknown: return AppColors.textHint;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget? statusBadge;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.statusBadge,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (statusBadge != null) statusBadge!,
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.6)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
              color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: highlight ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final int? daysLeft;
  final Color statusColor;

  const _DateRangeRow({
    required this.start,
    required this.end,
    required this.daysLeft,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'ro');
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _DateCol(label: 'Început', date: fmt.format(start)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.textHint),
              ),
              _DateCol(label: 'Expirare', date: fmt.format(end), isEnd: true),
            ],
          ),
          if (daysLeft != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.hourglass_bottom_rounded, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  daysLeft! > 0 ? '$daysLeft zile rămase' : 'Expirat',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DateCol extends StatelessWidget {
  final String label;
  final String date;
  final bool isEnd;

  const _DateCol({required this.label, required this.date, this.isEnd = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(date,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DaysLeftBar extends StatelessWidget {
  final int daysLeft;
  final Color color;

  const _DaysLeftBar({required this.daysLeft, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_bottom_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            daysLeft > 0 ? '$daysLeft zile rămase' : 'Expirat',
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;

  const _StatusPill(
      {required this.label, required this.color, this.showDot = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyHint({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          message,
          style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 13,
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.outlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: color.withValues(alpha: 0.04),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shadowColor: color.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
