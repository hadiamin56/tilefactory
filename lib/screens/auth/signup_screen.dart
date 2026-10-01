import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import 'login_screen.dart';

enum SignupRole { grower, seller }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Grower-only fields
  final _locationController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _primaryCropController = TextEditingController();

  // Seller-only fields
  final _businessNameController = TextEditingController();

  SignupRole _role = SignupRole.grower;
  bool _obscure = true;
  bool _loading = false;
  bool _accountCreated = false;
  String? _error;

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty) return setState(() => _error = 'Enter your full name');
    if (email.isEmpty || !email.contains('@')) return setState(() => _error = 'Enter a valid email address');
    if (password.length < 8) return setState(() => _error = 'Password must be at least 8 characters');
    if (password != confirm) return setState(() => _error = 'Passwords do not match');
    if (_role == SignupRole.grower && _locationController.text.trim().isEmpty) {
      return setState(() => _error = 'Enter your farm location');
    }
    if (_role == SignupRole.seller && _businessNameController.text.trim().isEmpty) {
      return setState(() => _error = 'Enter your business name');
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final metadata = <String, dynamic>{
        'full_name': name,
        'role': _role == SignupRole.grower ? 'grower' : 'seller',
        'phone': _phoneController.text.trim(),
        if (_role == SignupRole.grower) ...{
          'location': _locationController.text.trim(),
          'farm_size': _farmSizeController.text.trim(),
          'primary_crop': _primaryCropController.text.trim(),
        },
        if (_role == SignupRole.seller) ...{
          'business_name': _businessNameController.text.trim(),
        },
      };

      final response = await supabase.auth.signUp(email: email, password: password, data: metadata);
      if (!mounted) return;
      if (response.session != null) {
        // Email confirmation is disabled on the project right now — the user
        // is already signed in. AuthGate rebuilt behind this pushed route;
        // pop back to it so the new session's screen is actually shown.
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(() => _accountCreated = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong — check your internet and try again');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_accountCreated) {
      return Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 44, color: AppColors.primary),
              const SizedBox(height: 14),
              const Text('Confirm your email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'We sent a confirmation link to ${_emailController.text.trim()}. Tap it, then come back and log in.',
                style: const TextStyle(color: AppColors.textGrey, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Go to Login'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create your account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Join Mandi-Go as a Grower or a Seller', style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 24),

            const Text('I am a', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _RoleTile(label: 'Grower', icon: Icons.agriculture, selected: _role == SignupRole.grower, onTap: () => setState(() => _role = SignupRole.grower))),
                const SizedBox(width: 12),
                Expanded(child: _RoleTile(label: 'Seller', icon: Icons.store, selected: _role == SignupRole.seller, onTap: () => setState(() => _role = SignupRole.seller))),
              ],
            ),
            const SizedBox(height: 18),

            const _Label('Full Name'),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Your name')),
            const SizedBox(height: 14),

            const _Label('Email'),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'you@example.com')),
            const SizedBox(height: 14),

            const _Label('Phone (optional)'),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+91 98765 43210')),
            const SizedBox(height: 14),

            const _Label('Password'),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'At least 8 characters',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 14),

            const _Label('Confirm Password'),
            TextField(controller: _confirmPasswordController, obscureText: _obscure, decoration: const InputDecoration(hintText: 'Re-enter password')),
            const SizedBox(height: 18),

            // --- Role-specific fields ---
            if (_role == SignupRole.grower) ...[
              const Text('Farm Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 12),
              const _Label('Farm Location'),
              TextField(controller: _locationController, decoration: const InputDecoration(hintText: 'e.g. Anantnag, Kashmir')),
              const SizedBox(height: 14),
              const _Label('Farm Size (optional)'),
              TextField(controller: _farmSizeController, decoration: const InputDecoration(hintText: 'e.g. 4.5 Acres')),
              const SizedBox(height: 14),
              const _Label('Primary Crop (optional)'),
              TextField(controller: _primaryCropController, decoration: const InputDecoration(hintText: 'e.g. Apple (High Density)')),
            ] else ...[
              const Text('Business Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 12),
              const _Label('Business Name'),
              TextField(controller: _businessNameController, decoration: const InputDecoration(hintText: 'e.g. Kashmir AgroSupplies')),
            ],

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12.5)),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                    children: [
                      TextSpan(text: 'Already have an account? '),
                      TextSpan(text: 'Log In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textGrey),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textGrey, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}