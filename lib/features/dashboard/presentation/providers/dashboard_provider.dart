import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';
import '../../domain/usecases/get_parent_spaces_usecase.dart';
import '../../domain/usecases/get_children_spaces_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../../../core/services/notification_service.dart';
import '../widgets/locations_card.dart';
import '../widgets/notifications_card.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardStatsUseCase getDashboardStats;
  final GetParentSpacesUseCase getParentSpaces;
  final GetChildrenSpacesUseCase getChildrenSpaces;
  final GetNotificationsUseCase getNotifications;
  final DeleteNotificationUseCase deleteNotificationUseCase;

  DashboardCubit({
    required this.getDashboardStats,
    required this.getParentSpaces,
    required this.getChildrenSpaces,
    required this.getNotifications,
    required this.deleteNotificationUseCase,
  }) : super(DashboardInitial());

  Future<void> loadDashboardStats() async {
    emit(DashboardLoading());
    try {
      print('📊 [Dashboard] Loading stats from API...');
      final stats = await getDashboardStats();
      print('📊 [Dashboard] Stats loaded: totalCount=${stats.totalCount}');

      // Load parent spaces
      List<LocationNode> locationTree = [];
      try {
        final parents = await getParentSpaces();
        print('📍 [Dashboard] Spaces loaded: ${parents.length} parents');
        locationTree = parents
            .map((s) => LocationNode(
                  id: s.id,
                  name: s.name,
                  type: s.type,
                  childrenLoaded: s.childrenCount == 0,
                ))
            .toList();
      } catch (e) {
        print('⚠️ [Dashboard] Error loading spaces: $e');
      }

      // Load notifications
      List<NotificationData> notifications = [];
      try {
        final notifs = await getNotifications();
        print('🔔 [Dashboard] Notifications loaded: ${notifs.length}');
        notifications = notifs
            .map((n) => NotificationData(
                  id: n.id,
                  type: n.type,
                  message: n.message,
                ))
            .toList();
      } catch (e) {
        print('⚠️ [Dashboard] Error loading notifications: $e');
      }

      // Pornește verificarea periodică a notificărilor push
      try {
        NotificationService.startPeriodicCheck();
      } catch (e) {
        print('⚠️ [Dashboard] Error starting notification check: $e');
      }

      emit(DashboardLoaded(
        stats: stats,
        locationTree: locationTree,
        notifications: notifications,
      ));
    } catch (e) {
      print('❌ [Dashboard] FATAL error: $e');
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> loadChildren(LocationNode node) async {
    try {
      final children = await getChildrenSpaces(node.id);
      node.children = children
          .map((s) => LocationNode(
                id: s.id,
                name: s.name,
                type: s.type,
                childrenLoaded: s.childrenCount == 0,
              ))
          .toList();
    } catch (e) {
      node.children = [];
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    try {
      await deleteNotificationUseCase(notificationId);
      final updatedNotifications = currentState.notifications
          .where((n) => n.id != notificationId)
          .toList();
      emit(currentState.copyWith(notifications: updatedNotifications));
    } catch (_) {
      // Ștergerea a eșuat — nu modificăm UI
    }
  }
}
