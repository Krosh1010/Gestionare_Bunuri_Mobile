import '../../../../core/network/api_client.dart';

abstract class CoverageRemoteDataSource {
  // Warranty
  Future<Map<String, dynamic>> getWarrantySummary();
  Future<List<Map<String, dynamic>>> getExpiredWarrantyAssets();
  Future<List<Map<String, dynamic>>> getValidWarrantyAssets();
  Future<List<Map<String, dynamic>>> getExpiringWarrantyAssets();
  Future<List<Map<String, dynamic>>> getAssetsWithoutWarranty();

  // Insurance
  Future<Map<String, dynamic>> getInsuranceSummary();
  Future<List<Map<String, dynamic>>> getExpiredInsuranceAssets();
  Future<List<Map<String, dynamic>>> getValidInsuranceAssets();
  Future<List<Map<String, dynamic>>> getExpiringInsuranceAssets();
  Future<List<Map<String, dynamic>>> getAssetsWithoutInsurance();
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
  Future<List<Map<String, dynamic>>> getExpiredWarrantyAssets() async {
    final response = await apiClient.dio.get('/coverage-status/warranty/expired-assets');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getValidWarrantyAssets() async {
    final response = await apiClient.dio.get('/coverage-status/warranty/valid-assets');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getExpiringWarrantyAssets() async {
    final response = await apiClient.dio.get('/coverage-status/warranty/expiring-assets');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getAssetsWithoutWarranty() async {
    final response = await apiClient.dio.get('/coverage-status/warranty/assets-without-warranty');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // ─── Insurance ──────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getInsuranceSummary() async {
    final response = await apiClient.dio.get('/coverage-status/insurance/summary');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getExpiredInsuranceAssets() async {
    final response = await apiClient.dio.get('/coverage-status/insurance/expired-assets');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getValidInsuranceAssets() async {
    final response = await apiClient.dio.get('/coverage-status/insurance/valid-assets');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getExpiringInsuranceAssets() async {
    final response = await apiClient.dio.get('/coverage-status/insurance/expiring-assets');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getAssetsWithoutInsurance() async {
    final response = await apiClient.dio.get('/coverage-status/insurance/assets-without-insurance');
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}
