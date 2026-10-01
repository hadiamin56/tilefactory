import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/market_price.dart';
import '../../repositories/listing_repository.dart';
import '../../repositories/market_price_repository.dart';
import '../../repositories/home_stats_repository.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_circle.dart';
import '../../repositories/message_repository.dart';
import '../../repositories/cart_repository.dart';
import '../market_prices/market_prices_screen.dart';
import '../buy_inputs/buy_inputs_screen.dart';
import '../messages/messages_screen.dart';
import '../cart/cart_screen.dart';
import '../buy_inputs/product_detail_screen.dart';
import '../orders/orders_screen.dart';
import '../my_farm/my_farm_screen.dart';
import '../wallet/wallet_screen.dart';
import '../support/support_screen.dart';
import '../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeStats> _statsFuture;
  late Future<List<MarketPrice>> _pricesFuture;
  late Future<List<Product>> _inputsFuture;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _statsFuture = HomeStatsRepository.fetchGrowerStats();
    _pricesFuture = MarketPriceRepository.fetchAll();
    _inputsFuture = ListingRepository.fetchActiveListings();
  }

  Future<void> _refresh() async {
    setState(_loadAll);
    await Future.wait([_statsFuture, _pricesFuture, _inputsFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  children: [
                    const _HeroBanner(),
                    const SizedBox(height: 22),
                    const _QuickActionsGrid(),
                    const SizedBox(height: 22),
                    _CategoriesRow(),
                    const SizedBox(height: 22),
                    FutureBuilder<HomeStats>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
                        }
                        return _StatsGrid(stats: snapshot.data!);
                      },
                    ),
                    const SizedBox(height: 26),
                    _SectionHeader(
                      title: "Today's Market Price",
                      onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketPricesScreen())),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<MarketPrice>>(
                      future: _pricesFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                        return _MarketPriceList(prices: snapshot.data!.take(4).toList());
                      },
                    ),
                    const SizedBox(height: 26),
                    _SectionHeader(
                      title: 'Buy Quality Inputs',
                      onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyInputsScreen())),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Product>>(
                      future: _inputsFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                        final items = snapshot.data!.take(3).toList();
                        if (items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('No listings yet', style: TextStyle(color: AppColors.textGrey)),
                          );
                        }
                        return Column(
                          children: items
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ProductCard(
                                      product: p,
                                      onAddToCart: () async {
                                        await CartRepository.addToCart(p.id, 1);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Added ${p.name} to cart')),
                                        );
                                      },
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                                    ),
                                  ))
                              .toList(),
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

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.eco, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(child: _GreetingText()),
          const _CartButtonBadge(),
          const SizedBox(width: 10),
          const _IconButtonBadge(),
          const SizedBox(width: 10),
          const CircleAvatar(radius: 19, backgroundColor: AppColors.primaryLight, child: Icon(Icons.person, color: AppColors.primary, size: 20)),
        ],
      ),
    );
  }
}

class _GreetingText extends StatelessWidget {
  const _GreetingText();

  static Future<Map<String, dynamic>> _fetchProfile() async {
    final userId = supabase.auth.currentUser!.id;
    return await supabase.from('profiles').select('full_name, role').eq('id', userId).single();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Mandi-Go', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textDark, letterSpacing: -0.3));
        }
        final name = (snapshot.data!['full_name'] as String?)?.split(' ').first ?? 'Grower';
        final role = (snapshot.data!['role'] as String?) ?? 'grower';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hi, $name', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textDark, letterSpacing: -0.3)),
            Text(role[0].toUpperCase() + role.substring(1), style: const TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        );
      },
    );
  }
}

