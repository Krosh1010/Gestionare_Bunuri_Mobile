import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/space.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/dashboard_stats_model.dart';
import '../models/space_model.dart';
import '../models/app_notification_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DashboardStats> getDashboardStats() async {
    final json = await remoteDataSource.getDashboardStats();
    return DashboardStatsModel.fromJson(json);
  }

  @override
  Future<List<Space>> getParentSpaces() async {
    final jsonList = await remoteDataSource.getParentSpaces();
    return jsonList.map((json) => SpaceModel.fromJson(json)).toList();
  }

  @override
  Future<List<Space>> getChildrenSpaces(String parentId) async {
    final jsonList = await remoteDataSource.getChildrenSpaces(parentId);
    return jsonList.map((json) => SpaceModel.fromJson(json)).toList();
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    final jsonList = await remoteDataSource.getNotifications();
    return jsonList.map((json) => AppNotificationModel.fromJson(json)).toList();
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await remoteDataSource.deleteNotification(notificationId);
  }
}
