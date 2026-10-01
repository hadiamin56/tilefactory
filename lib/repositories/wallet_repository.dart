import '../main.dart';

class WalletTransaction {
  final String label;
  final double amount;
  final DateTime date;

  const WalletTransaction({required this.label, required this.amount, required this.date});
}

class WalletRepository {
  static Future<double> fetchBalance() async {
    final userId = supabase.auth.currentUser!.id;
    final row = await supabase.from('profiles').select('wallet_balance').eq('id', userId).single();
    return (row['wallet_balance'] as num).toDouble();
  }

  static Future<List<WalletTransaction>> fetchTransactions() async {
    final userId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('wallet_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((row) => WalletTransaction(
              label: row['label'] as String,
              amount: (row['amount'] as num).toDouble(),
              date: DateTime.parse(row['created_at'] as String),
            ))
        .toList();
  }

  /// Simulated top-up for testing — in production this is called only
  /// after a real payment gateway (Razorpay/Stripe) confirms payment.
  static Future<void> addMoney(double amount) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.rpc('adjust_wallet_balance', params: {
      'p_user_id': userId,
      'p_amount': amount,
    });
    await supabase.from('wallet_transactions').insert({
      'user_id': userId,
      'label': 'Wallet top-up',
      'amount': amount,
    });
  }
}