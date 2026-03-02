import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/repositories/profile_repository.dart';

// ─── Events ─────────────────────────────────────────────────────
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {}

class ProfileUpdateDataRequested extends ProfileEvent {
  final String fullName;
  final String email;

  const ProfileUpdateDataRequested({required this.fullName, required this.email});

  @override
  List<Object?> get props => [fullName, email];
}

class ProfileChangePasswordRequested extends ProfileEvent {
  final String currentPassword;
  final String newPassword;

  const ProfileChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

// ─── States ─────────────────────────────────────────────────────
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileUser user;

  const ProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileUpdateSuccess extends ProfileState {
  final ProfileUser user;
  final String message;

  const ProfileUpdateSuccess({required this.user, required this.message});

  @override
  List<Object?> get props => [user, message];
}

class ProfilePasswordChangeSuccess extends ProfileState {
  final ProfileUser user;

  const ProfilePasswordChangeSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfilePasswordChangeError extends ProfileState {
  final String message;
  final ProfileUser user;

  const ProfilePasswordChangeError({required this.message, required this.user});

  @override
  List<Object?> get props => [message, user];
}

// ─── Bloc ───────────────────────────────────────────────────────
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;
  ProfileUser? _cachedUser;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadProfile);
    on<ProfileUpdateDataRequested>(_onUpdateData);
    on<ProfileChangePasswordRequested>(_onChangePassword);
  }

  Future<void> _onLoadProfile(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final user = await repository.getProfile();
      _cachedUser = user;
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(_parseError(e)));
    }
  }

  Future<void> _onUpdateData(
    ProfileUpdateDataRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final user = await repository.updateData(
        fullName: event.fullName,
        email: event.email,
      );
      _cachedUser = user;
      emit(ProfileUpdateSuccess(user: user, message: 'Datele au fost actualizate cu succes!'));
    } catch (e) {
      emit(ProfileError(_parseError(e)));
      // Re-emit loaded state with cached user so UI stays functional
      if (_cachedUser != null) {
        emit(ProfileLoaded(_cachedUser!));
      }
    }
  }

  Future<void> _onChangePassword(
    ProfileChangePasswordRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      await repository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(ProfilePasswordChangeSuccess(_cachedUser!));
    } catch (e) {
      if (_cachedUser != null) {
        emit(ProfilePasswordChangeError(
          message: _parseError(e),
          user: _cachedUser!,
        ));
      } else {
        emit(ProfileError(_parseError(e)));
      }
    }
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('DioException')) {
      if (e.toString().contains('400')) {
        return 'Date invalide. Verifică informațiile introduse.';
      }
      if (e.toString().contains('401')) {
        return 'Sesiunea a expirat. Autentifică-te din nou.';
      }
      if (e.toString().contains('404')) {
        return 'Utilizatorul nu a fost găsit.';
      }
      if (e.toString().contains('connection')) {
        return 'Eroare de conexiune. Verifică internetul.';
      }
    }
    return 'A apărut o eroare: ${e.toString()}';
  }
}

