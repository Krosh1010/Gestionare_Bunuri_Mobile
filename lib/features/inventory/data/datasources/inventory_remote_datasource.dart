import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/inventory/domain/entities/paged_assets_result.dart';
import '../models/asset_model.dart';

abstract class InventoryRemoteDataSource {
  Future<PagedAssetsResult> getMyAssets({
    int page,
    int pageSize,
    String? name,
    String? category,
    double? minValue,
    double? maxValue,
    int? spaceId,
  });
  Future<AssetModel> getAssetById(String id);
  Future<AssetModel> getAssetByBarcode(String barcode);
  Future<AssetModel> addAsset(Map<String, dynamic> data);
  Future<AssetModel> updateAsset(String id, Map<String, dynamic> data);
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

  // Loan
  Future<Map<String, dynamic>?> getActiveLoanByAsset(int assetId);
  Future<List<Map<String, dynamic>>> getLoanHistory(int assetId);
  Future<void> createLoan(Map<String, dynamic> data);
  Future<void> updateLoan(int loanId, Map<String, dynamic> data);
  Future<void> returnLoan(int loanId, Map<String, dynamic> data);
  Future<void> deleteLoan(int loanId);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final ApiClient apiClient;

  InventoryRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PagedAssetsResult> getMyAssets({
    int page = 1,
    int pageSize = 10,
    String? name,
    String? category,
    double? minValue,
    double? maxValue,
    int? spaceId,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (name != null && name.isNotEmpty) params['name'] = name;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (minValue != null) params['minValue'] = minValue;
    if (maxValue != null) params['maxValue'] = maxValue;
    if (spaceId != null) params['spaceId'] = spaceId;

    final response = await apiClient.dio.get(
      '/Assets/my/paged',
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['items'] as List;
    final items = list
        .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return PagedAssetsResult(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
      totalValue: (data['totalValue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<AssetModel> getAssetById(String id) async {
    final response = await apiClient.dio.get('/Assets/$id');
    return AssetModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AssetModel> getAssetByBarcode(String barcode) async {
    final response = await apiClient.dio.get('/Assets/barcode/$barcode');
    return AssetModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AssetModel> addAsset(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/Assets', data: data);
    return AssetModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AssetModel> updateAsset(String id, Map<String, dynamic> data) async {
    await apiClient.dio.patch(
      '/Assets/$id',
      data: jsonEncode(data),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    // PATCH returns a plain string, not JSON — fetch the updated asset separately
    final response = await apiClient.dio.get('/Assets/$id');
    return AssetModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAsset(String id) async {
    await apiClient.dio.delete('/Assets/$id');
  }

  @override
  Future<void> addWarranty(Map<String, dynamic> data, {File? document}) async {
    final formData = FormData.fromMap({
      'AssetId': data['assetId'],
      'Provider': data['provider'],
      'StartDate': data['startDate'],
      'EndDate': data['endDate'],
      if (document != null)
        'document': await MultipartFile.fromFile(
          document.path,
          filename: document.path.split(Platform.pathSeparator).last,
        ),
    });
    await apiClient.dio.post('/Warranty/create', data: formData);
  }

  @override
  Future<void> addInsurance(Map<String, dynamic> data, {File? document}) async {
    final formData = FormData.fromMap({
      'AssetId': data['assetId'],
      'Company': data['company'],
      'InsuredValue': data['insuredValue'],
      'StartDate': data['startDate'],
      'EndDate': data['endDate'],
      if (document != null)
        'document': await MultipartFile.fromFile(
          document.path,
          filename: document.path.split(Platform.pathSeparator).last,
        ),
    });
    await apiClient.dio.post('/Insurance/create', data: formData);
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
  Future<void> updateWarrantyByAsset(int assetId, Map<String, dynamic> data, {File? document}) async {
    final formMap = <String, dynamic>{};
    if (data.containsKey('provider')) formMap['Provider'] = data['provider'];
    if (data.containsKey('startDate')) formMap['StartDate'] = data['startDate'];
    if (data.containsKey('endDate')) formMap['EndDate'] = data['endDate'];
    if (document != null) {
      formMap['document'] = await MultipartFile.fromFile(
        document.path,
        filename: document.path.split(Platform.pathSeparator).last,
      );
    }
    final formData = FormData.fromMap(formMap);
    await apiClient.dio.patch('/Warranty/by-asset/$assetId', data: formData);
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
  Future<void> updateInsuranceByAsset(int assetId, Map<String, dynamic> data, {File? document}) async {
    final formMap = <String, dynamic>{};
    if (data.containsKey('company')) formMap['Company'] = data['company'];
    if (data.containsKey('insuredValue')) formMap['InsuredValue'] = data['insuredValue'];
    if (data.containsKey('startDate')) formMap['StartDate'] = data['startDate'];
    if (data.containsKey('endDate')) formMap['EndDate'] = data['endDate'];
    if (document != null) {
      formMap['document'] = await MultipartFile.fromFile(
        document.path,
        filename: document.path.split(Platform.pathSeparator).last,
      );
    }
    final formData = FormData.fromMap(formMap);
    await apiClient.dio.patch('/Insurance/by-asset/$assetId', data: formData);
  }

  @override
  Future<void> deleteWarrantyByAsset(int assetId) async {
    await apiClient.dio.delete('/Warranty/by-asset/$assetId');
  }

  @override
  Future<void> deleteInsuranceByAsset(int assetId) async {
    await apiClient.dio.delete('/Insurance/by-asset/$assetId');
  }

  @override
  Future<Uint8List> downloadWarrantyDocument(int assetId) async {
    final response = await apiClient.dio.get(
      '/Warranty/by-asset/$assetId/document/download',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  @override
  Future<void> deleteWarrantyDocument(int assetId) async {
    await apiClient.dio.delete('/Warranty/by-asset/$assetId/document');
  }

  @override
  Future<Uint8List> downloadInsuranceDocument(int assetId) async {
    final response = await apiClient.dio.get(
      '/Insurance/by-asset/$assetId/document/download',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  @override
  Future<void> deleteInsuranceDocument(int assetId) async {
    await apiClient.dio.delete('/Insurance/by-asset/$assetId/document');
  }

  @override
  Future<void> createCustomTracker(Map<String, dynamic> data) async {
    await apiClient.dio.post('/CustomTracker/create', data: {
      'assetId': data['assetId'],
      'name': data['name'],
      'description': data['description'],
      'startDate': data['startDate'],
      'endDate': data['endDate'],
    });
  }

  @override
  Future<Map<String, dynamic>?> getCustomTrackerByAsset(int assetId) async {
    try {
      final response = await apiClient.dio.get('/CustomTracker/by-asset/$assetId');
      if (response.data == null) return null;

      // API might return a single object or a list
      if (response.data is List) {
        final list = response.data as List;
        if (list.isEmpty) return null;
        return Map<String, dynamic>.from(list.first as Map);
      }

      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      print('Error loading custom tracker for asset $assetId: $e');
      return null;
    }
  }

  @override
  Future<void> updateCustomTracker(int trackerId, Map<String, dynamic> data) async {
    await apiClient.dio.patch('/CustomTracker/$trackerId', data: {
      if (data.containsKey('name')) 'name': data['name'],
      if (data.containsKey('description')) 'description': data['description'],
      if (data.containsKey('startDate')) 'startDate': data['startDate'],
      if (data.containsKey('endDate')) 'endDate': data['endDate'],
    });
  }

  @override
  Future<void> deleteCustomTracker(int trackerId) async {
    await apiClient.dio.delete('/CustomTracker/$trackerId');
  }

  @override
  Future<Map<String, dynamic>?> getActiveLoanByAsset(int assetId) async {
    try {
      final response = await apiClient.dio.get('/loan/active/by-asset/$assetId');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLoanHistory(int assetId) async {
    final response = await apiClient.dio.get('/loan/history/by-asset/$assetId');
    final list = response.data as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<void> createLoan(Map<String, dynamic> data) async {
    await apiClient.dio.post('/loan/create', data: data);
  }

  @override
  Future<void> updateLoan(int loanId, Map<String, dynamic> data) async {
    await apiClient.dio.patch('/loan/$loanId', data: data);
  }

  @override
  Future<void> returnLoan(int loanId, Map<String, dynamic> data) async {
    await apiClient.dio.patch('/loan/$loanId/return', data: data);
  }

  @override
  Future<void> deleteLoan(int loanId) async {
    await apiClient.dio.delete('/loan/$loanId');
  }
}
