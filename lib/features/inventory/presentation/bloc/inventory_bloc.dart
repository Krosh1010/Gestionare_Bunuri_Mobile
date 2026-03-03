import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/inventory_repository.dart';

// Events
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadAssets extends InventoryEvent {
  final int page;
  final int pageSize;
  final String? name;
  final String? category;
  final double? minValue;
  final double? maxValue;
  final int? spaceId;
  final String? spaceName; // ← added to preserve filter name across pages

  const LoadAssets({
    this.page = 1,
    this.pageSize = 10,
    this.name,
    this.category,
    this.minValue,
    this.maxValue,
    this.spaceId,
    this.spaceName,
  });

  @override
  List<Object?> get props => [page, pageSize, name, category, minValue, maxValue, spaceId, spaceName];
}

class SearchAssets extends InventoryEvent {
  final String query;
  const SearchAssets(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterByCategory extends InventoryEvent {
  final AssetCategory? category;
  const FilterByCategory(this.category);
  @override
  List<Object?> get props => [category];
}

class ApplyAdvancedFilters extends InventoryEvent {
  final Set<AssetCategory> categories;
  final double? priceMin;
  final double? priceMax;
  final int? spaceId;        // ← was spaceFilter (String)
  final String? spaceName;   // display only

  const ApplyAdvancedFilters({
    required this.categories,
    this.priceMin,
    this.priceMax,
    this.spaceId,
    this.spaceName,
  });

  @override
  List<Object?> get props => [categories, priceMin, priceMax, spaceId, spaceName];
}

class ClearFilters extends InventoryEvent {}

class DeleteAssetEvent extends InventoryEvent {
  final String assetId;
  const DeleteAssetEvent(this.assetId);
  @override
  List<Object?> get props => [assetId];
}

// States
abstract class InventoryState extends Equatable {
  const InventoryState();
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<Asset> assets;
  final int totalCount;
  final double totalValue;
  final int page;
  final int pageSize;
  final String searchQuery;
  final AssetCategory? selectedCategory;
  final Set<AssetCategory> activeCategories;
  final double? priceMin;
  final double? priceMax;
  final int? selectedSpaceId;     // ← was spaceFilter (String)
  final String? selectedSpaceName; // display only

  const InventoryLoaded({
    required this.assets,
    required this.totalCount,
    required this.totalValue,
    this.page = 1,
    this.pageSize = 10,
    this.searchQuery = '',
    this.selectedCategory,
    this.activeCategories = const {},
    this.priceMin,
    this.priceMax,
    this.selectedSpaceId,
    this.selectedSpaceName,
  });

  List<Asset> get filteredAssets => assets;

  int get activeFiltersCount {
    int count = 0;
    if (activeCategories.isNotEmpty) count++;
    if (priceMin != null) count++;
    if (priceMax != null) count++;
    if (selectedSpaceId != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        assets,
        totalCount,
        totalValue,
        page,
        pageSize,
        searchQuery,
        selectedCategory,
        activeCategories,
        priceMin,
        priceMax,
        selectedSpaceId,
        selectedSpaceName,
      ];
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository repository;

  InventoryBloc({required this.repository}) : super(InventoryInitial()) {
    on<LoadAssets>(_onLoadAssets);
    on<SearchAssets>(_onSearchAssets);
    on<FilterByCategory>(_onFilterByCategory);
    on<ApplyAdvancedFilters>(_onApplyAdvancedFilters);
    on<ClearFilters>(_onClearFilters);
    on<DeleteAssetEvent>(_onDeleteAsset);
  }

  String? _categoryToString(AssetCategory? category) {
    if (category == null) return null;
    return category.name;
  }

  /// Emits InventoryLoaded preserving all active filters from [prev] state,
  /// overriding only [page] (and optionally other fields passed explicitly).
  Future<void> _fetchAndEmit(
    Emitter<InventoryState> emit, {
    required int page,
    required int pageSize,
    String? name,
    String? category,
    double? minValue,
    double? maxValue,
    int? spaceId,
    String searchQuery = '',
    AssetCategory? selectedCategory,
    Set<AssetCategory> activeCategories = const {},
    double? priceMin,
    double? priceMax,
    int? selectedSpaceId,
    String? selectedSpaceName,
  }) async {
    final result = await repository.getAssets(
      page: page,
      pageSize: pageSize,
      name: name,
      category: category,
      minValue: minValue,
      maxValue: maxValue,
      spaceId: spaceId,
    );
    emit(InventoryLoaded(
      assets: result.items,
      totalCount: result.totalCount,
      totalValue: result.totalValue,
      page: page,
      pageSize: pageSize,
      searchQuery: searchQuery,
      selectedCategory: selectedCategory,
      activeCategories: activeCategories,
      priceMin: priceMin,
      priceMax: priceMax,
      selectedSpaceId: selectedSpaceId,
      selectedSpaceName: selectedSpaceName,
    ));
  }

  Future<void> _onLoadAssets(LoadAssets event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      // Derive selectedCategory and activeCategories from event.category string
      final matchedCategory = event.category != null
          ? AssetCategory.values.where((c) => c.name == event.category).firstOrNull
          : null;
      await _fetchAndEmit(
        emit,
        page: event.page,
        pageSize: event.pageSize,
        name: event.name,
        category: event.category,
        minValue: event.minValue,
        maxValue: event.maxValue,
        spaceId: event.spaceId,
        searchQuery: event.name ?? '',
        selectedCategory: matchedCategory,
        activeCategories: matchedCategory != null ? {matchedCategory} : const {},
        priceMin: event.minValue,
        priceMax: event.maxValue,
        selectedSpaceId: event.spaceId,
        selectedSpaceName: event.spaceName, // Pass spaceName through to preserve filter
      );
    } catch (e) {
      emit(InventoryError('Nu s-au putut încărca bunurile: ${e.toString()}'));
    }
  }

  Future<void> _onSearchAssets(SearchAssets event, Emitter<InventoryState> emit) async {
    final s = state is InventoryLoaded ? state as InventoryLoaded : null;
    emit(InventoryLoading());
    try {
      final categoryStr = s?.activeCategories.isNotEmpty == true
          ? _categoryToString(s!.activeCategories.first)
          : _categoryToString(s?.selectedCategory);
      await _fetchAndEmit(
        emit,
        page: 1,
        pageSize: s?.pageSize ?? 10,
        name: event.query.isNotEmpty ? event.query : null,
        category: categoryStr,
        minValue: s?.priceMin,
        maxValue: s?.priceMax,
        spaceId: s?.selectedSpaceId,
        searchQuery: event.query,
        selectedCategory: s?.selectedCategory,
        activeCategories: s?.activeCategories ?? const {},
        priceMin: s?.priceMin,
        priceMax: s?.priceMax,
        selectedSpaceId: s?.selectedSpaceId,
        selectedSpaceName: s?.selectedSpaceName,
      );
    } catch (e) {
      emit(InventoryError('Nu s-au putut încărca bunurile: ${e.toString()}'));
    }
  }

  Future<void> _onFilterByCategory(FilterByCategory event, Emitter<InventoryState> emit) async {
    final s = state is InventoryLoaded ? state as InventoryLoaded : null;
    emit(InventoryLoading());
    try {
      final newActiveCategories = event.category != null ? {event.category!} : <AssetCategory>{};
      await _fetchAndEmit(
        emit,
        page: 1,
        pageSize: s?.pageSize ?? 10,
        name: s?.searchQuery.isNotEmpty == true ? s!.searchQuery : null,
        category: _categoryToString(event.category),
        minValue: s?.priceMin,
        maxValue: s?.priceMax,
        spaceId: s?.selectedSpaceId,
        searchQuery: s?.searchQuery ?? '',
        selectedCategory: event.category,
        activeCategories: newActiveCategories,
        priceMin: s?.priceMin,
        priceMax: s?.priceMax,
        selectedSpaceId: s?.selectedSpaceId,
        selectedSpaceName: s?.selectedSpaceName,
      );
    } catch (e) {
      emit(InventoryError('Nu s-au putut încărca bunurile: ${e.toString()}'));
    }
  }

  Future<void> _onApplyAdvancedFilters(ApplyAdvancedFilters event, Emitter<InventoryState> emit) async {
    final s = state is InventoryLoaded ? state as InventoryLoaded : null;
    emit(InventoryLoading());
    try {
      final categoryStr = event.categories.isNotEmpty
          ? _categoryToString(event.categories.first)
          : null;
      // Keep selectedCategory in sync with the chip bar
      final selectedCategory = event.categories.length == 1 ? event.categories.first : null;
      await _fetchAndEmit(
        emit,
        page: 1,
        pageSize: s?.pageSize ?? 10,
        name: s?.searchQuery.isNotEmpty == true ? s!.searchQuery : null,
        category: categoryStr,
        minValue: event.priceMin,
        maxValue: event.priceMax,
        spaceId: event.spaceId,
        searchQuery: s?.searchQuery ?? '',
        selectedCategory: selectedCategory,
        activeCategories: event.categories,
        priceMin: event.priceMin,
        priceMax: event.priceMax,
        selectedSpaceId: event.spaceId,
        selectedSpaceName: event.spaceName,
      );
    } catch (e) {
      emit(InventoryError('Nu s-au putut încărca bunurile: ${e.toString()}'));
    }
  }

  Future<void> _onClearFilters(ClearFilters event, Emitter<InventoryState> emit) async {
    final s = state is InventoryLoaded ? state as InventoryLoaded : null;
    emit(InventoryLoading());
    try {
      await _fetchAndEmit(
        emit,
        page: 1,
        pageSize: s?.pageSize ?? 10,
      );
    } catch (e) {
      emit(InventoryError('Nu s-au putut încărca bunurile: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteAsset(DeleteAssetEvent event, Emitter<InventoryState> emit) async {
    if (state is InventoryLoaded) {
      final s = state as InventoryLoaded;
      try {
        await repository.deleteAsset(event.assetId);
        final updatedAssets = s.assets.where((a) => a.id != event.assetId).toList();
        final removedValue = s.assets
            .where((a) => a.id == event.assetId)
            .fold(0.0, (sum, a) => sum + a.value);
        emit(InventoryLoaded(
          assets: updatedAssets,
          totalCount: (s.totalCount - 1).clamp(0, s.totalCount),
          totalValue: (s.totalValue - removedValue).clamp(0.0, s.totalValue),
          page: s.page,
          pageSize: s.pageSize,
          searchQuery: s.searchQuery,
          selectedCategory: s.selectedCategory,
          activeCategories: s.activeCategories,
          priceMin: s.priceMin,
          priceMax: s.priceMax,
          selectedSpaceId: s.selectedSpaceId,
          selectedSpaceName: s.selectedSpaceName,
        ));
      } catch (e) {
        emit(InventoryError('Nu s-a putut șterge bunul: ${e.toString()}'));
      }
    }
  }
}
