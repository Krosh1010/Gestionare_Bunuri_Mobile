import '../entities/asset.dart';

abstract class InventoryRepository {
  Future<List<Asset>> getAssets();
  Future<Asset> getAssetById(String id);
  Future<Asset> addAsset(Asset asset);
  Future<Asset> updateAsset(Asset asset);
  Future<void> deleteAsset(String id);
  Future<List<Asset>> searchAssets(String query);
  Future<List<Asset>> filterByCategory(AssetCategory category);
  Future<List<Asset>> filterByStatus(AssetStatus status);
}

