import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/coverage_asset.dart';
import '../../domain/entities/warranty_summary.dart';
import '../bloc/coverage_bloc.dart';

class WarrantyPage extends StatelessWidget {
  const WarrantyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: BlocBuilder<CoverageBloc, CoverageState>(
          builder: (context, state) {
            if (state is CoverageLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CoverageError) {
              return _buildError(context, state.message);
            }

            if (state is CoverageSummaryLoaded) {
              return _buildContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'Eroare la încărcarea datelor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CoverageBloc>().add(LoadWarrantySummary());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reîncearcă'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CoverageSummaryLoaded state) {
    final summary = state.summary;

    return CustomScrollView(
      slivers: [
        // ── App Bar ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Garanții',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),

        // ── Summary Card ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _WarrantySummaryCard(summary: summary),
          ),
        ),

        // ── Filter Buttons ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrează după stare',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                _FilterButtonsRow(
                  summary: summary,
                  activeFilter: state.activeFilter,
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Assets List ──
        if (state.assetsLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (state.assets != null && state.assets!.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 56, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text(
                      'Nu au fost găsite bunuri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (state.assets != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final asset = state.assets![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AssetCard(
                      asset: asset,
                      filter: state.activeFilter!,
                    ),
                  );
                },
                childCount: state.assets!.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─── Summary Card ───────────────────────────────────────────────
class _WarrantySummaryCard extends StatelessWidget {
  final WarrantySummary summary;

  const _WarrantySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2E5090)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rezumat Garanții',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _SummaryStatItem(
                  label: 'Total',
                  value: summary.totalCount.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              Expanded(
                child: _SummaryStatItem(
                  label: 'Active',
                  value: summary.validMoreThanMonthCount.toString(),
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryStatItem(
                  label: 'Expiră curând',
                  value: summary.expiringSoonCount.toString(),
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              Expanded(
                child: _SummaryStatItem(
                  label: 'Expirate',
                  value: summary.expiredCount.toString(),
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryStatItem(
                  label: 'Fără garanție',
                  value: summary.assetsWithoutWarrantyCount.toString(),
                  icon: Icons.remove_circle_outline,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Buttons ─────────────────────────────────────────────
class _FilterButtonsRow extends StatelessWidget {
  final WarrantySummary summary;
  final WarrantyFilter? activeFilter;

  const _FilterButtonsRow({
    required this.summary,
    this.activeFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChip(
          label: 'Expirate',
          count: summary.expiredCount,
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_outlined,
          isSelected: activeFilter == WarrantyFilter.expired,
          onTap: () {
            if (activeFilter == WarrantyFilter.expired) {
              context.read<CoverageBloc>().add(ClearWarrantyAssets());
            } else {
              context.read<CoverageBloc>().add(
                    const LoadWarrantyAssets(WarrantyFilter.expired),
                  );
            }
          },
        ),
        _FilterChip(
          label: 'Expiră curând',
          count: summary.expiringSoonCount,
          color: const Color(0xFFF59E0B),
          icon: Icons.warning_amber_rounded,
          isSelected: activeFilter == WarrantyFilter.expiringSoon,
          onTap: () {
            if (activeFilter == WarrantyFilter.expiringSoon) {
              context.read<CoverageBloc>().add(ClearWarrantyAssets());
            } else {
              context.read<CoverageBloc>().add(
                    const LoadWarrantyAssets(WarrantyFilter.expiringSoon),
                  );
            }
          },
        ),
        _FilterChip(
          label: 'Active',
          count: summary.validMoreThanMonthCount,
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_outline,
          isSelected: activeFilter == WarrantyFilter.valid,
          onTap: () {
            if (activeFilter == WarrantyFilter.valid) {
              context.read<CoverageBloc>().add(ClearWarrantyAssets());
            } else {
              context.read<CoverageBloc>().add(
                    const LoadWarrantyAssets(WarrantyFilter.valid),
                  );
            }
          },
        ),
        _FilterChip(
          label: 'Fără garanție',
          count: summary.assetsWithoutWarrantyCount,
          color: const Color(0xFF6B7280),
          icon: Icons.remove_circle_outline,
          isSelected: activeFilter == WarrantyFilter.withoutWarranty,
          onTap: () {
            if (activeFilter == WarrantyFilter.withoutWarranty) {
              context.read<CoverageBloc>().add(ClearWarrantyAssets());
            } else {
              context.read<CoverageBloc>().add(
                    const LoadWarrantyAssets(WarrantyFilter.withoutWarranty),
                  );
            }
          },
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Asset Card ─────────────────────────────────────────────────
class _AssetCard extends StatelessWidget {
  final CoverageAsset asset;
  final WarrantyFilter filter;

  const _AssetCard({
    required this.asset,
    required this.filter,
  });

  Color get _statusColor {
    switch (filter) {
      case WarrantyFilter.expired:
        return const Color(0xFFEF4444);
      case WarrantyFilter.expiringSoon:
        return const Color(0xFFF59E0B);
      case WarrantyFilter.valid:
        return const Color(0xFF10B981);
      case WarrantyFilter.withoutWarranty:
        return const Color(0xFF6B7280);
    }
  }

  String get _statusLabel {
    switch (filter) {
      case WarrantyFilter.expired:
        return 'Expirată';
      case WarrantyFilter.expiringSoon:
        return '${asset.daysLeft} zile rămase';
      case WarrantyFilter.valid:
        return '${asset.daysLeft} zile rămase';
      case WarrantyFilter.withoutWarranty:
        return 'Fără garanție';
    }
  }

  IconData get _categoryIcon {
    switch (asset.category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'furniture':
        return Icons.chair;
      case 'vehicles':
        return Icons.directions_car;
      case 'documents':
        return Icons.description;
      default:
        return Icons.category;
    }
  }

  String get _categoryLabel {
    switch (asset.category.toLowerCase()) {
      case 'electronics':
        return 'Electronică';
      case 'furniture':
        return 'Mobilier';
      case 'vehicles':
        return 'Vehicule';
      case 'documents':
        return 'Documente';
      default:
        return 'Altele';
    }
  }

  bool get _showDates => filter != WarrantyFilter.withoutWarranty && asset.startDate != null && asset.endDate != null;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'ro_RO');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: name + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon, color: _statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.assetName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.business, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            asset.company,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.label_outline, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          _categoryLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (asset.provider.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.storefront_outlined, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              asset.provider,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (_showDates) ...[
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: const Color(0xFFF3F4F6),
            ),
            const SizedBox(height: 14),
            // Bottom row: dates + value
            Row(
              children: [
                _InfoTag(
                  icon: Icons.calendar_today_outlined,
                  label: dateFormat.format(asset.startDate!),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                _InfoTag(
                  icon: Icons.event_outlined,
                  label: dateFormat.format(asset.endDate!),
                ),
                const Spacer(),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: const Color(0xFFF3F4F6),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Spacer(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

