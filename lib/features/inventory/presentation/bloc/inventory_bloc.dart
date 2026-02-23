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

class LoadAssets extends InventoryEvent {}

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
  final String? spaceFilter;

  const ApplyAdvancedFilters({
    required this.categories,
    this.priceMin,
    this.priceMax,
    this.spaceFilter,
  });

  @override
  List<Object?> get props => [categories, priceMin, priceMax, spaceFilter];
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
  final List<Asset> filteredAssets;
  final AssetCategory? selectedCategory;
  final String searchQuery;
  final Set<AssetCategory> activeCategories;
  final double? priceMin;
  final double? priceMax;
  final String? spaceFilter;

  const InventoryLoaded({
    required this.assets,
    required this.filteredAssets,
    this.selectedCategory,
    this.searchQuery = '',
    this.activeCategories = const {},
    this.priceMin,
    this.priceMax,
    this.spaceFilter,
  });

  int get totalAssets => assets.length;
  double get totalValue => assets.fold(0.0, (sum, a) => sum + a.value);

  int get activeFiltersCount {
    int count = 0;
    if (activeCategories.isNotEmpty) count++;
    if (priceMin != null) count++;
    if (priceMax != null) count++;
    if (spaceFilter != null && spaceFilter!.isNotEmpty) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        assets,
        filteredAssets,
        selectedCategory,
        searchQuery,
        activeCategories,
        priceMin,
        priceMax,
        spaceFilter,
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

  List<Asset> _applyAllFilters({
    required List<Asset> assets,
    String searchQuery = '',
    AssetCategory? selectedCategory,
    Set<AssetCategory> activeCategories = const {},
    double? priceMin,
    double? priceMax,
    String? spaceFilter,
  }) {
    var filtered = List<Asset>.from(assets);

    // Search
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((asset) {
        return asset.name.toLowerCase().contains(query) ||
            asset.location.toLowerCase().contains(query) ||
            (asset.description?.toLowerCase().contains(query) ?? false) ||
            (asset.spaceName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Category (simple filter)
    if (selectedCategory != null) {
      filtered = filtered.where((a) => a.category == selectedCategory).toList();
    }

    // Advanced category filter
    if (activeCategories.isNotEmpty) {
      filtered = filtered.where((a) => activeCategories.contains(a.category)).toList();
    }

    // Price range
    if (priceMin != null) {
      filtered = filtered.where((a) => a.value >= priceMin).toList();
    }
    if (priceMax != null) {
      filtered = filtered.where((a) => a.value <= priceMax).toList();
    }

    // Space filter
    if (spaceFilter != null && spaceFilter.isNotEmpty) {
      final loc = spaceFilter.toLowerCase();
      filtered = filtered.where((a) => a.location.toLowerCase().contains(loc)).toList();
    }

    return filtered;
  }

  Future<void> _onLoadAssets(LoadAssets event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final assets = await repository.getAssets();
      emit(InventoryLoaded(
        assets: assets,
        filteredAssets: assets,
      ));
    } catch (e) {
      emit(InventoryError('Nu s-au putut încărca bunurile: ${e.toString()}'));
    }
  }

  void _onSearchAssets(SearchAssets event, Emitter<InventoryState> emit) {
    if (state is InventoryLoaded) {
      final s = state as InventoryLoaded;
      final filtered = _applyAllFilters(
        assets: s.assets,
        searchQuery: event.query,
        selectedCategory: s.selectedCategory,
        activeCategories: s.activeCategories,
        priceMin: s.priceMin,
        priceMax: s.priceMax,
        spaceFilter: s.spaceFilter,
      );
      emit(InventoryLoaded(
        assets: s.assets,
        filteredAssets: filtered,
        selectedCategory: s.selectedCategory,
        searchQuery: event.query,
        activeCategories: s.activeCategories,
        priceMin: s.priceMin,
        priceMax: s.priceMax,
        spaceFilter: s.spaceFilter,
      ));
    }
  }

  void _onFilterByCategory(FilterByCategory event, Emitter<InventoryState> emit) {
    if (state is InventoryLoaded) {
      final s = state as InventoryLoaded;
      final filtered = _applyAllFilters(
        assets: s.assets,
        searchQuery: s.searchQuery,
        selectedCategory: event.category,
        activeCategories: s.activeCategories,
        priceMin: s.priceMin,
        priceMax: s.priceMax,
        spaceFilter: s.spaceFilter,
      );
      emit(InventoryLoaded(
        assets: s.assets,
        filteredAssets: filtered,
        selectedCategory: event.category,
        searchQuery: s.searchQuery,
        activeCategories: s.activeCategories,
        priceMin: s.priceMin,
        priceMax: s.priceMax,
        spaceFilter: s.spaceFilter,
      ));
    }
  }

  void _onApplyAdvancedFilters(ApplyAdvancedFilters event, Emitter<InventoryState> emit) {
    if (state is InventoryLoaded) {
      final s = state as InventoryLoaded;
      final filtered = _applyAllFilters(
        assets: s.assets,
        searchQuery: s.searchQuery,
        selectedCategory: null,
        activeCategories: event.categories,
        priceMin: event.priceMin,
        priceMax: event.priceMax,
        spaceFilter: event.spaceFilter,
      );
      emit(InventoryLoaded(
        assets: s.assets,
        filteredAssets: filtered,
        selectedCategory: null,
        searchQuery: s.searchQuery,
        activeCategories: event.categories,
        priceMin: event.priceMin,
        priceMax: event.priceMax,
        spaceFilter: event.spaceFilter,
      ));
    }
  }

  void _onClearFilters(ClearFilters event, Emitter<InventoryState> emit) {
    if (state is InventoryLoaded) {
      final s = state as InventoryLoaded;
      emit(InventoryLoaded(
        assets: s.assets,
        filteredAssets: s.assets,
        searchQuery: '',
      ));
    }
  }

  Future<void> _onDeleteAsset(DeleteAssetEvent event, Emitter<InventoryState> emit) async {
    if (state is InventoryLoaded) {
      final s = state as InventoryLoaded;
      try {
        await repository.deleteAsset(event.assetId);
        final updatedAssets = s.assets.where((a) => a.id != event.assetId).toList();
        final updatedFiltered = s.filteredAssets.where((a) => a.id != event.assetId).toList();
        emit(InventoryLoaded(
          assets: updatedAssets,
          filteredAssets: updatedFiltered,
          selectedCategory: s.selectedCategory,
          searchQuery: s.searchQuery,
          activeCategories: s.activeCategories,
          priceMin: s.priceMin,
          priceMax: s.priceMax,
          spaceFilter: s.spaceFilter,
        ));
      } catch (e) {
        emit(InventoryError('Nu s-a putut șterge bunul: ${e.toString()}'));
      }
    }
  }
}

