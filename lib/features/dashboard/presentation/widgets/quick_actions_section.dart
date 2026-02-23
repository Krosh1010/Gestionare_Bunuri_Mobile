import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Inventar',
                  subtitle: 'Gestionează toate bunurile',
                  icon: Icons.assignment_outlined,
                  gradientColors: [
                    const Color(0xFF667EEA).withValues(alpha: 0.1),
                    const Color(0xFF764BA2).withValues(alpha: 0.1),
                  ],
                  iconColor: const Color(0xFF667EEA),
                  onTap: () => context.go('/inventory'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  title: 'Rapoarte',
                  subtitle: 'Generează și exportă',
                  icon: Icons.bar_chart_rounded,
                  gradientColors: [
                    const Color(0xFF10B981).withValues(alpha: 0.1),
                    const Color(0xFF22C55E).withValues(alpha: 0.1),
                  ],
                  iconColor: const Color(0xFF10B981),
                  onTap: () => context.go('/reports'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Locații',
                  subtitle: 'Urmărește bunurile',
                  icon: Icons.location_on_outlined,
                  gradientColors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    const Color(0xFF2563EB).withValues(alpha: 0.1),
                  ],
                  iconColor: const Color(0xFF3B82F6),
                  onTap: () {
                    // TODO: Navigate to locations
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  title: 'Stare',
                  subtitle: 'Garanții/Asigurări',
                  icon: Icons.access_time_rounded,
                  gradientColors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    const Color(0xFFD97706).withValues(alpha: 0.1),
                  ],
                  iconColor: const Color(0xFFF59E0B),
                  onTap: () {
                    // TODO: Navigate to coverage status
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
