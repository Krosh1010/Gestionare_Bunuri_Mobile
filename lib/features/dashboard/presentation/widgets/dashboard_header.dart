import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/domain/entities/profile_user.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, d MMMM y', 'ro_RO');
    String formattedDate;
    try {
      formattedDate = dateFormat.format(now);
    } catch (_) {
      formattedDate = DateFormat('EEEE, d MMMM y').format(now);
    }

    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Bună dimineața! ☀️';
    } else if (hour < 18) {
      greeting = 'Bună ziua! 👋';
    } else {
      greeting = 'Bună seara! 🌙';
    }

    return BlocProvider(
      create: (_) => ProfileBloc(repository: sl<ProfileRepository>())
        ..add(ProfileLoadRequested()),
      child: Builder(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Panou de Gestiune',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Avatar — shows initials when loaded
                BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    String? initials;
                    if (state is ProfileLoaded) {
                      initials = _getInitials(state.user.fullName);
                    } else if (state is ProfileUpdateSuccess) {
                      initials = _getInitials(state.user.fullName);
                    }

                    return GestureDetector(
                      onTap: () => _showUserMenu(context, state),
                      child: Container(
                        width: 48,
                        height: 48,
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
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: initials != null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _showUserMenu(BuildContext context, ProfileState state) {
    ProfileUser? user;
    if (state is ProfileLoaded) user = state.user;
    if (state is ProfileUpdateSuccess) user = state.user;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UserMenuSheet(user: user),
    );
  }
}

// ─── User Menu Bottom Sheet ──────────────────────────────────────
class _UserMenuSheet extends StatelessWidget {
  final ProfileUser? user;

  const _UserMenuSheet({this.user});

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user?.fullName ?? 'Utilizator';
    final displayEmail = user?.email ?? '';
    final displayRole = user?.role;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: user != null
                      ? Text(
                          _getInitials(displayName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                ),
              ),
              const SizedBox(height: 14),
              // Name
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              if (displayEmail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  displayEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
              if (displayRole != null && displayRole.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayRole,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Profil
              _MenuOption(
                icon: Icons.person_outline_rounded,
                label: 'Profilul meu',
                color: const Color(0xFF667EEA),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),
              const SizedBox(height: 8),
              // Setări
              _MenuOption(
                icon: Icons.settings_outlined,
                label: 'Setări',
                color: const Color(0xFF6B7280),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              // Delogare
              _MenuOption(
                icon: Icons.logout_rounded,
                label: 'Deconectare',
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color == const Color(0xFFEF4444)
                        ? color
                        : const Color(0xFF111827),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
