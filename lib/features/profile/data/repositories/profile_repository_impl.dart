import '../../domain/entities/profile_user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasource/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ProfileUser> getProfile() async {
    return await remoteDataSource.getProfile();
  }

  @override
  Future<ProfileUser> updateData({required String fullName, required String email}) async {
    return await remoteDataSource.updateData(fullName: fullName, email: email);
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

