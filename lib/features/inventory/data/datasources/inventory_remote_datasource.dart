import '../../../../core/network/api_client.dart';
import '../models/asset_model.dart';

abstract class InventoryRemoteDataSource {
  Future<List<AssetModel>> getMyAssets({int page, int pageSize});
  Future<AssetModel> getAssetById(String id);
  Future<AssetModel> addAsset(Map<String, dynamic> data);
  Future<AssetModel> updateAsset(String id, Map<String, dynamic> data);
  Future<void> deleteAsset(String id);
  Future<void> addWarranty(Map<String, dynamic> data);
  Future<void> addInsurance(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getSpacePath(int spaceId);
  Future<Map<String, dynamic>?> getWarrantyByAsset(int assetId);
  Future<void> updateWarrantyByAsset(int assetId, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getInsuranceByAsset(int assetId);
  Future<void> updateInsuranceByAsset(int assetId, Map<String, dynamic> data);
  Future<void> deleteWarrantyByAsset(int assetId);
  Future<void> deleteInsuranceByAsset(int assetId);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final ApiClient apiClient;

  InventoryRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AssetModel>> getMyAssets({int page = 1, int pageSize = 1}) async {
    final response = await apiClient.dio.get(
      '/Assets/my/paged',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final list = response.data['items'] as List;
    return list
        .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AssetModel> getAssetById(String id) async {
    final response = await apiClient.dio.get('/Assets/$id');
    return AssetModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AssetModel> addAsset(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/Assets', data: data);
    return AssetModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AssetModel> updateAsset(String id, Map<String, dynamic> data) async {
    final response = await apiClient.dio.patch('/Assets/$id', data: data);
    return AssetModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAsset(String id) async {
    await apiClient.dio.delete('/Assets/$id');
  }

  @override
  Future<void> addWarranty(Map<String, dynamic> data) async {
    await apiClient.dio.post('/Warranty/create', data: data);
  }

  @override
  Future<void> addInsurance(Map<String, dynamic> data) async {
    await apiClient.dio.post('/Insurance/create', data: data);
  }

  @override
  Future<List<Map<String, dynamic>>> getSpacePath(int spaceId) async {
    final response = await apiClient.dio.get('/Spaces/path/$spaceId');
    final list = response.data as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<Map<String, dynamic>?> getWarrantyByAsset(int assetId) async {
    try {
      final response = await apiClient.dio.get('/Warranty/by-asset/$assetId');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateWarrantyByAsset(int assetId, Map<String, dynamic> data) async {
    await apiClient.dio.patch('/Warranty/by-asset/$assetId', data: data);
  }

  @override
  Future<Map<String, dynamic>?> getInsuranceByAsset(int assetId) async {
    try {
      final response = await apiClient.dio.get('/Insurance/by-asset/$assetId');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateInsuranceByAsset(int assetId, Map<String, dynamic> data) async {
    await apiClient.dio.patch('/Insurance/by-asset/$assetId', data: data);
  }

  @override
  Future<void> deleteWarrantyByAsset(int assetId) async {
    await apiClient.dio.delete('/Warranty/by-asset/$assetId');
  }

  @override
  Future<void> deleteInsuranceByAsset(int assetId) async {
    await apiClient.dio.delete('/Insurance/by-asset/$assetId');
  }
}
