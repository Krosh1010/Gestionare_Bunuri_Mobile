import '../../../../core/network/api_client.dart';
import '../models/profile_user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileUserModel> getProfile();
  Future<ProfileUserModel> updateData({required String fullName, required String email});
  Future<void> changePassword({required String currentPassword, required String newPassword});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSourceImpl(this.apiClient);

  @override
  Future<ProfileUserModel> getProfile() async {
    final response = await apiClient.dio.get('/User/me');
    return ProfileUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProfileUserModel> updateData({required String fullName, required String email}) async {
    final response = await apiClient.dio.patch(
      '/User/update-data',
      data: {
        'fullName': fullName,
        'email': email,
      },
    );
    return ProfileUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await apiClient.dio.patch(
      '/User/Change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}

