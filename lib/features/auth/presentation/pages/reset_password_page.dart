import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/auth_bloc.dart';

class ResetPasswordPage extends StatefulWidget {
  final String prefillEmail;

  const ResetPasswordPage({super.key, required this.prefillEmail});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _resendCode(BuildContext context) {
    context.read<AuthBloc>().add(
          ForgotPasswordRequested(email: widget.prefillEmail),
        );
    _startCooldown();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            ResetPasswordRequested(
              email: widget.prefillEmail,
              token: _tokenController.text.trim(),
              newPassword: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);

    return BlocProvider(
      create: (_) => AuthBloc(),
      child: Builder(
        builder: (ctx) => BlocConsumer<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is ResetPasswordSuccess) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Parola a fost resetată cu succes! Te poți autentifica acum.',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 4),
                ),
              );
              router.go('/login');
            } else if (state is ForgotPasswordSuccess) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Un nou cod a fost trimis pe email-ul tău.',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          builder: (ctx, state) {
            final isLoading = state is AuthLoading;
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // ── Buton înapoi la forgot-password ──
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () => router.go('/forgot-password'),
                                icon: const Icon(Icons.arrow_back_ios_rounded,
                                    size: 16, color: Colors.white),
                                label: const Text(
                                  'Schimbă email-ul',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ── Icon ──
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.lock_open_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Resetare parolă',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Introdu codul primit pe email și noua parolă',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // ── Card ──
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Parolă nouă',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),

                                    // ── Email afișat (nu input) ──
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.divider),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.email_outlined,
                                              color: AppColors.textHint,
                                              size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Cod trimis la',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color: AppColors
                                                              .textSecondary),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  widget.prefillEmail,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // ── Cod resetare ──
                                    TextFormField(
                                      controller: _tokenController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      enabled: !isLoading,
                                      maxLength: 6,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Cod resetare (6 cifre)',
                                        prefixIcon: const Icon(
                                            Icons.pin_outlined,
                                            color: AppColors.textHint),
                                        filled: true,
                                        fillColor: AppColors.background,
                                        counterText: '',
                                        helperText:
                                            'Codul primit pe email — valabil 15 min',
                                        helperStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppColors.textSecondary),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Introduceți codul de resetare';
                                        }
                                        if (!RegExp(r'^\d{6}$')
                                            .hasMatch(value.trim())) {
                                          return 'Codul trebuie să aibă exact 6 cifre';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 4),

                                    // ── Retrimite cod ──
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed:
                                            (isLoading || _resendCooldown > 0)
                                                ? null
                                                : () => _resendCode(ctx),
                                        icon: Icon(
                                          Icons.refresh_rounded,
                                          size: 16,
                                          color: _resendCooldown > 0
                                              ? AppColors.textHint
                                              : AppColors.primary,
                                        ),
                                        label: Text(
                                          _resendCooldown > 0
                                              ? 'Retrimite cod ($_resendCooldown s)'
                                              : 'Retrimite cod',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _resendCooldown > 0
                                                ? AppColors.textHint
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // ── Parolă nouă ──
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      enabled: !isLoading,
                                      decoration: InputDecoration(
                                        labelText: 'Parolă nouă',
                                        prefixIcon: const Icon(
                                            Icons.lock_outlined,
                                            color: AppColors.textHint),
                                        filled: true,
                                        fillColor: AppColors.background,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.textHint,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Introduceți parola nouă';
                                        }
                                        if (value.length < 8) {
                                          return 'Parola trebuie să aibă cel puțin 8 caractere';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),

                                    // ── Confirmă parola ──
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirm,
                                      textInputAction: TextInputAction.done,
                                      enabled: !isLoading,
                                      onFieldSubmitted: (_) => _submit(ctx),
                                      decoration: InputDecoration(
                                        labelText: 'Confirmă parola',
                                        prefixIcon: const Icon(
                                            Icons.lock_outline_rounded,
                                            color: AppColors.textHint),
                                        filled: true,
                                        fillColor: AppColors.background,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirm
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.textHint,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscureConfirm =
                                                  !_obscureConfirm),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Confirmați parola nouă';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Parolele nu coincid';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 28),

                                    // ── Resetează parola (buton principal) ──
                                    SizedBox(
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => _submit(ctx),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : const Text(
                                                'Resetează parola',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // ── Mergi direct la login (buton secundar) ──
                                    SizedBox(
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : () => router.go('/login'),
                                        icon: const Icon(
                                          Icons.login_rounded,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Mergi la autentificare',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          side: const BorderSide(
                                              color: AppColors.primary,
                                              width: 1.5),
                                          foregroundColor: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

