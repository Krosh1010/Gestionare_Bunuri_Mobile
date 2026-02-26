import '../entities/warranty_summary.dart';
import '../entities/insurance_summary.dart';
import '../entities/coverage_asset.dart';

abstract class CoverageRepository {
  // Warranty
  Future<WarrantySummary> getWarrantySummary();
  Future<List<CoverageAsset>> getExpiredWarrantyAssets({int page = 1, int pageSize = 20});
  Future<List<CoverageAsset>> getValidWarrantyAssets({int page = 1, int pageSize = 20});
  Future<List<CoverageAsset>> getExpiringWarrantyAssets({int page = 1, int pageSize = 20});
  Future<List<CoverageAsset>> getAssetsWithoutWarranty({int page = 1, int pageSize = 20});

  // Insurance
  Future<InsuranceSummary> getInsuranceSummary();
  Future<List<CoverageAsset>> getExpiredInsuranceAssets({int page = 1, int pageSize = 20});
  Future<List<CoverageAsset>> getValidInsuranceAssets({int page = 1, int pageSize = 20});
  Future<List<CoverageAsset>> getExpiringInsuranceAssets({int page = 1, int pageSize = 20});
  Future<List<CoverageAsset>> getAssetsWithoutInsurance({int page = 1, int pageSize = 20});
}
