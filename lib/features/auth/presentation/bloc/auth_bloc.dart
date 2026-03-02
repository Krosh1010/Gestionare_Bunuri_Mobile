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

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRemoteDataSource _authRemoteDataSource =
      AuthRemoteDataSourceImpl(sl<ApiClient>());

  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
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
      emit(AuthError('Eroare la autentificare: ${e.toString()}'));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRemoteDataSource.register(
        event.fullName,
        event.email,
        event.password,
      );
      final token = response['token'] as String?;
      if (token != null && token.isNotEmpty) {
        // Înregistrează tokenul FCM la backend (push notifications prin FCM)
        await FcmService.registerDeviceToken();

        emit(AuthAuthenticated(
          userName: response['userName'] ?? event.fullName,
          email: event.email,
        ));
      } else {
        emit(const AuthError('Eroare la înregistrare. Încearcă din nou.'));
      }
    } catch (e) {
      emit(AuthError('Eroare la înregistrare: ${e.toString()}'));
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
}
