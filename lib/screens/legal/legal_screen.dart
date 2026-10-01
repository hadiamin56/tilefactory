import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String body;
  const LegalScreen({super.key, required this.title, required this.body});

  static const String termsAndConditions = '''
Last updated: August 2026

1. Introduction
Welcome to Mandi-Go ("we", "us", "our"). Mandi-Go is a marketplace app that connects growers with sellers of farming inputs (seeds, fertilizers, pesticides, tools and related products). By creating an account or using the app, you agree to these Terms & Conditions.

2. Accounts
You must provide accurate information when creating an account. You are responsible for keeping your login credentials secure and for all activity under your account.

3. Marketplace Role
Mandi-Go acts as a platform connecting growers and sellers. We are not a party to the sale contract between a grower and a seller. Sellers are responsible for the accuracy of their listings, product quality, pricing, and fulfilment. Growers are responsible for providing accurate delivery details and payment.

4. Orders, Payments & Cancellations
Orders are placed against a seller's published listings and stock. Payments are deducted from your in-app wallet at checkout. Sellers may cancel an order that has not yet shipped (for example, if stock is unavailable); in that case the grower is refunded to their wallet automatically. Growers may cancel a pending order before it is confirmed.

5. Verification
Sellers may submit a request to be verified. Verified status is granted at Mandi-Go's discretion after a manual review and does not constitute a guarantee of product quality or business legitimacy.

6. Prohibited Use
You may not use the app to list or sell counterfeit, banned, or illegal agricultural inputs, to mislead other users, or to interfere with the normal operation of the platform.

7. Account Suspension
We may suspend or restrict an account that violates these terms or is involved in fraudulent activity.

8. Limitation of Liability
Mandi-Go is provided on an "as is" basis. We are not liable for losses arising from transactions between growers and sellers, crop outcomes, or product performance.

9. Changes to These Terms
We may update these Terms from time to time. Continued use of the app after changes are posted constitutes acceptance of the updated Terms.

10. Contact
For questions about these Terms, contact us through the support option in the app.
''';

  static const String privacyPolicy = '''
Last updated: August 2026

1. Information We Collect
We collect information you provide directly, such as your name, phone number, email address, business details (for sellers), delivery addresses, and order history. We also collect information generated through your use of the app, such as wallet transactions and listing activity.

2. How We Use Your Information
We use your information to operate the marketplace: to process orders, connect growers with sellers, manage your wallet balance, verify seller accounts, and provide customer support. We may also use it to improve the app and to communicate important updates.

3. Sharing of Information
Your name and relevant order details are shared with the other party in a transaction (for example, a seller sees a grower's delivery details for an order placed with them). We do not sell your personal information to third parties.

4. Data Storage & Security
Your data is stored using Supabase infrastructure with access controls in place to restrict who can view or modify it. While we take reasonable measures to protect your data, no method of storage or transmission is completely secure.

5. Account Deletion
You may request deletion of your account from the Settings screen. We will process deletion requests and remove your personal data within a reasonable time, except where retention is required for legal or accounting purposes.

6. Children's Privacy
Mandi-Go is not directed at children under 18. We do not knowingly collect information from children.

7. Your Choices
You can review and update your profile information at any time from within the app. You may also request account deletion at any time.

8. Changes to This Policy
We may update this Privacy Policy from time to time. We will notify users of material changes through the app.

9. Contact
For privacy-related questions, contact us through the support option in the app.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          body.trim(),
          style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textDark),
        ),
      ),
    );
  }
}
