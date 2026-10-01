import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../my_farm/my_farm_screen.dart';
import '../wallet/wallet_screen.dart';
import '../auth_gate.dart';
import '../support/support_screen.dart';
import '../settings/settings_screen.dart';
import '../../repositories/verification_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final userId = supabase.auth.currentUser!.id;
    return await supabase.from('profiles').select().eq('id', userId).single();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data!;
          final name = (profile['full_name'] as String?) ?? 'Grower';
          final location = (profile['location'] as String?) ?? 'Location not set';
          final isVerified = profile['is_verified'] as bool? ?? false;
          final role = (profile['role'] as String?) ?? 'grower';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 32, backgroundColor: AppColors.primaryLight, child: Icon(Icons.person, color: AppColors.primary, size: 32)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, size: 16, color: AppColors.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          role[0].toUpperCase() + role.substring(1),
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppColors.textGrey),
                          const SizedBox(width: 2),
                          Text(location, style: const TextStyle(color: AppColors.textGrey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!isVerified)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Become a Verified Grower\nGet more visibility and better opportunities.', style: TextStyle(fontSize: 13)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final pending = await VerificationRepository.hasPendingRequest();
                            if (pending) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Your verification request is already pending review')),
                              );
                              return;
                            }
                            await VerificationRepository.submitRequest();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Verification request submitted — our team will review it soon')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not submit request')));
                          }
                        },
                        child: const Text('Get Verified'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              _MenuTile(icon: Icons.agriculture_outlined, label: 'My Farm', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyFarmScreen()))),
              _MenuTile(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
              _MenuTile(icon: Icons.support_agent_outlined, label: 'Support', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
              _MenuTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
              _MenuTile(icon: Icons.logout, label: 'Log Out', color: AppColors.red, onTap: _confirmLogout),
            ],
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _MenuTile({required this.icon, required this.label, this.color = AppColors.textDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
      onTap: onTap,
    );
  }
}