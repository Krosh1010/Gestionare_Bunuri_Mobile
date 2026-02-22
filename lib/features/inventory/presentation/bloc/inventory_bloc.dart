import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/asset.dart';

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

class FilterByStatus extends InventoryEvent {
  final AssetStatus? status;
  const FilterByStatus(this.status);
  @override
  List<Object?> get props => [status];
}

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
  final AssetStatus? selectedStatus;
  final String searchQuery;

  const InventoryLoaded({
    required this.assets,
    required this.filteredAssets,
    this.selectedCategory,
    this.selectedStatus,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [assets, filteredAssets, selectedCategory, selectedStatus, searchQuery];
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc() : super(InventoryInitial()) {
    on<LoadAssets>(_onLoadAssets);
    on<SearchAssets>(_onSearchAssets);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByStatus>(_onFilterByStatus);
    on<DeleteAssetEvent>(_onDeleteAsset);
  }

  // Date demo pentru prezentare
  final List<Asset> _demoAssets = [
    Asset(
      id: '1',
      name: 'Laptop Dell XPS 15',
      description: 'Laptop performant pentru dezvoltare software',
      serialNumber: 'DL-XPS-2024-001',
      category: AssetCategory.electronics,
      status: AssetStatus.active,
      location: 'Birou 101',
      value: 7500.00,
      purchaseDate: DateTime(2024, 3, 15),
      assignedTo: 'Ion Popescu',
    ),
    Asset(
      id: '2',
      name: 'Monitor LG UltraWide 34"',
      description: 'Monitor ultrawide pentru productivitate',
      serialNumber: 'LG-UW34-2024-002',
      category: AssetCategory.electronics,
      status: AssetStatus.active,
      location: 'Birou 101',
      value: 3200.00,
      purchaseDate: DateTime(2024, 5, 20),
      assignedTo: 'Ion Popescu',
    ),
    Asset(
      id: '3',
      name: 'Birou Ergonomic Standing Desk',
      description: 'Birou reglabil pe înălțime',
      serialNumber: 'SD-ERG-2024-003',
      category: AssetCategory.furniture,
      status: AssetStatus.active,
      location: 'Birou 102',
      value: 2800.00,
      purchaseDate: DateTime(2024, 1, 10),
    ),
    Asset(
      id: '4',
      name: 'Imprimantă HP LaserJet Pro',
      description: 'Imprimantă laser color multifuncțională',
      serialNumber: 'HP-LJ-2023-004',
      category: AssetCategory.equipment,
      status: AssetStatus.inRepair,
      location: 'Sala de Conferințe',
      value: 1500.00,
      purchaseDate: DateTime(2023, 8, 5),
    ),
    Asset(
      id: '5',
      name: 'Autoturism Dacia Duster',
      description: 'Vehicul de serviciu',
      serialNumber: 'DD-2023-005',
      category: AssetCategory.vehicles,
      status: AssetStatus.active,
      location: 'Parcarea Principală',
      value: 85000.00,
      purchaseDate: DateTime(2023, 6, 12),
      assignedTo: 'Maria Ionescu',
    ),
    Asset(
      id: '6',
      name: 'Proiector Epson EB-U05',
      description: 'Proiector Full HD pentru prezentări',
      serialNumber: 'EP-U05-2022-006',
      category: AssetCategory.electronics,
      status: AssetStatus.decommissioned,
      location: 'Depozit',
      value: 2100.00,
      purchaseDate: DateTime(2022, 2, 28),
    ),
    Asset(
      id: '7',
      name: 'Scaun Ergonomic Herman Miller',
      description: 'Scaun de birou ergonomic premium',
      serialNumber: 'HM-AER-2024-007',
      category: AssetCategory.furniture,
      status: AssetStatus.active,
      location: 'Birou 103',
      value: 4500.00,
      purchaseDate: DateTime(2024, 4, 1),
      assignedTo: 'Andrei Vasile',
    ),
    Asset(
      id: '8',
      name: 'Server Rack Dell PowerEdge',
      description: 'Server pentru infrastructura IT',
      serialNumber: 'DL-PE-2023-008',
      category: AssetCategory.equipment,
      status: AssetStatus.active,
      location: 'Camera Serverelor',
      value: 32000.00,
      purchaseDate: DateTime(2023, 11, 15),
    ),
  ];

  Future<void> _onLoadAssets(LoadAssets event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      emit(InventoryLoaded(assets: _demoAssets, filteredAssets: _demoAssets));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  void _onSearchAssets(SearchAssets event, Emitter<InventoryState> emit) {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      final query = event.query.toLowerCase();
      final filtered = currentState.assets.where((asset) {
        return asset.name.toLowerCase().contains(query) ||
            asset.location.toLowerCase().contains(query) ||
            (asset.serialNumber?.toLowerCase().contains(query) ?? false) ||
            (asset.assignedTo?.toLowerCase().contains(query) ?? false);
      }).toList();
      emit(InventoryLoaded(
        assets: currentState.assets,
        filteredAssets: filtered,
        selectedCategory: currentState.selectedCategory,
        selectedStatus: currentState.selectedStatus,
        searchQuery: event.query,
      ));
    }
  }

  void _onFilterByCategory(FilterByCategory event, Emitter<InventoryState> emit) {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      List<Asset> filtered = currentState.assets;
      if (event.category != null) {
        filtered = filtered.where((a) => a.category == event.category).toList();
      }
      if (currentState.selectedStatus != null) {
        filtered = filtered.where((a) => a.status == currentState.selectedStatus).toList();
      }
      emit(InventoryLoaded(
        assets: currentState.assets,
        filteredAssets: filtered,
        selectedCategory: event.category,
        selectedStatus: currentState.selectedStatus,
      ));
    }
  }

  void _onFilterByStatus(FilterByStatus event, Emitter<InventoryState> emit) {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      List<Asset> filtered = currentState.assets;
      if (currentState.selectedCategory != null) {
        filtered = filtered.where((a) => a.category == currentState.selectedCategory).toList();
      }
      if (event.status != null) {
        filtered = filtered.where((a) => a.status == event.status).toList();
      }
      emit(InventoryLoaded(
        assets: currentState.assets,
        filteredAssets: filtered,
        selectedCategory: currentState.selectedCategory,
        selectedStatus: event.status,
      ));
    }
  }

  void _onDeleteAsset(DeleteAssetEvent event, Emitter<InventoryState> emit) {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      final updatedAssets = currentState.assets.where((a) => a.id != event.assetId).toList();
      final updatedFiltered = currentState.filteredAssets.where((a) => a.id != event.assetId).toList();
      emit(InventoryLoaded(
        assets: updatedAssets,
        filteredAssets: updatedFiltered,
        selectedCategory: currentState.selectedCategory,
        selectedStatus: currentState.selectedStatus,
        searchQuery: currentState.searchQuery,
      ));
    }
  }
}

