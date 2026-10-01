import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../auth_gate.dart';
import '../../repositories/admin_repository.dart';
import '../../repositories/verification_repository.dart';
import 'admin_user_detail_screen.dart';
import 'admin_verification_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<AdminUser>> _usersFuture;
  late Future<List<VerificationRequest>> _verificationFuture;
  String _search = '';
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _usersFuture = AdminRepository.fetchAllUsers();
    _verificationFuture = VerificationRepository.fetchPending();
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = AdminRepository.fetchAllUsers();
      _verificationFuture = VerificationRepository.fetchPending();
    });
    await _usersFuture;
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthGate()), (route) => false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'suspended':
        return AppColors.amber;
      case 'deleted':
        return AppColors.red;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: FutureBuilder<List<AdminUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load users: ${snapshot.error}', style: const TextStyle(color: AppColors.textGrey)));
          }
          final all = snapshot.data ?? [];
          var users = all;
          if (_roleFilter != null) {
            users = users.where((u) => u.role == _roleFilter).toList();
          }
          if (_search.trim().isNotEmpty) {
            final q = _search.trim().toLowerCase();
            users = users.where((u) => u.displayName.toLowerCase().contains(q) || (u.phone ?? '').contains(q)).toList();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(label: 'Total Users', value: '${all.length}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(label: 'Growers', value: '${all.where((u) => u.role == 'grower').length}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(label: 'Sellers', value: '${all.where((u) => u.role == 'seller').length}'),
                      ),
                    ],
                  ),
                ),
                FutureBuilder<List<VerificationRequest>>(
                  future: _verificationFuture,
                  builder: (context, vSnapshot) {
                    final pendingCount = vSnapshot.data?.length ?? 0;
                    if (pendingCount == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen()));
                          _refresh();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_outlined, color: AppColors.amber),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '$pendingCount verification request${pendingCount == 1 ? '' : 's'} awaiting review',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textDark),
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textGrey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: const InputDecoration(hintText: 'Search users...', prefixIcon: Icon(Icons.search, size: 20)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _RoleChip(label: 'All', selected: _roleFilter == null, onTap: () => setState(() => _roleFilter = null)),
                      _RoleChip(label: 'Growers', selected: _roleFilter == 'grower', onTap: () => setState(() => _roleFilter = 'grower')),
                      _RoleChip(label: 'Sellers', selected: _roleFilter == 'seller', onTap: () => setState(() => _roleFilter = 'seller')),
                      _RoleChip(label: 'Admins', selected: _roleFilter == 'admin', onTap: () => setState(() => _roleFilter = 'admin')),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: users.isEmpty
                      ? const Center(child: Text('No users found', style: TextStyle(color: AppColors.textGrey)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final u = users[i];
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserDetailScreen(user: u)));
                                _refresh();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Icon(u.role == 'seller' ? Icons.store : Icons.person, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                          const SizedBox(height: 3),
                                          Text(u.role[0].toUpperCase() + u.role.substring(1), style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: _statusColor(u.accountStatus).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                      child: Text(
                                        u.accountStatus.toUpperCase(),
                                        style: TextStyle(color: _statusColor(u.accountStatus), fontSize: 10.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.soft),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textGrey, fontWeight: FontWeight.w600, fontSize: 12.5),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      ),
    );
  }
}
