import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({required this.id, this.email, this.isDemo = false});

  static const demo = AppUser(id: 'demo', isDemo: true);

  final String id;
  final String? email;

  /// True for the "try it without an account" session, which runs on the
  /// in-memory demo orders and never touches the backend.
  final bool isDemo;

  @override
  List<Object?> get props => [id, isDemo];
}

/// Why a sign-in failed, in words the user can act on.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  AppUser? get currentUser;

  /// Emits on sign-in, sign-out and session expiry.
  Stream<AppUser?> get changes;

  /// Throws [AuthFailure].
  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();
}
