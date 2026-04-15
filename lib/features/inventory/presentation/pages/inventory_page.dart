import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../bloc/inventory_bloc.dart';
import '../../../spaces/domain/entities/space.dart';
import '../../../spaces/domain/repositories/spaces_repository.dart';
import 'barcode_scanner_page.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InventoryBloc>()..add(LoadAssets()),
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

  Future<void> _navigateToAdd() async {
    await context.push('/inventory/add');
    if (mounted) {
      context.read<InventoryBloc>().add(LoadAssets());
    }
  }

  Future<void> _navigateToDetail(Asset asset) async {
    await context.push('/inventory/${asset.id}');
    if (mounted) {
      context.read<InventoryBloc>().add(LoadAssets());
    }
  }

  // ─── BARCODE SCAN & SEARCH
  Future<void> _scanBarcodeAndSearch(BuildContext context) async {
    // 1. Deschide scanner-ul
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (barcode == null || barcode.isEmpty || !mounted) return;

    // Așteptăm ca navigator-ul să termine tranziția de la scanner
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // 2. Afișează loading
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Se caută bunul...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 3. Caută bunul pe backend
      final asset = await sl<InventoryRepository>().getAssetByBarcode(barcode);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // închide loading

      // 4. Succes → navigare la pagina de detalii cu datele deja primite
      await context.push('/inventory/barcode-result', extra: asset);
      if (mounted) {
        context.read<InventoryBloc>().add(LoadAssets());
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // închide loading

      // 5. Eroare (404 sau altceva) → dialog cu opțiuni
      _showBarcodeNotFoundDialog(context, barcode);
    }
  }

  void _showBarcodeNotFoundDialog(BuildContext context, String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_off_rounded, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Bun negăsit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nu s-a găsit niciun bun asociat cu acest cod de bare.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_rounded, color: AppColors.textHint, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      barcode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dorești să creezi un bun nou cu acest cod de bare?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anulează'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigare la adăugare bun – trimitem barcode-ul ca extra
              context.push('/inventory/add', extra: barcode);
            },
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            label: const Text('Creează bun', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context.read<InventoryBloc>().add(LoadAssets());
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStatsOverview(context)),
                    SliverToBoxAdapter(child: _buildSearchAndActions(context)),
                    SliverToBoxAdapter(child: _buildFilterChips(context)),
                    SliverToBoxAdapter(child: _buildResultsCount(context)),
                    _buildAssetList(context),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          AppStrings.addAsset,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ─── HEADER
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventar Bunuri',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Gestionează toate activele tale',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.qr_code_scanner_rounded,
                onTap: () => _scanBarcodeAndSearch(context),
              ),
              const SizedBox(width: 8),
              BlocBuilder<InventoryBloc, InventoryState>(
                builder: (context, state) {
                  final filterCount = state is InventoryLoaded ? state.activeFiltersCount : 0;
                  return _HeaderIconButton(
                    icon: Icons.tune_rounded,
                    badge: filterCount,
                    onTap: () => _showAdvancedFilters(context),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── STATS OVERVIEW
  Widget _buildStatsOverview(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is! InventoryLoaded) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  emoji: '📦',
                  value: '${state.totalCount}',
                  label: 'Total bunuri',
                  gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  emoji: '💰',
                  value: _formatCompactValue(state.totalValue),
                  label: 'Valoare totală',
                  gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCompactValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M RON';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K RON';
    }
    return '${value.toStringAsFixed(0)} RON';
  }

  // ─── SEARCH BAR
  Widget _buildSearchAndActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {});
          context.read<InventoryBloc>().add(SearchAssets(value));
        },
        decoration: InputDecoration(
          hintText: AppStrings.searchAssets,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    context.read<InventoryBloc>().add(const SearchAssets(''));
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

  // ─── FILTER CHIPS
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
              _CategoryChip(
                label: 'Toate',
                isSelected: selectedCategory == null,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(null)),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: 'Electronică',
                emoji: '💻',
                isSelected: selectedCategory == AssetCategory.electronics,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(AssetCategory.electronics)),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: 'Mobilier',
                emoji: '🛋️',
                isSelected: selectedCategory == AssetCategory.furniture,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(AssetCategory.furniture)),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: 'Vehicule',
                emoji: '🚗',
                isSelected: selectedCategory == AssetCategory.vehicles,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(AssetCategory.vehicles)),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: 'Documente',
                emoji: '📄',
                isSelected: selectedCategory == AssetCategory.documents,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(AssetCategory.documents)),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: 'Altele',
                emoji: '📁',
                isSelected: selectedCategory == AssetCategory.other,
                onTap: () => context.read<InventoryBloc>().add(const FilterByCategory(AssetCategory.other)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── RESULTS COUNT
  Widget _buildResultsCount(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        final count = state is InventoryLoaded ? state.filteredAssets.length : 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Text(
            '$count bunuri găsite',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        );
      },
    );
  }

  // ─── ASSET LIST
  Widget _buildAssetList(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is InventoryError) {
          return SliverFillRemaining(
            child: Center(
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
            ),
          );
        }

        if (state is InventoryLoaded) {
          final assets = state.filteredAssets;
          final page = state.page;
          final pageSize = state.pageSize;

          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (assets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('Nu există bunuri pe această pagină.')),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: assets.length,
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      return _AssetListCard(
                        asset: asset,
                        onTap: (a) => _navigateToDetail(a),
                      );
                    },
                  ),
                // PAGINARE - vizibilă mereu!
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: page > 1
                            ? () => context.read<InventoryBloc>().add(LoadAssets(
                                  page: page - 1,
                                  pageSize: pageSize,
                                  name: state.searchQuery.isNotEmpty ? state.searchQuery : null,
                                  category: state.selectedCategory?.name ??
                                      (state.activeCategories.isNotEmpty ? state.activeCategories.first.name : null),
                                  minValue: state.priceMin,
                                  maxValue: state.priceMax,
                                  spaceId: state.selectedSpaceId,
                                  spaceName: state.selectedSpaceName,
                                ))
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Pagina $page', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: assets.length == pageSize
                            ? () => context.read<InventoryBloc>().add(LoadAssets(
                                  page: page + 1,
                                  pageSize: pageSize,
                                  name: state.searchQuery.isNotEmpty ? state.searchQuery : null,
                                  category: state.selectedCategory?.name ??
                                      (state.activeCategories.isNotEmpty ? state.activeCategories.first.name : null),
                                  minValue: state.priceMin,
                                  maxValue: state.priceMax,
                                  spaceId: state.selectedSpaceId,
                                  spaceName: state.selectedSpaceName,
                                ))
                            : null,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          );
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  // ─── EMPTY STATE
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text('📦', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nu s-au găsit bunuri',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Încearcă să modifici filtrele sau adaugă un bun nou',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _navigateToAdd,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Adaugă primul bun',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ADVANCED FILTERS
  void _showAdvancedFilters(BuildContext context) {
    final bloc = context.read<InventoryBloc>();
    final state = bloc.state;
    Set<AssetCategory> selectedCategories = {};
    double? priceMin;
    double? priceMax;
    int? selectedSpaceId;
    String? selectedSpaceName;

    if (state is InventoryLoaded) {
      selectedCategories = Set.from(state.activeCategories);
      priceMin = state.priceMin;
      priceMax = state.priceMax;
      selectedSpaceId = state.selectedSpaceId;
      selectedSpaceName = state.selectedSpaceName;
    }

    final priceMinController = TextEditingController(
      text: priceMin != null ? priceMin.toStringAsFixed(0) : '',
    );
    final priceMaxController = TextEditingController(
      text: priceMax != null ? priceMax.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Filtre avansate',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Category ──
                      _FilterSectionTitle(emoji: '📊', title: 'Categorie'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _AdvancedFilterChip(
                            emoji: '💻', label: 'Electronice',
                            isSelected: selectedCategories.contains(AssetCategory.electronics),
                            onTap: () => setModalState(() => selectedCategories.contains(AssetCategory.electronics)
                                ? selectedCategories.remove(AssetCategory.electronics)
                                : selectedCategories.add(AssetCategory.electronics)),
                          ),
                          _AdvancedFilterChip(
                            emoji: '🛋️', label: 'Mobilier',
                            isSelected: selectedCategories.contains(AssetCategory.furniture),
                            onTap: () => setModalState(() => selectedCategories.contains(AssetCategory.furniture)
                                ? selectedCategories.remove(AssetCategory.furniture)
                                : selectedCategories.add(AssetCategory.furniture)),
                          ),
                          _AdvancedFilterChip(
                            emoji: '🚗', label: 'Vehicule',
                            isSelected: selectedCategories.contains(AssetCategory.vehicles),
                            onTap: () => setModalState(() => selectedCategories.contains(AssetCategory.vehicles)
                                ? selectedCategories.remove(AssetCategory.vehicles)
                                : selectedCategories.add(AssetCategory.vehicles)),
                          ),
                          _AdvancedFilterChip(
                            emoji: '📄', label: 'Documente',
                            isSelected: selectedCategories.contains(AssetCategory.documents),
                            onTap: () => setModalState(() => selectedCategories.contains(AssetCategory.documents)
                                ? selectedCategories.remove(AssetCategory.documents)
                                : selectedCategories.add(AssetCategory.documents)),
                          ),
                          _AdvancedFilterChip(
                            emoji: '📁', label: 'Altele',
                            isSelected: selectedCategories.contains(AssetCategory.other),
                            onTap: () => setModalState(() => selectedCategories.contains(AssetCategory.other)
                                ? selectedCategories.remove(AssetCategory.other)
                                : selectedCategories.add(AssetCategory.other)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: AppColors.divider.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      // ── Price ──
                      _FilterSectionTitle(emoji: '💰', title: 'Preț (RON)'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _PriceInput(label: 'Min', controller: priceMinController, hint: '0')),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('—', style: TextStyle(color: AppColors.textHint, fontSize: 18)),
                          ),
                          Expanded(child: _PriceInput(label: 'Max', controller: priceMaxController, hint: '∞')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: AppColors.divider.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      // ── Location picker ──
                      _FilterSectionTitle(emoji: '📍', title: 'Locație'),
                      const SizedBox(height: 10),
                      // Show currently selected space as a chip
                      if (selectedSpaceId != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    selectedSpaceName ?? 'Spațiu #$selectedSpaceId',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setModalState(() {
                                    selectedSpaceId = null;
                                    selectedSpaceName = null;
                                  }),
                                  child: const Icon(Icons.close_rounded, color: AppColors.primary, size: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // 2-level space picker
                      _SpacePicker(
                        initialSpaceId: selectedSpaceId,
                        onSpaceSelected: (id, name) => setModalState(() {
                          selectedSpaceId = id;
                          selectedSpaceName = name;
                        }),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          bloc.add(ClearFilters());
                          _searchController.clear();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Resetează'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final pMin = double.tryParse(priceMinController.text);
                          final pMax = double.tryParse(priceMaxController.text);
                          bloc.add(ApplyAdvancedFilters(
                            categories: selectedCategories,
                            priceMin: pMin,
                            priceMax: pMax,
                            spaceId: selectedSpaceId,
                            spaceName: selectedSpaceName,
                          ));
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                        label: const Text('Aplică filtre', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// REUSABLE WIDGETS


// ─── HEADER ICON BUTTON
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: AppColors.textSecondary, size: 22),
            constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            padding: EdgeInsets.zero,
          ),
        ),
        if (badge > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── STAT CARD
class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final List<Color> gradient;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [gradient[0].withValues(alpha: 0.12), gradient[1].withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── CATEGORY CHIP
class _CategoryChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.5),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FILTER SECTION TITLE
class _FilterSectionTitle extends StatelessWidget {
  final String emoji;
  final String title;

  const _FilterSectionTitle({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ─── ADVANCED FILTER CHIP
class _AdvancedFilterChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdvancedFilterChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PRICE INPUT
class _PriceInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _PriceInput({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}


// ASSET LIST CARD

class _AssetListCard extends StatelessWidget {
  final Asset asset;
  final void Function(Asset) onTap;

  const _AssetListCard({
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'ro_RO', symbol: 'RON', decimalDigits: 0);
    final dateFormatter = DateFormat('dd.MM.yyyy');

    return GestureDetector(
      onTap: () => onTap(asset),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main content row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon
                  _CategoryIconBox(category: asset.category),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          asset.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Description
                        if (asset.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            asset.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textHint,
                                  fontSize: 12,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Details row: value + location
                        Row(
                          children: [
                            _DetailChip(
                              icon: Icons.attach_money_rounded,
                              text: formatter.format(asset.value),
                              color: AppColors.primary,
                              isBold: true,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DetailChip(
                                icon: Icons.location_on_outlined,
                                text: asset.location,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _DetailChip(
                              icon: Icons.calendar_today_outlined,
                              text: dateFormatter.format(asset.purchaseDate),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chevron to indicate tappable
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 22),
                  ),
                ],
              ),
            ),
            // Warranty / Insurance footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Loaned badge
                  if (asset.isLoaned)
                    _LoanedBadge(),
                  // Warranty badge
                  _WarrantyBadge(
                    emoji: '🛡️',
                    label: asset.warrantyStatusLabel,
                    status: asset.warrantyStatus,
                  ),
                  // Insurance badge
                  _InsuranceBadge(
                    emoji: '📄',
                    label: asset.insuranceStatusLabel,
                    status: asset.insuranceStatus,
                  ),
                  // Custom Tracker badge
                  _CustomTrackerBadge(
                    emoji: '🎯',
                    label: asset.customTrackerName != null
                        ? '${asset.customTrackerName}: ${asset.customTrackerStatusLabel}'
                        : asset.customTrackerStatusLabel,
                    status: asset.customTrackerStatus,
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


// SHARED SMALL WIDGETS


class _CategoryIconBox extends StatelessWidget {
  final AssetCategory category;
  final double size;

  const _CategoryIconBox({required this.category, this.size = 52});

  String _emoji() {
    switch (category) {
      case AssetCategory.electronics: return '💻';
      case AssetCategory.furniture: return '🛋️';
      case AssetCategory.vehicles: return '🚗';
      case AssetCategory.documents: return '📄';
      case AssetCategory.other: return '📁';
    }
  }

  List<Color> _gradientColors() {
    switch (category) {
      case AssetCategory.electronics: return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
      case AssetCategory.furniture: return [const Color(0xFF10B981), const Color(0xFF22C55E)];
      case AssetCategory.vehicles: return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case AssetCategory.documents: return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case AssetCategory.other: return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradientColors();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[0].withValues(alpha: 0.12), colors[1].withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Text(_emoji(), style: TextStyle(fontSize: size * 0.45)),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final bool isBold;

  const _DetailChip({
    required this.icon,
    required this.text,
    this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? AppColors.textHint),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: color ?? AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _WarrantyBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final WarrantyStatus status;

  const _WarrantyBadge({
    required this.emoji,
    required this.label,
    required this.status,
  });

  Color _bgColor() {
    switch (status) {
      case WarrantyStatus.notStarted: return const Color(0xFF9CA3AF);
      case WarrantyStatus.active: return const Color(0xFF4F46E5);
      case WarrantyStatus.expiringSoon: return const Color(0xFFFB923C);
      case WarrantyStatus.expired: return const Color(0xFFEF4444);
      case WarrantyStatus.unknown: return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _bgColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsuranceBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final InsuranceStatus status;

  const _InsuranceBadge({
    required this.emoji,
    required this.label,
    required this.status,
  });

  Color _bgColor() {
    switch (status) {
      case InsuranceStatus.active: return const Color(0xFF22C55E);
      case InsuranceStatus.expiringSoon: return const Color(0xFFFBBF24);
      case InsuranceStatus.expired: return const Color(0xFFEF4444);
      case InsuranceStatus.notStarted: return const Color(0xFF9CA3AF);
      case InsuranceStatus.unknown: return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _bgColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTrackerBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final CustomTrackerStatus status;

  const _CustomTrackerBadge({
    required this.emoji,
    required this.label,
    required this.status,
  });

  Color _bgColor() {
    switch (status) {
      case CustomTrackerStatus.active: return const Color(0xFFFF6B35);
      case CustomTrackerStatus.expiringSoon: return const Color(0xFFFBBF24);
      case CustomTrackerStatus.expired: return const Color(0xFFEF4444);
      case CustomTrackerStatus.notStarted: return const Color(0xFF9CA3AF);
      case CustomTrackerStatus.unknown: return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _bgColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: c,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanedBadge extends StatelessWidget {
  const _LoanedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_clock_rounded, size: 12, color: AppColors.error),
          const SizedBox(width: 4),
          Text(
            'Împrumutat',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}


// SPACE PICKER – simple two-level dropdowns

class _SpacePicker extends StatefulWidget {
  final int? initialSpaceId;
  final void Function(int id, String name) onSpaceSelected;

  const _SpacePicker({
    required this.onSpaceSelected,
    this.initialSpaceId,
  });

  @override
  State<_SpacePicker> createState() => _SpacePickerState();
}

class _SpacePickerState extends State<_SpacePicker> {
  List<Space> _parents = [];
  List<Space> _children = [];
  Space? _selectedParent;
  Space? _selectedChild;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  Future<void> _loadParents() async {
    try {
      final repo = sl<SpacesRepository>();
      final parents = await repo.getParentSpaces();
      Space? initParent;
      Space? initChild;

      // If there's an initial selection, figure out which parent/child it belongs to
      if (widget.initialSpaceId != null) {
        for (final p in parents) {
          if (p.id == widget.initialSpaceId) {
            initParent = p;
            break;
          }
        }
        // If not found among parents, it might be a child – load children for each parent
        if (initParent == null) {
          for (final p in parents) {
            if (p.childrenCount > 0) {
              try {
                final children = await repo.getChildrenSpaces(p.id);
                final match = children.where((c) => c.id == widget.initialSpaceId).firstOrNull;
                if (match != null) {
                  initParent = p;
                  initChild = match;
                  if (mounted) setState(() => _children = children);
                  break;
                }
              } catch (_) {}
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _parents = parents;
          _selectedParent = initParent;
          _selectedChild = initChild;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _onParentChanged(Space? parent) async {
    if (parent == null) {
      setState(() {
        _selectedParent = null;
        _selectedChild = null;
        _children = [];
      });
      return;
    }

    setState(() {
      _selectedParent = parent;
      _selectedChild = null;
      _children = [];
    });

    // Always allow selecting the parent itself
    widget.onSpaceSelected(parent.id, parent.name);

    // Load children if any
    if (parent.childrenCount > 0) {
      try {
        final repo = sl<SpacesRepository>();
        final children = await repo.getChildrenSpaces(parent.id);
        if (mounted) setState(() => _children = children);
      } catch (_) {}
    }
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Text('Eroare la încărcarea spațiilor',
          style: TextStyle(color: AppColors.error, fontSize: 13));
    }
    if (_parents.isEmpty) {
      return Text('Nu există spații create.',
          style: TextStyle(color: AppColors.textHint, fontSize: 13));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Parent dropdown ──
        DropdownButtonFormField<Space>(
          value: _selectedParent,
          isExpanded: true,
          decoration: _dropdownDecoration('Selectează spațiul'),
          hint: const Text('Selectează spațiul', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
          items: [
            const DropdownMenuItem<Space>(
              value: null,
              child: Text('— Niciun spațiu —', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
            ),
            ..._parents.map((p) => DropdownMenuItem<Space>(
              value: p,
              child: Row(
                children: [
                  Text(p.typeEmoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.childrenCount > 0 ? '${p.name}  (${p.childrenCount} sub-spații)' : p.name,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
          ],
          onChanged: _onParentChanged,
        ),

        // ── Child dropdown (only when parent has children) ──
        if (_selectedParent != null && _children.isNotEmpty) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<Space>(
            value: _selectedChild,
            isExpanded: true,
            decoration: _dropdownDecoration('Selectează sub-spațiul (opțional)'),
            hint: const Text('Sub-spațiu (opțional)',
                style: TextStyle(fontSize: 14, color: AppColors.textHint)),
            items: [
              const DropdownMenuItem<Space>(
                value: null,
                child: Text('— Tot spațiul —',
                    style: TextStyle(fontSize: 14, color: AppColors.textHint)),
              ),
              ..._children.map((c) => DropdownMenuItem<Space>(
                value: c,
                child: Row(
                  children: [
                    Text(c.typeEmoji, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c.name,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              )),
            ],
            onChanged: (child) {
              setState(() => _selectedChild = child);
              if (child != null) {
                widget.onSpaceSelected(child.id, child.name);
              } else if (_selectedParent != null) {
                widget.onSpaceSelected(_selectedParent!.id, _selectedParent!.name);
              }
            },
          ),
        ],
      ],
    );
  }
}
