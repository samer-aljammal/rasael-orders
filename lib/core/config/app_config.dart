/// Build-time configuration, passed with `--dart-define-from-file`.
///
/// Without a Supabase URL and key the app still runs, on the demo
/// repository only: that is the public web build recruiters open.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get hasBackend => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
