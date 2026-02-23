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
  const LoadWarrantyAssets(this.filter);
  @override
  List<Object?> get props => [filter];
}

class ClearWarrantyAssets extends CoverageEvent {}

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

  const CoverageSummaryLoaded({
    required this.summary,
    this.activeFilter,
    this.assets,
    this.assetsLoading = false,
  });

  CoverageSummaryLoaded copyWith({
    WarrantySummary? summary,
    WarrantyFilter? activeFilter,
    List<CoverageAsset>? assets,
    bool? assetsLoading,
    bool clearFilter = false,
  }) {
    return CoverageSummaryLoaded(
      summary: summary ?? this.summary,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      assets: clearFilter ? null : (assets ?? this.assets),
      assetsLoading: assetsLoading ?? this.assetsLoading,
    );
  }

  @override
  List<Object?> get props => [summary, activeFilter, assets, assetsLoading];
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
          assets = await repository.getExpiredWarrantyAssets();
          break;
        case WarrantyFilter.valid:
          assets = await repository.getValidWarrantyAssets();
          break;
        case WarrantyFilter.expiringSoon:
          assets = await repository.getExpiringWarrantyAssets();
          break;
        case WarrantyFilter.withoutWarranty:
          assets = await repository.getAssetsWithoutWarranty();
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
}

