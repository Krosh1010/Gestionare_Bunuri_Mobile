abstract class InventoryRemoteDataSource {
  Future<List<Map<String, dynamic>>> getAssets();
  Future<Map<String, dynamic>> getAssetById(String id);
  Future<Map<String, dynamic>> addAsset(Map<String, dynamic> asset);
  Future<Map<String, dynamic>> updateAsset(String id, Map<String, dynamic> asset);
  Future<void> deleteAsset(String id);
}

