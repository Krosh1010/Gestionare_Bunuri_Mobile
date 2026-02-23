import '../../domain/entities/warranty_summary.dart';
import '../../domain/entities/insurance_summary.dart';
import '../../domain/entities/coverage_asset.dart';
import '../../domain/repositories/coverage_repository.dart';
import '../datasources/coverage_remote_datasource.dart';
import '../models/warranty_summary_model.dart';
import '../models/insurance_summary_model.dart';
import '../models/coverage_asset_model.dart';

class CoverageRepositoryImpl implements CoverageRepository {
  final CoverageRemoteDataSource remoteDataSource;

  CoverageRepositoryImpl({required this.remoteDataSource});

  // ─── Warranty ───────────────────────────────────────────────
  @override
  Future<WarrantySummary> getWarrantySummary() async {
    final json = await remoteDataSource.getWarrantySummary();
    return WarrantySummaryModel.fromJson(json);
  }

  @override
  Future<List<CoverageAsset>> getExpiredWarrantyAssets() async {
    final jsonList = await remoteDataSource.getExpiredWarrantyAssets();
    return jsonList.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getValidWarrantyAssets() async {
    final jsonList = await remoteDataSource.getValidWarrantyAssets();
    return jsonList.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getExpiringWarrantyAssets() async {
    final jsonList = await remoteDataSource.getExpiringWarrantyAssets();
    return jsonList.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getAssetsWithoutWarranty() async {
    final jsonList = await remoteDataSource.getAssetsWithoutWarranty();
    return jsonList.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  // ─── Insurance ──────────────────────────────────────────────
  @override
  Future<InsuranceSummary> getInsuranceSummary() async {
    final json = await remoteDataSource.getInsuranceSummary();
    return InsuranceSummaryModel.fromJson(json);
  }

  @override
  Future<List<CoverageAsset>> getExpiredInsuranceAssets() async {
    final jsonList = await remoteDataSource.getExpiredInsuranceAssets();
    return jsonList.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getValidInsuranceAssets() async {
    final jsonList = await remoteDataSource.getValidInsuranceAssets();
    return jsonList.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getExpiringInsuranceAssets() async {
    final jsonList = await remoteDataSource.getExpiringInsuranceAssets();
    return jsonList.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getAssetsWithoutInsurance() async {
    final jsonList = await remoteDataSource.getAssetsWithoutInsurance();
    return jsonList.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }
}
