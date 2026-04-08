import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/fcm_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;

  const RegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, email, password];
}

class LogoutRequested extends AuthEvent {}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String token;
  final String newPassword;

  const ResetPasswordRequested({
    required this.email,
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, token, newPassword];
}

class VerifyEmailRequested extends AuthEvent {
  final String email;
  final String token;

  const VerifyEmailRequested({required this.email, required this.token});

  @override
  List<Object?> get props => [email, token];
}

class ResendVerificationRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;

  const ResendVerificationRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, email, password];
}

class ResendLoginVerificationRequested extends AuthEvent {
  final String email;
  final String password;

  const ResendLoginVerificationRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userName;
  final String email;

  const AuthAuthenticated({required this.userName, required this.email});

  @override
  List<Object?> get props => [userName, email];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordSuccess extends AuthState {
  final String email;
  const ForgotPasswordSuccess({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPasswordSuccess extends AuthState {}

class RegisterPendingVerification extends AuthState {
  final String email;
  final String fullName;
  final String password;

  const RegisterPendingVerification({
    required this.email,
    required this.fullName,
    required this.password,
  });

  @override
  List<Object?> get props => [email, fullName, password];
}

class EmailVerified extends AuthState {
  final String userName;
  final String email;

  const EmailVerified({required this.userName, required this.email});

  @override
  List<Object?> get props => [userName, email];
}

class ResendVerificationSuccess extends AuthState {}

class LoginPendingVerification extends AuthState {
  final String email;
  final String password;

  const LoginPendingVerification({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRemoteDataSource _authRemoteDataSource =
      AuthRemoteDataSourceImpl(sl<ApiClient>());

  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<VerifyEmailRequested>(_onVerifyEmailRequested);
    on<ResendVerificationRequested>(_onResendVerificationRequested);
    on<ResendLoginVerificationRequested>(_onResendLoginVerificationRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRemoteDataSource.login(event.email, event.password);
      final token = response['token'] as String?;
      if (token != null && token.isNotEmpty) {
        // Înregistrează tokenul FCM la backend (push notifications prin FCM)
        await FcmService.registerDeviceToken();

        emit(AuthAuthenticated(
          userName: response['userName'] ?? 'Utilizator',
          email: event.email,
        ));
      } else {
        emit(const AuthError('Email sau parolă incorectă!'));
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == '403') {
        // Backend a retrimis automat un cod nou pe email
        emit(LoginPendingVerification(email: event.email, password: event.password));
      } else {
        emit(AuthError('Eroare la autentificare: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRemoteDataSource.register(
        event.fullName,
        event.email,
        event.password,
      );
      // Backend răspunde 200 cu mesaj — userul trebuie să verifice email-ul
      emit(RegisterPendingVerification(
        email: event.email,
        fullName: event.fullName,
        password: event.password,
      ));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == '409') {
        emit(const AuthError('Există deja un cont verificat cu acest email.'));
      } else {
        emit(AuthError('Eroare la înregistrare: $msg'));
      }
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    // Oprește verificarea periodică și curăță notificările
    NotificationService.stopPeriodicCheck();
    await NotificationService.clearShownNotifications();

    // Dezînregistrează tokenul FCM de la backend (înainte de ștergerea JWT-ului)
    await FcmService.unregisterDeviceToken();

    await Future.delayed(const Duration(milliseconds: 500));
    emit(AuthUnauthenticated());
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRemoteDataSource.forgotPassword(event.email);
      emit(ForgotPasswordSuccess(email: event.email));
    } catch (e) {
      // Răspundem cu succes indiferent de eroare pentru a nu expune
      // dacă email-ul există sau nu (comportament de securitate)
      emit(ForgotPasswordSuccess(email: event.email));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRemoteDataSource.resetPassword(
        event.email,
        event.token,
        event.newPassword,
      );
      emit(ResetPasswordSuccess());
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message));
    }
  }

  Future<void> _onVerifyEmailRequested(
    VerifyEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRemoteDataSource.verifyEmail(
        event.email,
        event.token,
      );
      await FcmService.registerDeviceToken();
      emit(EmailVerified(
        userName: response['userName'] ?? 'Utilizator',
        email: event.email,
      ));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message));
    }
  }

  Future<void> _onResendVerificationRequested(
    ResendVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRemoteDataSource.register(
        event.fullName,
        event.email,
        event.password,
      );
      // Backend retrimite codul și returnează tot 200
      emit(ResendVerificationSuccess());
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      // 409 înseamnă că email-ul a fost deja verificat între timp
      if (msg == '409') {
        emit(const AuthError('Contul tău este deja verificat. Autentifică-te.'));
      } else {
        emit(const AuthError('Nu s-a putut retrimite codul. Încearcă din nou.'));
      }
    }
  }

  Future<void> _onResendLoginVerificationRequested(
    ResendLoginVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Apelăm login — backend va returna 403 și va retrimite automat un cod nou
      await _authRemoteDataSource.login(event.email, event.password);
      // Dacă cumva contul a fost verificat între timp și login-ul reușește
      emit(ResendVerificationSuccess());
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == '403') {
        // 403 = codul a fost retrimis cu succes
        emit(ResendVerificationSuccess());
      } else {
        emit(const AuthError('Nu s-a putut retrimite codul. Încearcă din nou.'));
      }
    }
  }
}
