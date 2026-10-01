import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';

class MyFarmScreen extends StatefulWidget {
  const MyFarmScreen({super.key});

  @override
  State<MyFarmScreen> createState() => _MyFarmScreenState();
}

class _MyFarmScreenState extends State<MyFarmScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final userId = supabase.auth.currentUser!.id;
    return await supabase.from('profiles').select('location, farm_size, primary_crop, created_at').eq('id', userId).single();
  }

  Future<void> _showEditSheet(Map<String, dynamic> current) async {
    final locationController = TextEditingController(text: current['location'] as String? ?? '');
    final sizeController = TextEditingController(text: current['farm_size'] as String? ?? '');
    final cropController = TextEditingController(text: current['primary_crop'] as String? ?? '');

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
            const Text('Edit Farm Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: locationController, decoration: const InputDecoration(hintText: 'Farm location')),
            const SizedBox(height: 12),
            TextField(controller: sizeController, decoration: const InputDecoration(hintText: 'Farm size, e.g. 4.5 Acres')),
            const SizedBox(height: 12),
            TextField(controller: cropController, decoration: const InputDecoration(hintText: 'Primary crop')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final userId = supabase.auth.currentUser!.id;
                  await supabase.from('profiles').update({
                    'location': locationController.text.trim(),
                    'farm_size': sizeController.text.trim(),
                    'primary_crop': cropController.text.trim(),
                  }).eq('id', userId);
                  if (!mounted) return;
                  Navigator.pop(sheetContext);
                  setState(() {
                    _profileFuture = _fetchProfile();
                  });
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _val(Map<String, dynamic> profile, String key) {
    final v = profile[key] as String?;
    return (v != null && v.isNotEmpty) ? v : 'Not set';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Farm')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data!;
          final memberSince = DateFormat('MMM yyyy').format(DateTime.parse(profile['created_at'] as String));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.coloredGreen),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.eco, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_val(profile, 'location'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 3),
                          Text(_val(profile, 'farm_size'), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showEditSheet(profile),
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('Farm Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                child: Column(
                  children: [
                    _InfoRow(label: 'Farm Size', value: _val(profile, 'farm_size')),
                    const Divider(height: 1),
                    _InfoRow(label: 'Location', value: _val(profile, 'location')),
                    const Divider(height: 1),
                    _InfoRow(label: 'Primary Crop', value: _val(profile, 'primary_crop')),
                    const Divider(height: 1),
                    _InfoRow(label: 'Member Since', value: memberSince, showDivider: false),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditSheet(profile),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Farm Details'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;
  const _InfoRow({required this.label, required this.value, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13.5)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        ],
      ),
    );
  }
}
