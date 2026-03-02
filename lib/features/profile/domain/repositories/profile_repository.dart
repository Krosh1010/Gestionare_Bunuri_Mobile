import '../entities/profile_user.dart';

abstract class ProfileRepository {
  Future<ProfileUser> getProfile();
  Future<ProfileUser> updateData({required String fullName, required String email});
  Future<void> changePassword({required String currentPassword, required String newPassword});
}

