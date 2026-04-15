import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/inventory_repository.dart';

// States
abstract class AssetDetailState extends Equatable {
  const AssetDetailState();
  @override
  List<Object?> get props => [];
}

class AssetDetailInitial extends AssetDetailState {}

class AssetDetailLoading extends AssetDetailState {}

class AssetDetailLoaded extends AssetDetailState {
  final Asset asset;
  const AssetDetailLoaded(this.asset);
  @override
  List<Object?> get props => [asset];
}

class AssetDetailError extends AssetDetailState {
  final String message;
  const AssetDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class AssetDetailCubit extends Cubit<AssetDetailState> {
  final InventoryRepository repository;

  AssetDetailCubit({required this.repository}) : super(AssetDetailInitial());


  void loadFromAsset(Asset asset) {
    emit(AssetDetailLoaded(asset));
  }

  Future<void> loadAssetDetail(String assetId) async {
    emit(AssetDetailLoading());
    try {
      final asset = await repository.getAssetById(assetId);
      emit(AssetDetailLoaded(asset));
    } catch (e) {
      emit(AssetDetailError('Nu s-au putut încărca detaliile bunului: ${e.toString()}'));
    }
  }

  Future<void> refreshAsset(String assetId) async {
    try {
      final asset = await repository.getAssetById(assetId);
      emit(AssetDetailLoaded(asset));
    } catch (e) {
      emit(AssetDetailError('Nu s-au putut reîncărca detaliile: ${e.toString()}'));
    }
  }

  Future<bool> deleteAsset(String assetId) async {
    try {
      await repository.deleteAsset(assetId);
      return true;
    } catch (e) {
      emit(AssetDetailError('Nu s-a putut șterge bunul: ${e.toString()}'));
      return false;
    }
  }

  Future<Uint8List> downloadWarrantyDocument(int assetId) async {
    return await repository.downloadWarrantyDocument(assetId);
  }

  Future<Uint8List> downloadInsuranceDocument(int assetId) async {
    return await repository.downloadInsuranceDocument(assetId);
  }
}
