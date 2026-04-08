import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/auth_bloc.dart';

class VerifyEmailPage extends StatefulWidget {
  final String prefillEmail;
  final String fullName;
  final String password;

  const VerifyEmailPage({
    super.key,
    required this.prefillEmail,
    required this.fullName,
    required this.password,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();

  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  // true when the user arrived here from the login page (403 flow)
  bool get _fromLogin => widget.fullName.isEmpty;

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
    if (_fromLogin) {
      // Re-apelăm login — backend returnează 403 și retrimite automat codul
      context.read<AuthBloc>().add(
            ResendLoginVerificationRequested(
              email: widget.prefillEmail,
              password: widget.password,
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            ResendVerificationRequested(
              fullName: widget.fullName,
              email: widget.prefillEmail,
              password: widget.password,
            ),
          );
    }
    _startCooldown();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            VerifyEmailRequested(
              email: widget.prefillEmail,
              token: _tokenController.text.trim(),
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
            if (state is EmailVerified) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Email verificat! Bun venit în aplicație.',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 3),
                ),
              );
              router.go('/dashboard');
            } else if (state is ResendVerificationSuccess) {
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
                            // ── Buton înapoi ──
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () => router.go(_fromLogin ? '/login' : '/register'),
                                icon: const Icon(Icons.arrow_back_ios_rounded,
                                    size: 16, color: Colors.white),
                                label: Text(
                                  _fromLogin ? 'Înapoi la autentificare' : 'Înapoi la înregistrare',
                                  style: const TextStyle(color: Colors.white),
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
                                Icons.mark_email_unread_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Verifică email-ul',
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
                              'Introdu codul de 6 cifre primit pe email',
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
                                      'Confirmare cont',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Codul este valabil 15 minute.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),

                                    // ── Email afișat (read-only) ──
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

                                    // ── Câmp cod ──
                                    TextFormField(
                                      controller: _tokenController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.done,
                                      enabled: !isLoading,
                                      maxLength: 6,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 12,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onFieldSubmitted: (_) => _submit(ctx),
                                      decoration: InputDecoration(
                                        labelText: 'Cod verificare',
                                        hintText: '······',
                                        hintStyle: TextStyle(
                                          fontSize: 28,
                                          letterSpacing: 12,
                                          color: AppColors.textHint
                                              .withValues(alpha: 0.4),
                                        ),
                                        prefixIcon: const Icon(
                                            Icons.pin_outlined,
                                            color: AppColors.textHint),
                                        filled: true,
                                        fillColor: AppColors.background,
                                        counterText: '',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Introduceți codul primit pe email';
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
                                    const SizedBox(height: 16),

                                    // ── Buton verificare ──
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
                                                'Verifică contul',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // ── Mergi direct la login ──
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

