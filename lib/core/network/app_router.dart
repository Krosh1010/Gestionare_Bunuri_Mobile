import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/inventory/presentation/pages/add_asset_page.dart';
import '../../features/inventory/presentation/pages/asset_detail_page.dart';
import '../../features/inventory/presentation/pages/post_save_menu_page.dart';
import '../../features/inventory/presentation/pages/edit_asset_page.dart';
import '../../features/inventory/presentation/bloc/asset_detail_cubit.dart';
import '../../features/inventory/domain/entities/asset.dart';
import '../../features/reports/presentation/pages/export_page.dart';
import '../../features/spaces/presentation/pages/spaces_page.dart';
import '../../features/states/presentation/pages/coverage_status_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../constants/app_colors.dart';
import '../di/injection_container.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordPage(prefillEmail: email);
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return VerifyEmailPage(
            prefillEmail: extra['email'] as String? ?? '',
            fullName: extra['fullName'] as String? ?? '',
            password: extra['password'] as String? ?? '',
          );
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => BlocProvider(
              create: (_) => sl<DashboardCubit>()..loadDashboardStats(),
              child: const DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryPage(),
          ),
          GoRoute(
            path: '/coverage',
            builder: (context, state) => const CoverageStatusPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ExportPage(),
          ),
          GoRoute(
            path: '/spaces',
            builder: (context, state) => const SpacesPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/inventory/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddAssetPage(),
      ),
      GoRoute(
        path: '/inventory/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final asset = state.extra;
          if (asset is Asset) {
            return EditAssetPage(asset: asset);
          }
          return const Scaffold(
            body: Center(child: Text('Eroare: bunul nu a fost găsit')),
          );
        },
      ),
      GoRoute(
        path: '/inventory/post-save/:assetId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final assetId = int.parse(state.pathParameters['assetId']!);
          return PostSaveMenuPage(assetId: assetId);
        },
      ),
      GoRoute(
        path: '/inventory/barcode-result',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final asset = state.extra;
          if (asset is Asset) {
            return BlocProvider(
              create: (_) => sl<AssetDetailCubit>()..loadFromAsset(asset),
              child: AssetDetailPage(assetId: asset.id),
            );
          }
          return const Scaffold(
            body: Center(child: Text('Eroare: bunul nu a fost găsit')),
          );
        },
      ),
      GoRoute(
        path: '/inventory/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final assetId = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => sl<AssetDetailCubit>()..loadAssetDetail(assetId),
            child: AssetDetailPage(assetId: assetId),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
}

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/inventory')) return 1;
    if (location.startsWith('/coverage')) return 2;
    if (location.startsWith('/spaces')) return 3;
    if (location.startsWith('/reports')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/dashboard');
                break;
              case 1:
                context.go('/inventory');
                break;
              case 2:
                context.go('/coverage');
                break;
              case 3:
                context.go('/spaces');
                break;
              case 4:
                context.go('/reports');
                break;
            }
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
              label: 'Panou',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
              label: 'Inventar',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield, color: AppColors.primary),
              label: 'Stări',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on, color: AppColors.primary),
              label: 'Spații',
            ),
            NavigationDestination(
              icon: Icon(Icons.file_download_outlined),
              selectedIcon: Icon(Icons.file_download, color: AppColors.primary),
              label: 'Export',
            ),
          ],
        ),
      ),
    );
  }
}
