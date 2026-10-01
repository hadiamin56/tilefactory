/// Fill these in from Supabase Dashboard → Settings → API.
/// The anon key is safe to ship in the app — it only allows what your
/// Row Level Security policies (in supabase/schema.sql) permit.
class SupabaseConfig {
  static const String url = 'https://gbnicemqszefwoevzyli.supabase.co';
  static const String anonKey = 'sb_publishable_TGuhC5ztB5uoieaai1KVjQ_n76Ryvgr';

  /// Password reset always requires a real email to be sent (no way around
  /// it), so it stays hidden until custom SMTP is configured and working in
  /// the Supabase Dashboard. Flip this to true once SMTP is verified.
  static const bool passwordResetEnabled = false;
}



