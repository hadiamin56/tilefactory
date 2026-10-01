import '../main.dart';
import '../models/market_price.dart';

class MarketPriceRepository {
  static Future<List<MarketPrice>> fetchAll() async {
    final rows = await supabase.from('market_prices').select().order('produce_name');
    return (rows as List)
        .map((row) => MarketPrice(
              produceName: row['produce_name'] as String,
              pricePerKg: (row['price_per_kg'] as num).toDouble(),
              changePercent: (row['change_percent'] as num).toDouble(),
            ))
        .toList();
  }
}