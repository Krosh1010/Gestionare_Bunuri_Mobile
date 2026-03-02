import '../../domain/entities/profile_user.dart';

class ProfileUserModel extends ProfileUser {
  const ProfileUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.role,
    super.avatarUrl,
  });

  factory ProfileUserModel.fromJson(Map<String, dynamic> json) {
    return ProfileUserModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
    };
  }
}

