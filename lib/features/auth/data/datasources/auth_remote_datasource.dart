import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register(String fullName, String email, String password);
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String token, String newPassword);
  Future<Map<String, dynamic>> verifyEmail(String email, String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/Auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      final token = response.data['token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('403');
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/Auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('409');
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  @override
  Future<void> forgotPassword(String email) async {
    await apiClient.dio.post(
      '/Auth/forgot-password',
      data: {'email': email},
    );
  }

  @override
  Future<void> resetPassword(String email, String token, String newPassword) async {
    try {
      await apiClient.dio.post(
        '/Auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data is Map
            ? (e.response!.data['message'] ??
                e.response!.data['title'] ??
                'Codul de resetare este invalid sau a expirat.')
            : 'Codul de resetare este invalid sau a expirat.';
        throw Exception(message);
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> verifyEmail(String email, String token) async {
    try {
      final response = await apiClient.dio.post(
        '/Auth/verify-email',
        data: {
          'email': email,
          'token': token,
        },
      );
      final jwt = response.data['token'] as String?;
      if (jwt != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', jwt);
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data is Map
            ? (e.response!.data['message'] ??
                e.response!.data['title'] ??
                'Codul de verificare este invalid sau a expirat.')
            : 'Codul de verificare este invalid sau a expirat.';
        throw Exception(message);
      }
      rethrow;
    }
  }
}
