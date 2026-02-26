import '../../domain/entities/asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Asset>> getAssets({int page = 1, int pageSize = 1}) async {
    return await remoteDataSource.getMyAssets(page: page, pageSize: pageSize);
  }

  @override
  Future<Asset> getAssetById(String id) async {
    return await remoteDataSource.getAssetById(id);
  }

  @override
  Future<Asset> addAsset(Map<String, dynamic> data) async {
    return await remoteDataSource.addAsset(data);
  }

  @override
  Future<Asset> updateAsset(String id, Map<String, dynamic> data) async {
    return await remoteDataSource.updateAsset(id, data);
  }

  @override
  Future<void> deleteAsset(String id) async {
    await remoteDataSource.deleteAsset(id);
  }

  @override
  Future<void> addWarranty(Map<String, dynamic> data) async {
    await remoteDataSource.addWarranty(data);
  }

  @override
  Future<void> addInsurance(Map<String, dynamic> data) async {
    await remoteDataSource.addInsurance(data);
  }

  @override
  Future<List<Map<String, dynamic>>> getSpacePath(int spaceId) async {
    return await remoteDataSource.getSpacePath(spaceId);
  }

  @override
  Future<Map<String, dynamic>?> getWarrantyByAsset(int assetId) async {
    return await remoteDataSource.getWarrantyByAsset(assetId);
  }

  @override
  Future<void> updateWarrantyByAsset(int assetId, Map<String, dynamic> data) async {
    await remoteDataSource.updateWarrantyByAsset(assetId, data);
  }

  @override
  Future<Map<String, dynamic>?> getInsuranceByAsset(int assetId) async {
    return await remoteDataSource.getInsuranceByAsset(assetId);
  }

  @override
  Future<void> updateInsuranceByAsset(int assetId, Map<String, dynamic> data) async {
    await remoteDataSource.updateInsuranceByAsset(assetId, data);
  }

  @override
  Future<void> deleteWarrantyByAsset(int assetId) async {
    await remoteDataSource.deleteWarrantyByAsset(assetId);
  }

  @override
  Future<void> deleteInsuranceByAsset(int assetId) async {
    await remoteDataSource.deleteInsuranceByAsset(assetId);
  }
}
