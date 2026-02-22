import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/asset.dart';
import '../bloc/inventory_bloc.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventoryBloc()..add(LoadAssets()),
      child: const _InventoryView(),
    );
  }
}

class _InventoryView extends StatefulWidget {
  const _InventoryView();

  @override
  State<_InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<_InventoryView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            // Search Bar
            _buildSearchBar(context),
            // Filter Chips
            _buildFilterChips(context),
            // Asset List
            Expanded(
              child: _buildAssetList(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          AppStrings.addAsset,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.inventory,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              BlocBuilder<InventoryBloc, InventoryState>(
                builder: (context, state) {
                  final count = state is InventoryLoaded ? state.filteredAssets.length : 0;
                  return Text(
                    '$count bunuri găsite',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  );
                },
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            child: IconButton(
              onPressed: () => _showSortOptions(context),
              icon: const Icon(Icons.sort_rounded, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<InventoryBloc>().add(SearchAssets(value));
        },
        decoration: InputDecoration(
          hintText: AppStrings.searchAssets,
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                  onPressed: () {
                    _searchController.clear();
                    context.read<InventoryBloc>().add(const SearchAssets(''));
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        final selectedCategory = state is InventoryLoaded ? state.selectedCategory : null;
        return SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _FilterChip(
                label: 'Toate',
                isSelected: selectedCategory == null,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(null)),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Electronică',
                icon: Icons.devices_rounded,
                isSelected: selectedCategory == AssetCategory.electronics,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(AssetCategory.electronics)),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Mobilier',
                icon: Icons.chair_rounded,
                isSelected: selectedCategory == AssetCategory.furniture,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(AssetCategory.furniture)),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Vehicule',
                icon: Icons.directions_car_rounded,
                isSelected: selectedCategory == AssetCategory.vehicles,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(AssetCategory.vehicles)),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Echipamente',
                icon: Icons.build_rounded,
                isSelected: selectedCategory == AssetCategory.equipment,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(AssetCategory.equipment)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssetList(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is InventoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(state.message, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.read<InventoryBloc>().add(LoadAssets()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(AppStrings.retry),
                ),
              ],
            ),
          );
        }

        if (state is InventoryLoaded) {
          if (state.filteredAssets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.textHint.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noAssetsFound,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Încearcă să modifici filtrele sau adaugă un bun nou',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
            itemCount: state.filteredAssets.length,
            itemBuilder: (context, index) {
              final asset = state.filteredAssets[index];
              return _AssetCard(asset: asset);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(AppStrings.sortBy, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _sortOption(context, Icons.sort_by_alpha_rounded, 'Nume (A-Z)'),
            _sortOption(context, Icons.attach_money_rounded, 'Valoare (descrescător)'),
            _sortOption(context, Icons.calendar_today_rounded, 'Data achiziției'),
            _sortOption(context, Icons.location_on_rounded, 'Locație'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(BuildContext context, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => Navigator.pop(context),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final Asset asset;

  const _AssetCard({required this.asset});

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
    final formatter = NumberFormat.currency(locale: 'ro_RO', symbol: 'RON', decimalDigits: 0);
    final dateFormatter = DateFormat('dd.MM.yyyy');

    return GestureDetector(
      onTap: () => context.push('/inventory/${asset.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _categoryIcon(asset.category),
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          asset.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(asset.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          asset.statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(asset.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        asset.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        dateFormatter.format(asset.purchaseDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (asset.assignedTo != null)
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              asset.assignedTo!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        formatter.format(asset.value),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

