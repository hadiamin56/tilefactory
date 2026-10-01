import '../main.dart';

class AdminUser {
  final String id;
  final String? fullName;
  final String? businessName;
  final String role;
  final String? phone;
  final String? location;
  final bool isVerified;
  final String accountStatus;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.businessName,
    required this.role,
    required this.phone,
    required this.location,
    required this.isVerified,
    required this.accountStatus,
    required this.createdAt,
  });

  String get displayName => (businessName != null && businessName!.isNotEmpty) ? businessName! : (fullName ?? 'User');

  factory AdminUser.fromRow(Map<String, dynamic> row) {
    return AdminUser(
      id: row['id'] as String,
      fullName: row['full_name'] as String?,
      businessName: row['business_name'] as String?,
      role: (row['role'] as String?) ?? 'grower',
      phone: row['phone'] as String?,
      location: row['location'] as String?,
      isVerified: row['is_verified'] as bool? ?? false,
      accountStatus: (row['account_status'] as String?) ?? 'active',
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

/// All methods here rely on the `is_admin()` RLS policies granted to the
/// `admin` role on the `profiles` table — the database enforces the access
/// control, this repository is just the client-side call surface.
class AdminRepository {
  static Future<List<AdminUser>> fetchAllUsers() async {
    final rows = await supabase.from('profiles').select().order('created_at', ascending: false);
    return (rows as List).map((r) => AdminUser.fromRow(r as Map<String, dynamic>)).toList();
  }

  static Future<void> updateUser({
    required String userId,
    required String fullName,
    required String role,
    required String phone,
    required String location,
    required bool isVerified,
  }) async {
    await supabase.from('profiles').update({
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'location': location,
      'is_verified': isVerified,
    }).eq('id', userId);
  }

  static Future<void> setAccountStatus(String userId, String status) async {
    await supabase.from('profiles').update({'account_status': status}).eq('id', userId);
  }
}
