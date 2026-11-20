import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/auth_repository.dart';

class AuthState extends Equatable {
  const AuthState({this.user, this.busy = false, this.error});

  final AppUser? user;

  /// A sign-in request is in flight.
  final bool busy;
  final String? error;

  bool get signedIn => user != null;

  @override
  List<Object?> get props => [user, busy, error];
}

/// Owns the session. A null [AuthRepository] means the build has no
/// backend configured, and only the demo session is offered.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(AuthState(user: _repo?.currentUser)) {
    _sub = _repo?.changes.listen((user) {
      // A backend sign-out must not end a demo session, and vice versa.
      if (state.user?.isDemo ?? false) return;
      emit(AuthState(user: user));
    });
  }

  final AuthRepository? _repo;
  StreamSubscription<AppUser?>? _sub;

  bool get backendAvailable => _repo != null;

  Future<void> signIn(String email, String password) async {
    final repo = _repo;
    if (repo == null || state.busy) return;
    emit(const AuthState(busy: true));
    try {
      emit(AuthState(user: await repo.signIn(email: email, password: password)));
    } on AuthFailure catch (e) {
      emit(AuthState(error: e.message));
    }
  }

  void enterDemo() => emit(const AuthState(user: AppUser.demo));

  Future<void> signOut() async {
    final wasDemo = state.user?.isDemo ?? false;
    emit(const AuthState());
    if (!wasDemo) await _repo?.signOut();
  }

  void clearError() {
    if (state.error != null) emit(AuthState(user: state.user));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
