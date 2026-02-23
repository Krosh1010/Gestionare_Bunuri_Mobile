import '../entities/dashboard_stats.dart';
import '../entities/space.dart';
import '../entities/app_notification.dart';

abstract class DashboardRepository {
  Future<DashboardStats> getDashboardStats();
  Future<List<Space>> getParentSpaces();
  Future<List<Space>> getChildrenSpaces(String parentId);
  Future<List<AppNotification>> getNotifications();
  Future<void> deleteNotification(String notificationId);
}
