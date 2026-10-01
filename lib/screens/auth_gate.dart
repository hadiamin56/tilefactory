import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'auth/welcome_screen.dart';
import 'auth/reset_password_screen.dart';
import 'role_select/role_select_screen.dart';
import 'root_shell.dart';
import 'seller/seller_root_shell.dart';
import 'admin/admin_dashboard_screen.dart';

/// Watches Supabase auth state and shows the right screen:
/// - No session -> Welcome (Login / Sign Up)
/// - Password recovery link tapped -> Reset Password screen
/// - Suspended/deleted account -> Blocked screen (can only sign out)
/// - Session with a role saved in `profiles` -> straight into that dashboard
/// - Session but no role somehow (edge case / legacy accounts) -> Role Select
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final event = snapshot.data?.event;
        if (event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordScreen();
        }

        final session = supabase.auth.currentSession;
        if (session == null) {
          return const WelcomeScreen();
        }
        return const _RoleResolver();
      },
    );
  }
}

class _ProfileState {
  final String? role;
  final String accountStatus;
  const _ProfileState({required this.role, required this.accountStatus});
}

class _RoleResolver extends StatefulWidget {
  const _RoleResolver();

  @override
  State<_RoleResolver> createState() => _RoleResolverState();
}

class _RoleResolverState extends State<_RoleResolver> {
  late Future<_ProfileState> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileState();
  }

  Future<_ProfileState> _fetchProfileState() async {
    final userId = supabase.auth.currentUser!.id;
    final row = await supabase.from('profiles').select('role, account_status').eq('id', userId).maybeSingle();
    return _ProfileState(
      role: row?['role'] as String?,
      accountStatus: (row?['account_status'] as String?) ?? 'active',
    );
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileState>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // A failed fetch (network blip, timing hiccup) must NEVER be treated
        // as "no role yet" — that would drop an existing seller/grower onto
        // RoleSelectScreen, and picking a role there overwrites their real
        // one. Only an actually-empty role reaches RoleSelectScreen.
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text("Couldn't load your account — check your internet and try again."),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _profileFuture = _fetchProfileState()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final state = snapshot.data!;
        if (state.accountStatus != 'active') {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block_rounded, size: 40, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      state.accountStatus == 'suspended'
                          ? 'Your account has been suspended. Contact support if you think this is a mistake.'
                          : 'This account is no longer active.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _signOut, child: const Text('Log Out')),
                  ],
                ),
              ),
            ),
          );
        }

        final role = state.role;
        if (role == 'admin') return const AdminDashboardScreen();
        if (role == 'seller') return const SellerRootShell();
        if (role == 'grower') return const RootShell();
        return const RoleSelectScreen();
      },
    );
  }
}
