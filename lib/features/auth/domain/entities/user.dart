import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? role;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.role,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, fullName, email, role, avatarUrl];
}

