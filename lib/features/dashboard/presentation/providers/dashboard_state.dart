import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../widgets/locations_card.dart';
import '../widgets/notifications_card.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final List<LocationNode> locationTree;
  final bool locationsLoading;
  final List<NotificationData> notifications;

  const DashboardLoaded({
    required this.stats,
    this.locationTree = const [],
    this.locationsLoading = false,
    this.notifications = const [],
  });

  DashboardLoaded copyWith({
    DashboardStats? stats,
    List<LocationNode>? locationTree,
    bool? locationsLoading,
    List<NotificationData>? notifications,
  }) {
    return DashboardLoaded(
      stats: stats ?? this.stats,
      locationTree: locationTree ?? this.locationTree,
      locationsLoading: locationsLoading ?? this.locationsLoading,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [stats, locationTree, locationsLoading, notifications];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
