import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import '../../features/dashboard/domain/usecases/get_parent_spaces_usecase.dart';
import '../../features/dashboard/domain/usecases/get_children_spaces_usecase.dart';
import '../../features/dashboard/domain/usecases/get_notifications_usecase.dart';
import '../../features/dashboard/domain/usecases/delete_notification_usecase.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/inventory/data/datasources/inventory_remote_datasource.dart';
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/presentation/bloc/inventory_bloc.dart';
import '../../features/reports/data/datasources/export_remote_datasource.dart';
import '../../features/reports/data/repositories/export_repository.dart';
import '../../features/spaces/data/datasources/spaces_remote_datasource.dart';
import '../../features/spaces/data/repositories/spaces_repository_impl.dart';
import '../../features/spaces/domain/repositories/spaces_repository.dart';
import '../../features/spaces/presentation/bloc/spaces_bloc.dart';
import '../../features/states/data/datasources/coverage_remote_datasource.dart';
import '../../features/states/data/repositories/coverage_repository_impl.dart';
import '../../features/states/domain/repositories/coverage_repository.dart';
import '../../features/states/presentation/bloc/coverage_bloc.dart';
import '../../features/states/presentation/bloc/insurance_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // ─── Dashboard ────────────────────────────────────────────────
  // Data sources
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(
    () => GetDashboardStatsUseCase(repository: sl()),
  );
  sl.registerLazySingleton(
    () => GetParentSpacesUseCase(repository: sl()),
  );
  sl.registerLazySingleton(
    () => GetChildrenSpacesUseCase(repository: sl()),
  );
  sl.registerLazySingleton(
    () => GetNotificationsUseCase(repository: sl()),
  );
  sl.registerLazySingleton(
    () => DeleteNotificationUseCase(repository: sl()),
  );

  // Cubits
  sl.registerFactory(
    () => DashboardCubit(
      getDashboardStats: sl(),
      getParentSpaces: sl(),
      getChildrenSpaces: sl(),
      getNotifications: sl(),
      deleteNotificationUseCase: sl(),
    ),
  );

  // ─── Inventory ────────────────────────────────────────────────
  // Data sources
  sl.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(remoteDataSource: sl()),
  );

  // Bloc
  sl.registerFactory(
    () => InventoryBloc(repository: sl()),
  );

  // ─── Reports / Export ─────────────────────────────────────────
  sl.registerLazySingleton<ExportRemoteDataSource>(
    () => ExportRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<ExportRepository>(
    () => ExportRepository(remoteDataSource: sl()),
  );

  // ─── Spaces ───────────────────────────────────────────────────
  // Data sources
  sl.registerLazySingleton<SpacesRemoteDataSource>(
    () => SpacesRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<SpacesRepository>(
    () => SpacesRepositoryImpl(remoteDataSource: sl()),
  );

  // Bloc
  sl.registerFactory(
    () => SpacesBloc(repository: sl()),
  );

  // ─── Coverage Status (Garanții / Asigurări) ───────────────────
  // Data sources
  sl.registerLazySingleton<CoverageRemoteDataSource>(
    () => CoverageRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<CoverageRepository>(
    () => CoverageRepositoryImpl(remoteDataSource: sl()),
  );

  // Bloc
  sl.registerFactory(
    () => CoverageBloc(repository: sl()),
  );

  // Insurance Bloc
  sl.registerFactory(
    () => InsuranceBloc(repository: sl()),
  );
}
