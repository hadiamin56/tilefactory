import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../repositories/wallet_repository.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<double> _balanceFuture;
  late Future<List<WalletTransaction>> _txFuture;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _balanceFuture = WalletRepository.fetchBalance();
    _txFuture = WalletRepository.fetchTransactions();
  }

  Future<void> _refresh() async {
    setState(_loadAll);
    await Future.wait([_balanceFuture, _txFuture]);
  }

  Future<void> _showAddMoneySheet() async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Money', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Test top-up — no real payment gateway is connected yet.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: '\u20B9  ', hintText: 'Amount'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(controller.text.trim());
                  if (amount == null || amount <= 0) return;
                  Navigator.pop(sheetContext);
                  await WalletRepository.addMoney(amount);
                  if (!mounted) return;
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\u20B9${amount.toStringAsFixed(0)} added')));
                },
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wallet Balance', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  FutureBuilder<double>(
                    future: _balanceFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
                      }
                      return Text('\u20B9${snapshot.data!.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold));
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _showAddMoneySheet,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
                        child: const Text('Add Money'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            FutureBuilder<List<WalletTransaction>>(
              future: _txFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()));
                }
                final txs = snapshot.data!;
                if (txs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No transactions yet', style: TextStyle(color: AppColors.textGrey))),
                  );
                }
                return Column(
                  children: txs.map((t) {
                    final positive = t.amount >= 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.soft),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: positive ? AppColors.primaryLight : const Color(0xFFFCE9E9), shape: BoxShape.circle),
                            child: Icon(positive ? Icons.arrow_downward : Icons.arrow_upward, size: 16, color: positive ? AppColors.primary : AppColors.red),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(DateFormat('d MMM, h:mm a').format(t.date), style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(
                            '${positive ? '+' : ''}\u20B9${t.amount.toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: positive ? AppColors.primary : AppColors.red),
                          ),
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
    );
  }
}