class _CartButtonBadge extends StatelessWidget {
  const _CartButtonBadge();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: CartRepository.fetchItemCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: AppShadows.soft),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(child: Icon(Icons.shopping_cart_outlined, size: 20, color: AppColors.textDark)),
                if (count > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IconButtonBadge extends StatelessWidget {
  const _IconButtonBadge();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: MessageRepository.fetchUnreadCount(),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: AppShadows.soft),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.textDark)),
                if (unread > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.shopping_bag_rounded, 'Buy Inputs', AppColors.primary, AppColors.primaryLight, (BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const BuyInputsScreen()))),
      (Icons.receipt_long_rounded, 'My Orders', AppColors.blue, const Color(0xFFE7F0FF), (BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
      (Icons.bar_chart_rounded, 'Market Prices', AppColors.amber, const Color(0xFFFFF3E0), (BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const MarketPricesScreen()))),
      (Icons.eco_rounded, 'My Farm', AppColors.primary, AppColors.primaryLight, (BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const MyFarmScreen()))),
      (Icons.account_balance_wallet_rounded, 'Wallet', AppColors.purple, const Color(0xFFF1EEFF), (BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const WalletScreen()))),
      (Icons.chat_bubble_rounded, 'Messages', AppColors.blue, const Color(0xFFE7F0FF), (BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const MessagesScreen()))),
      (Icons.shopping_cart_rounded, 'My Cart', AppColors.primary, AppColors.primaryLight, (BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const CartScreen()))),
      (Icons.support_agent_rounded, 'Support', AppColors.amber, const Color(0xFFFFF3E0), (BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const SupportScreen()))),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 8,
      childAspectRatio: 0.78,
      children: actions.map((a) {
        return InkWell(
          onTap: () => a.$5(context),
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: a.$4, borderRadius: BorderRadius.circular(14)),
                child: Icon(a.$1, color: a.$3, size: 22),
              ),
              const SizedBox(height: 6),
              Text(a.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.coloredGreen,
      ),
      child: Stack(
        children: [
          Positioned(right: -18, top: -18, child: Icon(Icons.eco, size: 130, color: Colors.white.withValues(alpha: 0.08))),
          Positioned(right: 30, bottom: -30, child: Icon(Icons.local_florist, size: 90, color: Colors.white.withValues(alpha: 0.06))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text('Growers First', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              ),
              const SizedBox(height: 14),
              const Text('From Our Orchards\nto The World', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, height: 1.25, letterSpacing: -0.3)),
              const SizedBox(height: 8),
              Text('Direct Market. Better Price. Stronger Growers.', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sell Your Produce', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cats = [
      (Icons.circle, 'Apples', AppColors.red),
      (Icons.circle, 'Walnuts', const Color(0xFF8D6E63)),
      (Icons.circle, 'Cherries', const Color(0xFFD81B60)),
      (Icons.circle, 'Almonds', const Color(0xFFA1887F)),
      (Icons.spa, 'Saffron', AppColors.amber),
    ];
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = cats[i];
          return CategoryCircle(icon: c.$1, label: c.$2, color: c.$3);
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final HomeStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        StatCard(label: 'Active Orders', value: '${stats.activeOrders}', icon: Icons.shopping_bag, iconBg: AppColors.primaryLight, iconColor: AppColors.primary, actionLabel: 'View Orders'),
        StatCard(label: 'Total Sales', value: '\u20B9${stats.totalSales.toStringAsFixed(0)}', icon: Icons.bar_chart_rounded, iconBg: const Color(0xFFFFF3E0), iconColor: AppColors.amber, actionLabel: 'View Details'),
        StatCard(label: 'Wallet Balance', value: '\u20B9${stats.walletBalance.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, iconBg: const Color(0xFFF1EEFF), iconColor: AppColors.purple, actionLabel: 'Add Money'),
        StatCard(label: 'Profile Views', value: '${stats.profileViews}', icon: Icons.groups_rounded, iconBg: const Color(0xFFE7F0FF), iconColor: AppColors.blue, actionLabel: 'This Month'),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: AppColors.textDark, letterSpacing: -0.2)),
        GestureDetector(
          onTap: onViewAll,
          child: const Row(children: [
            Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
          ]),
        ),
      ],
    );
  }
}

class _MarketPriceList extends StatelessWidget {
  final List<MarketPrice> prices;
  const _MarketPriceList({required this.prices});

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return const Text('No market price data yet', style: TextStyle(color: AppColors.textGrey));
    }
    return Column(
      children: prices.map((m) {
        final up = m.changePercent >= 0;
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
                child: const Icon(Icons.eco_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(m.produceName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\u20B9${m.pricePerKg.toStringAsFixed(2)}/Kg', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 13, color: up ? AppColors.primary : AppColors.red),
                      Text('${m.changePercent.abs().toStringAsFixed(2)}%', style: TextStyle(color: up ? AppColors.primary : AppColors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}