import '../../../../core/network/api_client.dart';

abstract class DashboardRemoteDataSource {
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<Map<String, dynamic>>> getParentSpaces();
  Future<List<Map<String, dynamic>>> getChildrenSpaces(String parentId);
  Future<List<Map<String, dynamic>>> getNotifications();
  Future<void> deleteNotification(String notificationId);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient apiClient;

  DashboardRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await apiClient.dio.get('/Dashboard/assets-summary');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getParentSpaces() async {
    final response = await apiClient.dio.get('/Spaces/parents');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getChildrenSpaces(String parentId) async {
    final response = await apiClient.dio.get('/Spaces/children/$parentId');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await apiClient.dio.get('/Notifications');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await apiClient.dio.delete('/Notifications/$notificationId');
  }
}
