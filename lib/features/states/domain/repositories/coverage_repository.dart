import '../entities/warranty_summary.dart';
import '../entities/insurance_summary.dart';
import '../entities/coverage_asset.dart';

abstract class CoverageRepository {
  // Warranty
  Future<WarrantySummary> getWarrantySummary();
  Future<List<CoverageAsset>> getExpiredWarrantyAssets();
  Future<List<CoverageAsset>> getValidWarrantyAssets();
  Future<List<CoverageAsset>> getExpiringWarrantyAssets();
  Future<List<CoverageAsset>> getAssetsWithoutWarranty();

  // Insurance
  Future<InsuranceSummary> getInsuranceSummary();
  Future<List<CoverageAsset>> getExpiredInsuranceAssets();
  Future<List<CoverageAsset>> getValidInsuranceAssets();
  Future<List<CoverageAsset>> getExpiringInsuranceAssets();
  Future<List<CoverageAsset>> getAssetsWithoutInsurance();
}
