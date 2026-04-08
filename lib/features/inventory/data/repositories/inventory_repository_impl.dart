import 'dart:io';
import 'dart:typed_data';
import '../../domain/entities/asset.dart';
import '../../domain/entities/paged_assets_result.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PagedAssetsResult> getAssets({
    int page = 1,
    int pageSize = 10,
    String? name,
    String? category,
    double? minValue,
    double? maxValue,
    int? spaceId,
  }) async {
    return await remoteDataSource.getMyAssets(
      page: page,
      pageSize: pageSize,
      name: name,
      category: category,
      minValue: minValue,
      maxValue: maxValue,
      spaceId: spaceId,
    );
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
  Future<void> addWarranty(Map<String, dynamic> data, {File? document}) async {
    await remoteDataSource.addWarranty(data, document: document);
  }

  @override
  Future<void> addInsurance(Map<String, dynamic> data, {File? document}) async {
    await remoteDataSource.addInsurance(data, document: document);
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
  Future<void> updateWarrantyByAsset(int assetId, Map<String, dynamic> data, {File? document}) async {
    await remoteDataSource.updateWarrantyByAsset(assetId, data, document: document);
  }

  @override
  Future<Map<String, dynamic>?> getInsuranceByAsset(int assetId) async {
    return await remoteDataSource.getInsuranceByAsset(assetId);
  }

  @override
  Future<void> updateInsuranceByAsset(int assetId, Map<String, dynamic> data, {File? document}) async {
    await remoteDataSource.updateInsuranceByAsset(assetId, data, document: document);
  }

  @override
  Future<void> deleteWarrantyByAsset(int assetId) async {
    await remoteDataSource.deleteWarrantyByAsset(assetId);
  }

  @override
  Future<void> deleteInsuranceByAsset(int assetId) async {
    await remoteDataSource.deleteInsuranceByAsset(assetId);
  }

  @override
  Future<Uint8List> downloadWarrantyDocument(int assetId) async {
    return await remoteDataSource.downloadWarrantyDocument(assetId);
  }

  @override
  Future<void> deleteWarrantyDocument(int assetId) async {
    await remoteDataSource.deleteWarrantyDocument(assetId);
  }

  @override
  Future<Uint8List> downloadInsuranceDocument(int assetId) async {
    return await remoteDataSource.downloadInsuranceDocument(assetId);
  }

  @override
  Future<void> deleteInsuranceDocument(int assetId) async {
    await remoteDataSource.deleteInsuranceDocument(assetId);
  }

  @override
  Future<void> createCustomTracker(Map<String, dynamic> data) async {
    await remoteDataSource.createCustomTracker(data);
  }

  @override
  Future<Map<String, dynamic>?> getCustomTrackerByAsset(int assetId) async {
    return await remoteDataSource.getCustomTrackerByAsset(assetId);
  }

  @override
  Future<void> updateCustomTracker(int trackerId, Map<String, dynamic> data) async {
    await remoteDataSource.updateCustomTracker(trackerId, data);
  }

  @override
  Future<void> deleteCustomTracker(int trackerId) async {
    await remoteDataSource.deleteCustomTracker(trackerId);
  }

  // ── Loan ──────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>?> getActiveLoanByAsset(int assetId) async {
    return await remoteDataSource.getActiveLoanByAsset(assetId);
  }

  @override
  Future<List<Map<String, dynamic>>> getLoanHistory(int assetId) async {
    return await remoteDataSource.getLoanHistory(assetId);
  }

  @override
  Future<void> createLoan(Map<String, dynamic> data) async {
    await remoteDataSource.createLoan(data);
  }

  @override
  Future<void> updateLoan(int loanId, Map<String, dynamic> data) async {
    await remoteDataSource.updateLoan(loanId, data);
  }

  @override
  Future<void> returnLoan(int loanId, Map<String, dynamic> data) async {
    await remoteDataSource.returnLoan(loanId, data);
  }

  @override
  Future<void> deleteLoan(int loanId) async {
    await remoteDataSource.deleteLoan(loanId);
  }
}
