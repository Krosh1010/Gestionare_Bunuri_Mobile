import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/warranty_summary.dart';
import '../../domain/entities/coverage_asset.dart';
import '../../domain/repositories/coverage_repository.dart';

// ─── Events ─────────────────────────────────────────────────────
abstract class CoverageEvent extends Equatable {
  const CoverageEvent();
  @override
  List<Object?> get props => [];
}

class LoadWarrantySummary extends CoverageEvent {}

class LoadWarrantyAssets extends CoverageEvent {
  final WarrantyFilter filter;
  final int page;
  final int pageSize;
  const LoadWarrantyAssets(this.filter, {this.page = 1, this.pageSize = 10});
  @override
  List<Object?> get props => [filter, page, pageSize];
}

class ClearWarrantyAssets extends CoverageEvent {}

class ChangeWarrantyPage extends CoverageEvent {
  final int page;
  const ChangeWarrantyPage(this.page);
  @override
  List<Object?> get props => [page];
}

enum WarrantyFilter { expired, valid, expiringSoon, withoutWarranty }

// ─── States ─────────────────────────────────────────────────────
abstract class CoverageState extends Equatable {
  const CoverageState();
  @override
  List<Object?> get props => [];
}

class CoverageInitial extends CoverageState {}

class CoverageLoading extends CoverageState {}

class CoverageSummaryLoaded extends CoverageState {
  final WarrantySummary summary;
  final WarrantyFilter? activeFilter;
  final List<CoverageAsset>? assets;
  final bool assetsLoading;
  final int page;
  final int pageSize;

  const CoverageSummaryLoaded({
    required this.summary,
    this.activeFilter,
    this.assets,
    this.assetsLoading = false,
    this.page = 1,
    this.pageSize = 10,
  });

  CoverageSummaryLoaded copyWith({
    WarrantySummary? summary,
    WarrantyFilter? activeFilter,
    List<CoverageAsset>? assets,
    bool? assetsLoading,
    int? page,
    int? pageSize,
    bool clearFilter = false,
  }) {
    return CoverageSummaryLoaded(
      summary: summary ?? this.summary,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      assets: clearFilter ? null : (assets ?? this.assets),
      assetsLoading: assetsLoading ?? this.assetsLoading,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [summary, activeFilter, assets, assetsLoading, page, pageSize];
}

class CoverageError extends CoverageState {
  final String message;
  const CoverageError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───────────────────────────────────────────────────────
class CoverageBloc extends Bloc<CoverageEvent, CoverageState> {
  final CoverageRepository repository;

  CoverageBloc({required this.repository}) : super(CoverageInitial()) {
    on<LoadWarrantySummary>(_onLoadWarrantySummary);
    on<LoadWarrantyAssets>(_onLoadWarrantyAssets);
    on<ClearWarrantyAssets>(_onClearWarrantyAssets);
    on<ChangeWarrantyPage>(_onChangeWarrantyPage);
  }

  Future<void> _onLoadWarrantySummary(
    LoadWarrantySummary event,
    Emitter<CoverageState> emit,
  ) async {
    emit(CoverageLoading());
    try {
      final summary = await repository.getWarrantySummary();
      emit(CoverageSummaryLoaded(summary: summary));
    } catch (e) {
      emit(CoverageError(message: e.toString()));
    }
  }

  Future<void> _onLoadWarrantyAssets(
    LoadWarrantyAssets event,
    Emitter<CoverageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CoverageSummaryLoaded) return;

    emit(currentState.copyWith(
      activeFilter: event.filter,
      assetsLoading: true,
    ));

    try {
      List<CoverageAsset> assets;
      switch (event.filter) {
        case WarrantyFilter.expired:
          assets = await repository.getExpiredWarrantyAssets(page: event.page, pageSize: event.pageSize);
          break;
        case WarrantyFilter.valid:
          assets = await repository.getValidWarrantyAssets(page: event.page, pageSize: event.pageSize);
          break;
        case WarrantyFilter.expiringSoon:
          assets = await repository.getExpiringWarrantyAssets(page: event.page, pageSize: event.pageSize);
          break;
        case WarrantyFilter.withoutWarranty:
          assets = await repository.getAssetsWithoutWarranty(page: event.page, pageSize: event.pageSize);
          break;
      }
      // Re-read state in case it changed
      final latestState = state;
      if (latestState is CoverageSummaryLoaded) {
        emit(latestState.copyWith(
          assets: assets,
          assetsLoading: false,
        ));
      }
    } catch (e) {
      final latestState = state;
      if (latestState is CoverageSummaryLoaded) {
        emit(latestState.copyWith(assetsLoading: false));
      }
    }
  }

  void _onClearWarrantyAssets(
    ClearWarrantyAssets event,
    Emitter<CoverageState> emit,
  ) {
    final currentState = state;
    if (currentState is CoverageSummaryLoaded) {
      emit(currentState.copyWith(clearFilter: true));
    }
  }

  Future<void> _onChangeWarrantyPage(
    ChangeWarrantyPage event,
    Emitter<CoverageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CoverageSummaryLoaded) return;
    final page = event.page;
    final pageSize = currentState.pageSize;
    final filter = currentState.activeFilter;
    emit(currentState.copyWith(assetsLoading: true, page: page));
    try {
      List<CoverageAsset> assets = [];
      if (filter != null) {
        switch (filter) {
          case WarrantyFilter.expired:
            assets = await repository.getExpiredWarrantyAssets(page: page, pageSize: pageSize);
            break;
          case WarrantyFilter.valid:
            assets = await repository.getValidWarrantyAssets(page: page, pageSize: pageSize);
            break;
          case WarrantyFilter.expiringSoon:
            assets = await repository.getExpiringWarrantyAssets(page: page, pageSize: pageSize);
            break;
          case WarrantyFilter.withoutWarranty:
            assets = await repository.getAssetsWithoutWarranty(page: page, pageSize: pageSize);
            break;
        }
      }
      final latestState = state;
      if (latestState is CoverageSummaryLoaded) {
        emit(latestState.copyWith(
          assets: assets,
          assetsLoading: false,
          page: page,
        ));
      }
    } catch (e) {
      final latestState = state;
      if (latestState is CoverageSummaryLoaded) {
        emit(latestState.copyWith(assetsLoading: false));
      }
    }
  }
}
