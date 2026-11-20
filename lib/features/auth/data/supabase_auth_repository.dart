import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  static AppUser? _map(User? u) =>
      u == null ? null : AppUser(id: u.id, email: u.email);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> get changes =>
      _auth.onAuthStateChange.map((s) => _map(s.session?.user));

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _map(res.user)!;
    } on AuthException catch (e) {
      throw AuthFailure(_message(e));
    } catch (_) {
      throw const AuthFailure('ما قدرنا نوصل للخادم. تأكد من الإنترنت وجرّب كمان مرة.');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  static String _message(AuthException e) => switch (e.code) {
    'invalid_credentials' => 'الإيميل أو كلمة السر غلط.',
    'email_not_confirmed' => 'لازم تأكد الإيميل أول، شوف بريدك.',
    'over_request_rate_limit' ||
    'over_email_send_rate_limit' => 'محاولات كتير ورا بعض. استنّى دقيقة وجرّب.',
    _ when e.statusCode == null => 'ما قدرنا نوصل للخادم. تأكد من الإنترنت وجرّب كمان مرة.',
    _ => 'ما زبط تسجيل الدخول (${e.message}).',
  };
}
