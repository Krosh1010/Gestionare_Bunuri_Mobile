import 'package:equatable/equatable.dart';

class ProfileUser extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? role;
  final String? avatarUrl;

  const ProfileUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.role,
    this.avatarUrl,
  });

  ProfileUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? avatarUrl,
  }) {
    return ProfileUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, role, avatarUrl];
}

