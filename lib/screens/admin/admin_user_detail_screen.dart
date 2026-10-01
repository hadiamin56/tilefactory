import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../repositories/admin_repository.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final AdminUser user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late String _role;
  late bool _isVerified;
  late String _accountStatus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _locationController = TextEditingController(text: widget.user.location ?? '');
    _role = widget.user.role;
    _isVerified = widget.user.isVerified;
    _accountStatus = widget.user.accountStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AdminRepository.updateUser(
        userId: widget.user.id,
        fullName: _nameController.text.trim(),
        role: _role,
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        isVerified: _isVerified,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update user')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setStatus(String status, String confirmTitle, String confirmBody) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmTitle, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminRepository.setAccountStatus(widget.user.id, status);
      if (!mounted) return;
      setState(() => _accountStatus = status);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account $status')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update account status')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.user.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Icon(widget.user.role == 'seller' ? Icons.store : Icons.person, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 3),
                    Text('Joined ${DateFormat('d MMM yyyy').format(widget.user.createdAt)}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (_accountStatus == 'active' ? AppColors.primary : _accountStatus == 'suspended' ? AppColors.amber : AppColors.red).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _accountStatus.toUpperCase(),
                  style: TextStyle(
                    color: _accountStatus == 'active' ? AppColors.primary : _accountStatus == 'suspended' ? AppColors.amber : AppColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Profile Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          const SizedBox(height: 12),
          const _Label('Full Name'),
          TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Full name')),
          const SizedBox(height: 14),
          const _Label('Phone'),
          TextField(controller: _phoneController, decoration: const InputDecoration(hintText: 'Phone number')),
          const SizedBox(height: 14),
          const _Label('Location'),
          TextField(controller: _locationController, decoration: const InputDecoration(hintText: 'Location')),
          const SizedBox(height: 14),
          const _Label('Role'),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(value: 'grower', child: Text('Grower')),
              DropdownMenuItem(value: 'seller', child: Text('Seller')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (v) => setState(() => _role = v ?? _role),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isVerified,
            onChanged: (v) => setState(() => _isVerified = v),
            title: const Text('Verified', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Account Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          const SizedBox(height: 12),
          if (_accountStatus != 'suspended')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _setStatus('suspended', 'Suspend', 'This will block ${widget.user.displayName} from logging in. Continue?'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.amber, side: const BorderSide(color: AppColors.amber)),
                icon: const Icon(Icons.pause_circle_outline, size: 18),
                label: const Text('Suspend Account'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _setStatus('active', 'Reactivate', 'This will restore ${widget.user.displayName}\'s access. Continue?'),
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Reactivate Account'),
              ),
            ),
          const SizedBox(height: 10),
          if (_accountStatus != 'deleted')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _setStatus(
                  'deleted',
                  'Delete',
                  'This will permanently block ${widget.user.displayName} from the platform and hide their data from other users. Continue?',
                ),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Account'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
