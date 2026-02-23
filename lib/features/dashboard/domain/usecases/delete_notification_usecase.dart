import '../repositories/dashboard_repository.dart';

class DeleteNotificationUseCase {
  final DashboardRepository repository;

  DeleteNotificationUseCase({required this.repository});

  Future<void> call(String notificationId) async {
    await repository.deleteNotification(notificationId);
  }
}

