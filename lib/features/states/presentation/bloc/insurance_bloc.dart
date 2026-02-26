import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/insurance_summary.dart';
import '../../domain/entities/coverage_asset.dart';
import '../../domain/repositories/coverage_repository.dart';

// ─── Events ─────────────────────────────────────────────────────
abstract class InsuranceEvent extends Equatable {
  const InsuranceEvent();
  @override
  List<Object?> get props => [];
}

class LoadInsuranceSummary extends InsuranceEvent {}

class LoadInsuranceAssets extends InsuranceEvent {
  final InsuranceFilter filter;
  final int page;
  final int pageSize;
  const LoadInsuranceAssets(this.filter, {this.page = 1, this.pageSize = 10});
  @override
  List<Object?> get props => [filter, page, pageSize];
}

class ClearInsuranceAssets extends InsuranceEvent {}

enum InsuranceFilter { expired, valid, expiringSoon, withoutInsurance }

// ─── States ─────────────────────────────────────────────────────
abstract class InsuranceState extends Equatable {
  const InsuranceState();
  @override
  List<Object?> get props => [];
}

class InsuranceInitial extends InsuranceState {}

class InsuranceLoading extends InsuranceState {}

class InsuranceSummaryLoaded extends InsuranceState {
  final InsuranceSummary summary;
  final InsuranceFilter? activeFilter;
  final List<CoverageAsset>? assets;
  final bool assetsLoading;
  final int page;
  final int pageSize;

  const InsuranceSummaryLoaded({
    required this.summary,
    this.activeFilter,
    this.assets,
    this.assetsLoading = false,
    this.page = 1,
    this.pageSize = 10,
  });

  InsuranceSummaryLoaded copyWith({
    InsuranceSummary? summary,
    InsuranceFilter? activeFilter,
    List<CoverageAsset>? assets,
    bool? assetsLoading,
    int? page,
    int? pageSize,
    bool clearFilter = false,
  }) {
    return InsuranceSummaryLoaded(
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

class InsuranceError extends InsuranceState {
  final String message;
  const InsuranceError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───────────────────────────────────────────────────────
class InsuranceBloc extends Bloc<InsuranceEvent, InsuranceState> {
  final CoverageRepository repository;

  InsuranceBloc({required this.repository}) : super(InsuranceInitial()) {
    on<LoadInsuranceSummary>(_onLoadInsuranceSummary);
    on<LoadInsuranceAssets>(_onLoadInsuranceAssets);
    on<ClearInsuranceAssets>(_onClearInsuranceAssets);
  }

  Future<void> _onLoadInsuranceSummary(
    LoadInsuranceSummary event,
    Emitter<InsuranceState> emit,
  ) async {
    emit(InsuranceLoading());
    try {
      final summary = await repository.getInsuranceSummary();
      emit(InsuranceSummaryLoaded(summary: summary));
    } catch (e) {
      emit(InsuranceError(message: e.toString()));
    }
  }

  Future<void> _onLoadInsuranceAssets(
    LoadInsuranceAssets event,
    Emitter<InsuranceState> emit,
  ) async {
    final currentState = state;
    if (currentState is! InsuranceSummaryLoaded) return;

    emit(currentState.copyWith(
      activeFilter: event.filter,
      assetsLoading: true,
    ));

    try {
      List<CoverageAsset> assets;
      switch (event.filter) {
        case InsuranceFilter.expired:
          assets = await repository.getExpiredInsuranceAssets(page: event.page, pageSize: event.pageSize);
          break;
        case InsuranceFilter.valid:
          assets = await repository.getValidInsuranceAssets(page: event.page, pageSize: event.pageSize);
          break;
        case InsuranceFilter.expiringSoon:
          assets = await repository.getExpiringInsuranceAssets(page: event.page, pageSize: event.pageSize);
          break;
        case InsuranceFilter.withoutInsurance:
          assets = await repository.getAssetsWithoutInsurance(page: event.page, pageSize: event.pageSize);
          break;
      }
      final latestState = state;
      if (latestState is InsuranceSummaryLoaded) {
        emit(latestState.copyWith(
          assets: assets,
          assetsLoading: false,
          page: event.page,
        ));
      }
    } catch (e) {
      final latestState = state;
      if (latestState is InsuranceSummaryLoaded) {
        emit(latestState.copyWith(assetsLoading: false));
      }
    }
  }

  void _onClearInsuranceAssets(
    ClearInsuranceAssets event,
    Emitter<InsuranceState> emit,
  ) {
    final currentState = state;
    if (currentState is InsuranceSummaryLoaded) {
      emit(currentState.copyWith(clearFilter: true));
    }
  }
}
