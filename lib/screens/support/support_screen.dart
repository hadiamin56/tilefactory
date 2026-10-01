import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      ('How do I place an order?', 'Go to Buy Inputs, pick a product, choose quantity, and tap Confirm Purchase. Payment is deducted from your Wallet.'),
      ('How do I add money to my wallet?', 'Go to Profile > Wallet > Add Money and enter the amount.'),
      ('How do I cancel an order?', 'Go to My Orders — you can cancel any order that is still Pending. Cancelled orders are refunded to your wallet automatically.'),
      ('How do I become a Verified Grower/Seller?', 'Go to your Profile and tap "Get Verified". Our team reviews requests manually.'),
      ('How do I contact a seller?', 'Open a product in Buy Inputs and tap "Message" to start a conversation.'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [
                Icon(Icons.support_agent, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(child: Text('Need more help? Email us at support@mandigo.app', style: TextStyle(fontSize: 13))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...faqs.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(f.$2, style: const TextStyle(color: AppColors.textGrey, fontSize: 13))],
                ),
              )),
        ],
      ),
    );
  }
}