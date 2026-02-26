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
  Future<List<CoverageAsset>> getExpiredWarrantyAssets({int page = 1, int pageSize = 20}) async {
    final data = await remoteDataSource.getExpiredWarrantyAssets(page: page, pageSize: pageSize);
    return data.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getValidWarrantyAssets({int page = 1, int pageSize = 20}) async {
    final data = await remoteDataSource.getValidWarrantyAssets(page: page, pageSize: pageSize);
    return data.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getExpiringWarrantyAssets({int page = 1, int pageSize = 20}) async {
    final data = await remoteDataSource.getExpiringWarrantyAssets(page: page, pageSize: pageSize);
    return data.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getAssetsWithoutWarranty({int page = 1, int pageSize = 20}) async {
    final data = await remoteDataSource.getAssetsWithoutWarranty(page: page, pageSize: pageSize);
    return data.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  // ─── Insurance ──────────────────────────────────────────────
  @override
  Future<InsuranceSummary> getInsuranceSummary() async {
    final json = await remoteDataSource.getInsuranceSummary();
    return InsuranceSummaryModel.fromJson(json);
  }

  @override
  Future<List<CoverageAsset>> getExpiredInsuranceAssets({int page = 1, int pageSize = 20}) async {
    final data = await remoteDataSource.getExpiredInsuranceAssets(page: page, pageSize: pageSize);
    return data.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getValidInsuranceAssets({int page = 1, int pageSize = 20}) async {
    final data = await remoteDataSource.getValidInsuranceAssets(page: page, pageSize: pageSize);
    return data.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getExpiringInsuranceAssets({int page = 1, int pageSize = 20}) async {
    final data = await remoteDataSource.getExpiringInsuranceAssets(page: page, pageSize: pageSize);
    return data.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }

  @override
  Future<List<CoverageAsset>> getAssetsWithoutInsurance({int page = 1, int pageSize = 20}) async {
    final data = await remoteDataSource.getAssetsWithoutInsurance(page: page, pageSize: pageSize);
    return data.map((json) => CoverageAssetModel.fromJson(json)).toList();
  }
}
