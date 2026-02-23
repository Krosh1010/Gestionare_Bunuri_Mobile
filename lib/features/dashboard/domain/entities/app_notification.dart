import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final int type; // 0 = warranty, 1 = insurance
  final String message;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
  });

  @override
  List<Object?> get props => [id, type, message, isRead];
}

