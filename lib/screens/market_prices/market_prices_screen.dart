import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/market_price.dart';
import '../../repositories/market_price_repository.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  late Future<List<MarketPrice>> _pricesFuture;

  @override
  void initState() {
    super.initState();
    _pricesFuture = MarketPriceRepository.fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Market Prices')),
      body: FutureBuilder<List<MarketPrice>>(
        future: _pricesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load prices', style: TextStyle(color: AppColors.textGrey)));
          }
          final prices = snapshot.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: prices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = prices[i];
              final up = m.changePercent >= 0;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.soft),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.eco_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(m.produceName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\u20B9${m.pricePerKg.toStringAsFixed(2)}/Kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: up ? AppColors.primary : AppColors.red),
                            Text('${m.changePercent.abs().toStringAsFixed(2)}%', style: TextStyle(color: up ? AppColors.primary : AppColors.red, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}