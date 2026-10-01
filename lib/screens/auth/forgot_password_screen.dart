import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';

/// Must match a Redirect URL configured in Supabase Dashboard →
/// Authentication → URL Configuration, and the AndroidManifest intent-filter.
const String kPasswordResetRedirectUrl = 'io.mandigo.app://reset-password';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await supabase.auth.resetPasswordForEmail(email, redirectTo: kPasswordResetRedirectUrl);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = 'Could not send reset email — try again');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_sent) ...[
              const Icon(Icons.mark_email_read_outlined, size: 44, color: AppColors.primary),
              const SizedBox(height: 14),
              const Text('Check your email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('We sent a password reset link to ${_emailController.text.trim()}. Open it on this phone.', style: const TextStyle(color: AppColors.textGrey, height: 1.4)),
            ] else ...[
              const Text('Reset your password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text("Enter your email and we'll send you a reset link.", style: TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 22),
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'you@example.com')),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12.5)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendReset,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send Reset Link'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}