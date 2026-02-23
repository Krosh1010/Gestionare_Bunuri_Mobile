import '../entities/app_notification.dart';
import '../repositories/dashboard_repository.dart';

class GetNotificationsUseCase {
  final DashboardRepository repository;

  GetNotificationsUseCase({required this.repository});

  Future<List<AppNotification>> call() async {
    return await repository.getNotifications();
  }
}

