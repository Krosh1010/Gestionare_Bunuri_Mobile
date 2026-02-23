import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/dashboard_provider.dart';
import '../providers/dashboard_state.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/status_stats_card.dart';
import '../widgets/locations_card.dart';
import '../widgets/notifications_card.dart';
import '../widgets/categories_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is DashboardError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                        const SizedBox(height: 16),
                        Text(
                          'Eroare la încărcarea datelor',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<DashboardCubit>().loadDashboardStats();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reîncearcă'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is DashboardLoaded) {
                final stats = state.stats;
                final totalCount = stats.totalCount;
                final locationTree = state.locationTree;
                final notifications = state.notifications;

                final categories = [
                  CategoryData(label: 'Electronice', count: stats.electronicsCount, color: const Color(0xFF667EEA)),
                  CategoryData(label: 'Mobilier', count: stats.furnitureCount, color: const Color(0xFF764BA2)),
                  CategoryData(label: 'Vehicule', count: stats.vehiclesCount, color: const Color(0xFF10B981)),
                  CategoryData(label: 'Documente', count: stats.documentsCount, color: const Color(0xFFF59E0B)),
                  CategoryData(label: 'Altele', count: stats.otherCount, color: const Color(0xFFEF4444)),
                ];

                return RefreshIndicator(
                  onRefresh: () => context.read<DashboardCubit>().loadDashboardStats(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DashboardHeader(),

                        _buildSummaryBanner(stats, locationTree.length, notifications.length),
                        const SizedBox(height: 20),

                        NotificationsCard(
                          notifications: notifications,
                          onViewAll: () {},
                          onMarkAsRead: (id) {
                            context.read<DashboardCubit>().deleteNotification(id);
                          },
                        ),
                        const SizedBox(height: 20),

                        StatusStatsCard(
                          title: 'Status Asigurări',
                          total: stats.totalInsurance,
                          expired: stats.expiredInsurance,
                          expiringSoon: stats.expiringSoonInsurance,
                          active: stats.activeInsurance,
                          topBorderColor: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 16),
                        StatusStatsCard(
                          title: 'Status Garanții',
                          total: stats.totalWarranty,
                          expired: stats.expiredWarranty,
                          expiringSoon: stats.expiringSoonWarranty,
                          active: stats.activeWarranty,
                          topBorderColor: const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 20),

                        CategoriesCard(
                          categories: categories,
                          totalCount: totalCount,
                        ),
                        const SizedBox(height: 20),

                        LocationsCard(
                          locationTree: locationTree,
                          totalLocations: locationTree.length,
                          isLoading: state.locationsLoading,
                          onViewAll: () {},
                          onLoadChildren: (node) => context.read<DashboardCubit>().loadChildren(node),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBanner(dynamic stats, int locationCount, int notificationCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _SummaryItem(
            value: '${stats.totalCount}',
            label: 'Total Bunuri',
            icon: Icons.inventory_2_rounded,
          ),
          _buildDivider(),
          _SummaryItem(
            value: '$locationCount',
            label: 'Locații',
            icon: Icons.location_on_rounded,
          ),
          _buildDivider(),
          _SummaryItem(
            value: '$notificationCount',
            label: 'Alerte',
            icon: Icons.notifications_active_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
