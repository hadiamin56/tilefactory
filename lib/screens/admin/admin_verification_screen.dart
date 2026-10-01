import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../repositories/verification_repository.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  late Future<List<VerificationRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = VerificationRepository.fetchPending();
  }

  Future<void> _refresh() async {
    setState(() => _requestsFuture = VerificationRepository.fetchPending());
    await _requestsFuture;
  }

  Future<void> _approve(VerificationRequest r) async {
    try {
      await VerificationRepository.approve(r.id, r.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r.userName} verified')));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not approve request')));
    }
  }

  Future<void> _reject(VerificationRequest r) async {
    try {
      await VerificationRepository.reject(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request from ${r.userName} rejected')));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not reject request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verification Requests')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<VerificationRequest>>(
          future: _requestsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Could not load requests: ${snapshot.error}', style: const TextStyle(color: AppColors.textGrey)));
            }
            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Icon(Icons.verified_outlined, size: 48, color: AppColors.textGrey)),
                  SizedBox(height: 12),
                  Center(child: Text('No pending verification requests', style: TextStyle(color: AppColors.textGrey))),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = requests[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(r.userRole == 'seller' ? Icons.store : Icons.person, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(
                                  '${r.userRole[0].toUpperCase()}${r.userRole.substring(1)} · Requested ${DateFormat('d MMM yyyy').format(r.createdAt)}',
                                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _reject(r),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approve(r),
                              child: const Text('Approve'),
                            ),
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
      ),
    );
  }
}
