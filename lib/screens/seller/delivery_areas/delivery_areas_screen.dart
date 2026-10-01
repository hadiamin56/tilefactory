import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../main.dart';

class DeliveryAreasScreen extends StatefulWidget {
  const DeliveryAreasScreen({super.key});

  @override
  State<DeliveryAreasScreen> createState() => _DeliveryAreasScreenState();
}

class _DeliveryAreasScreenState extends State<DeliveryAreasScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = supabase.auth.currentUser!.id;
    final row = await supabase.from('profiles').select('delivery_areas').eq('id', userId).single();
    _controller.text = row['delivery_areas'] as String? ?? '';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('profiles').update({'delivery_areas': _controller.text.trim()}).eq('id', userId);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery areas saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Areas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'List the areas/towns you deliver to, comma-separated.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'e.g. Srinagar, Anantnag, Pulwama, Baramulla'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
    );
  }
}