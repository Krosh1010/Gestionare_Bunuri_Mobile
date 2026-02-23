import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register(String fullName, String email, String password);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiClient.dio.post(
      '/Auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    // Presupunem că răspunsul conține tokenul JWT sub cheia 'token'
    final token = response.data['token'] as String?;
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
    }
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    // Implementare similară pentru register dacă e nevoie
    return {};
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
