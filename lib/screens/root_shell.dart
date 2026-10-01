import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'orders/orders_screen.dart';
import 'buy_inputs/buy_inputs_screen.dart';
import 'profile/profile_screen.dart';
import 'messages/messages_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    OrdersScreen(),
    BuyInputsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  final _items = const [
    (Icons.home_rounded, 'Home'),
    (Icons.receipt_long_rounded, 'Orders'),
    (Icons.shopping_bag_rounded, 'Buy'),
    (Icons.chat_bubble_rounded, 'Chat'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.lifted,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final selected = _index == i;
                final item = _items[i];
                return GestureDetector(
                  onTap: () => setState(() => _index = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.$1, size: 22, color: selected ? AppColors.primary : AppColors.textGrey),
                        if (selected) ...[
                          const SizedBox(width: 7),
                          Text(item.$2, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
