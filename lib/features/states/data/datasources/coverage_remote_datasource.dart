import '../../../../core/network/api_client.dart';

abstract class CoverageRemoteDataSource {
  // Warranty
  Future<Map<String, dynamic>> getWarrantySummary();
  Future<List<Map<String, dynamic>>> getExpiredWarrantyAssets({int page = 1, int pageSize = 20});
  Future<List<Map<String, dynamic>>> getValidWarrantyAssets({int page = 1, int pageSize = 20});
  Future<List<Map<String, dynamic>>> getExpiringWarrantyAssets({int page = 1, int pageSize = 20});
  Future<List<Map<String, dynamic>>> getAssetsWithoutWarranty({int page = 1, int pageSize = 20});

  // Insurance
  Future<Map<String, dynamic>> getInsuranceSummary();
  Future<List<Map<String, dynamic>>> getExpiredInsuranceAssets({int page = 1, int pageSize = 20});
  Future<List<Map<String, dynamic>>> getValidInsuranceAssets({int page = 1, int pageSize = 20});
  Future<List<Map<String, dynamic>>> getExpiringInsuranceAssets({int page = 1, int pageSize = 20});
  Future<List<Map<String, dynamic>>> getAssetsWithoutInsurance({int page = 1, int pageSize = 20});
}

class CoverageRemoteDataSourceImpl implements CoverageRemoteDataSource {
  final ApiClient apiClient;

  CoverageRemoteDataSourceImpl({required this.apiClient});

  // ─── Warranty ───────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getWarrantySummary() async {
    final response = await apiClient.dio.get('/coverage-status/warranty/summary');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getExpiredWarrantyAssets({int page = 1, int pageSize = 20}) async {
    final response = await apiClient.dio.get(
      '/coverage-status/warranty/expired-assets',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['items'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getValidWarrantyAssets({int page = 1, int pageSize = 20}) async {
    final response = await apiClient.dio.get(
      '/coverage-status/warranty/valid-assets',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['items'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getExpiringWarrantyAssets({int page = 1, int pageSize = 20}) async {
    final response = await apiClient.dio.get(
      '/coverage-status/warranty/expiring-assets',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['items'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getAssetsWithoutWarranty({int page = 1, int pageSize = 20}) async {
    final response = await apiClient.dio.get(
      '/coverage-status/warranty/assets-without-warranty',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['items'] as List).cast<Map<String, dynamic>>();
  }

  // ─── Insurance ──────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getInsuranceSummary() async {
    final response = await apiClient.dio.get('/coverage-status/insurance/summary');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getExpiredInsuranceAssets({int page = 1, int pageSize = 20}) async {
    final response = await apiClient.dio.get(
      '/coverage-status/insurance/expired-assets',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['items'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getValidInsuranceAssets({int page = 1, int pageSize = 20}) async {
    final response = await apiClient.dio.get(
      '/coverage-status/insurance/valid-assets',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['items'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getExpiringInsuranceAssets({int page = 1, int pageSize = 20}) async {
    final response = await apiClient.dio.get(
      '/coverage-status/insurance/expiring-assets',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['items'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getAssetsWithoutInsurance({int page = 1, int pageSize = 20}) async {
    final response = await apiClient.dio.get(
      '/coverage-status/insurance/assets-without-insurance',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['items'] as List).cast<Map<String, dynamic>>();
  }
}
