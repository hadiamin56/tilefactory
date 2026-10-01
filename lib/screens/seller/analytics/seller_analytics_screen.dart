import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../repositories/seller_analytics_repository.dart';

class SellerAnalyticsScreen extends StatefulWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  late Future<SellerAnalytics> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = SellerAnalyticsRepository.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analytics')),
      body: FutureBuilder<SellerAnalytics>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final a = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _MetricCard(label: 'Total Sales', value: '₹${a.totalSales.toStringAsFixed(0)}', icon: Icons.payments_rounded, color: AppColors.primary, bg: AppColors.primaryLight)),
                  const SizedBox(width: 10),
                  Expanded(child: _MetricCard(label: 'Total Orders', value: '${a.totalOrders}', icon: Icons.receipt_long_rounded, color: AppColors.blue, bg: const Color(0xFFE7F0FF))),
                ],
              ),
              const SizedBox(height: 10),
              _MetricCard(label: 'Avg Order Value', value: '₹${a.avgOrderValue.toStringAsFixed(0)}', icon: Icons.trending_up_rounded, color: AppColors.amber, bg: const Color(0xFFFFF3E0), fullWidth: true),
              const SizedBox(height: 22),
              const Text('Last 7 Days', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.soft),
                child: _SalesTrendChart(weekSales: a.weekSales),
              ),
              const SizedBox(height: 22),
              const Text('Top Products', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              const SizedBox(height: 12),
              if (a.topProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No sales yet', style: TextStyle(color: AppColors.textGrey))),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                  child: Column(
                    children: a.topProducts.asMap().entries.map((entry) {
                      final p = entry.value;
                      final isLast = entry.key == a.topProducts.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                      Text('${p.unitsSold} sold', style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                Text('₹${p.revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                              ],
                            ),
                          ),
                          if (!isLast) const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final bool fullWidth;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color, required this.bg, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  final List<double> weekSales;
  const _SalesTrendChart({required this.weekSales});

  @override
  Widget build(BuildContext context) {
    final days = ['6d', '5d', '4d', '3d', '2d', 'Yest', 'Today'];
    final maxVal = weekSales.isEmpty ? 1.0 : weekSales.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    return SizedBox(
      height: 100,
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
                width: 22,
                height: (72 * ratio).clamp(4, 72).toDouble(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isMax ? [AppColors.primary, AppColors.primaryDark] : [AppColors.primary.withValues(alpha: 0.35), AppColors.primary.withValues(alpha: 0.15)],
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
    );
  }
}
