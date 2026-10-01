import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../main.dart';
import '../../auth_gate.dart';
import '../../settings/settings_screen.dart';
import '../../wallet/wallet_screen.dart';
import '../../support/support_screen.dart';
import '../reviews/seller_reviews_screen.dart';
import '../../../repositories/review_repository.dart';
import '../store_details/store_details_screen.dart';
import '../delivery_areas/delivery_areas_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<ReviewSummary> _reviewSummaryFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _reviewSummaryFuture = ReviewRepository.fetchSummaryForSeller(supabase.auth.currentUser!.id);
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final userId = supabase.auth.currentUser!.id;
    return await supabase.from('profiles').select('business_name, phone, location, delivery_areas, created_at').eq('id', userId).single();
  }

  void _refreshProfile() => setState(() => _profileFuture = _fetchProfile());

  Future<void> _logout(BuildContext context) async {
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
    if (confirmed != true) return;
    await supabase.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  String _val(Map<String, dynamic> profile, String key, [String fallback = 'Not set']) {
    final v = profile[key] as String?;
    return (v != null && v.isNotEmpty) ? v : fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Store Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data!;
          final businessName = _val(profile, 'business_name', 'My Store');
          final memberSince = DateFormat('MMM yyyy').format(DateTime.parse(profile['created_at'] as String));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 32, backgroundColor: AppColors.primaryLight, child: Icon(Icons.store, color: AppColors.primary, size: 32)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Seller', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 3),
                        Text('Input Supplier · ${_val(profile, 'location', 'Kashmir')}', style: const TextStyle(color: AppColors.textGrey)),
                        const SizedBox(height: 4),
                        FutureBuilder<ReviewSummary>(
                          future: _reviewSummaryFuture,
                          builder: (context, snapshot) {
                            final summary = snapshot.data ?? ReviewSummary.empty;
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerReviewsScreen())),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 15, color: AppColors.amber),
                                  const SizedBox(width: 3),
                                  Text(
                                    summary.count == 0 ? 'No reviews yet' : '${summary.average.toStringAsFixed(1)} (${summary.count})',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text('Business Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                child: Column(
                  children: [
                    _InfoRow(label: 'Phone', value: _val(profile, 'phone')),
                    const Divider(height: 1),
                    _InfoRow(label: 'Delivery Areas', value: _val(profile, 'delivery_areas')),
                    const Divider(height: 1),
                    _InfoRow(label: 'Member Since', value: memberSince, showDivider: false),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('Settings & Support', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.storefront_outlined,
                      label: 'Store Details',
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreDetailsScreen()));
                        _refreshProfile();
                      },
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.local_shipping_outlined,
                      label: 'Delivery Areas',
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryAreasScreen()));
                        _refreshProfile();
                      },
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Wallet & Payouts',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.star_outline_rounded,
                      label: 'Reviews',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerReviewsScreen())),
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.support_agent_outlined,
                      label: 'Support',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                    const Divider(height: 1),
                    _MenuTile(icon: Icons.logout, label: 'Log Out', color: AppColors.red, onTap: () => _logout(context)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;
  const _InfoRow({required this.label, required this.value, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13.5)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        ],
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
      onTap: onTap ?? () {},
    );
  }
}
