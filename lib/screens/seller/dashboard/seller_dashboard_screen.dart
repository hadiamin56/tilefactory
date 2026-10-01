import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../main.dart';
import '../../../repositories/seller_stats_repository.dart';
import '../../../repositories/order_repository.dart';
import '../../../widgets/stat_card.dart';
import '../customers/seller_customers_screen.dart';
import '../analytics/seller_analytics_screen.dart';
import '../reviews/seller_reviews_screen.dart';
import '../listings/seller_listings_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  late Future<SellerStats> _statsFuture;
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _statsFuture = SellerStatsRepository.fetch();
    _profileFuture = _fetchProfile();
    _ordersFuture = OrderRepository.fetchIncomingOrders();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final userId = supabase.auth.currentUser!.id;
    return await supabase.from('profiles').select('business_name').eq('id', userId).single();
  }

  Future<void> _refresh() async {
    setState(_loadAll);
    await Future.wait([_statsFuture, _profileFuture, _ordersFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _profileFuture,
                        builder: (context, snapshot) {
                          final name = snapshot.data?['business_name'] as String? ?? 'My Store';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: AppColors.textDark)),
                              const Text('Input Supplier · Kashmir', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: AppColors.textDark))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _QuickAction(icon: Icons.list_alt_rounded, label: 'My Listings', color: AppColors.primary, bg: AppColors.primaryLight, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerListingsScreen())))),
                        const SizedBox(width: 10),
                        Expanded(child: _QuickAction(icon: Icons.people_rounded, label: 'Customers', color: AppColors.blue, bg: const Color(0xFFE7F0FF), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerCustomersScreen())))),
                        const SizedBox(width: 10),
                        Expanded(child: _QuickAction(icon: Icons.bar_chart_rounded, label: 'Analytics', color: AppColors.amber, bg: const Color(0xFFFFF3E0), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerAnalyticsScreen())))),
                        const SizedBox(width: 10),
                        Expanded(child: _QuickAction(icon: Icons.star_rounded, label: 'Reviews', color: AppColors.purple, bg: const Color(0xFFF1EEFF), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerReviewsScreen())))),
                      ],
                    ),
                    const SizedBox(height: 22),
                    FutureBuilder<SellerStats>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
                        }
                        final s = snapshot.data!;
                        return Column(
                          children: [
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.25,
                              children: [
                                StatCard(label: 'Active Orders', value: '${s.activeOrders}', icon: Icons.shopping_bag_rounded, iconBg: AppColors.primaryLight, iconColor: AppColors.primary),
                                StatCard(label: 'Total Sales', value: '\u20B9${s.totalSales.toStringAsFixed(0)}', icon: Icons.bar_chart_rounded, iconBg: const Color(0xFFFFF3E0), iconColor: AppColors.amber),
                                StatCard(label: 'Wallet Balance', value: '\u20B9${s.walletBalance.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, iconBg: const Color(0xFFF1EEFF), iconColor: AppColors.purple),
                                StatCard(label: 'Listings', value: '${s.listingsCount}', icon: Icons.list_alt_rounded, iconBg: const Color(0xFFE7F0FF), iconColor: AppColors.blue),
                              ],
                            ),
                            const SizedBox(height: 22),
                            _SalesTrendCard(weekSales: s.weekSales),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    const Align(alignment: Alignment.centerLeft, child: Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: AppColors.textDark))),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _ordersFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
                        final orders = snapshot.data!.take(3).toList();
                        if (orders.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('No orders yet', style: TextStyle(color: AppColors.textGrey)),
                          );
                        }
                        return Column(
                          children: orders.map((o) {
                            final items = (o['order_items'] as List);
                            final summary = items.isNotEmpty ? '${items[0]['product_name']} x${items[0]['quantity']}' : '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(o['grower_name'] as String? ?? 'Grower', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                        Text(summary, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text('\u20B9${(o['total'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.soft),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }
}

class _SalesTrendCard extends StatelessWidget {
  final List<double> weekSales;
  const _SalesTrendCard({required this.weekSales});

  @override
  Widget build(BuildContext context) {
    final days = ['6d', '5d', '4d', '3d', '2d', 'Yest', 'Today'];
    final maxVal = weekSales.isEmpty ? 1.0 : weekSales.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last 7 Days', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.textDark)),
              Text('Sales Trend', style: TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(weekSales.length, (i) {
                final ratio = weekSales[i] / safeMax;
                final isMax = weekSales[i] == maxVal && maxVal > 0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: (68 * ratio).clamp(4, 68).toDouble(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isMax
                              ? [AppColors.primary, AppColors.primaryDark]
                              : [AppColors.primary.withValues(alpha: 0.35), AppColors.primary.withValues(alpha: 0.15)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(days[i], style: const TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}