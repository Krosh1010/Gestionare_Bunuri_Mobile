import 'dart:io';
import 'dart:typed_data';
import '../entities/asset.dart';
import '../entities/paged_assets_result.dart';

abstract class InventoryRepository {
  Future<PagedAssetsResult> getAssets({
    int page = 1,
    int pageSize = 10,
    String? name,
    String? category,
    double? minValue,
    double? maxValue,
    int? spaceId,
  });
  Future<Asset> getAssetById(String id);
  Future<Asset> addAsset(Map<String, dynamic> data);
  Future<Asset> updateAsset(String id, Map<String, dynamic> data);
  Future<void> deleteAsset(String id);
  Future<void> addWarranty(Map<String, dynamic> data, {File? document});
  Future<void> addInsurance(Map<String, dynamic> data, {File? document});
  Future<List<Map<String, dynamic>>> getSpacePath(int spaceId);
  Future<Map<String, dynamic>?> getWarrantyByAsset(int assetId);
  Future<void> updateWarrantyByAsset(int assetId, Map<String, dynamic> data, {File? document});
  Future<Map<String, dynamic>?> getInsuranceByAsset(int assetId);
  Future<void> updateInsuranceByAsset(int assetId, Map<String, dynamic> data, {File? document});
  Future<void> deleteWarrantyByAsset(int assetId);
  Future<void> deleteInsuranceByAsset(int assetId);
  Future<Uint8List> downloadWarrantyDocument(int assetId);
  Future<void> deleteWarrantyDocument(int assetId);
  Future<Uint8List> downloadInsuranceDocument(int assetId);
  Future<void> deleteInsuranceDocument(int assetId);
  Future<void> createCustomTracker(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getCustomTrackerByAsset(int assetId);
  Future<void> updateCustomTracker(int trackerId, Map<String, dynamic> data);
  Future<void> deleteCustomTracker(int trackerId);
}
