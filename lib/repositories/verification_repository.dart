import '../main.dart';

class VerificationRequest {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final DateTime createdAt;

  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.createdAt,
  });
}

class VerificationRepository {
  static Future<void> submitRequest() async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('verification_requests').insert({'user_id': userId, 'status': 'pending'});
  }

  static Future<bool> hasPendingRequest() async {
    final userId = supabase.auth.currentUser!.id;
    final rows = await supabase.from('verification_requests').select('id').eq('user_id', userId).eq('status', 'pending');
    return (rows as List).isNotEmpty;
  }

  /// Admin: fetch all pending verification requests, with the requester's
  /// name/role attached for display.
  static Future<List<VerificationRequest>> fetchPending() async {
    final rows = await supabase
        .from('verification_requests')
        .select('id, user_id, created_at')
        .eq('status', 'pending')
        .order('created_at', ascending: true);

    final requestRows = (rows as List).cast<Map<String, dynamic>>();
    if (requestRows.isEmpty) return [];

    final userIds = requestRows.map((r) => r['user_id'] as String).toSet().toList();
    final profileRows = await supabase.from('profiles_public').select('id, full_name, business_name, role').inFilter('id', userIds);
    final byId = {for (final row in (profileRows as List)) row['id'] as String: row as Map<String, dynamic>};

    return requestRows.map((row) {
      final profile = byId[row['user_id']];
      final name = (profile?['business_name'] as String?)?.isNotEmpty == true
          ? profile!['business_name'] as String
          : (profile?['full_name'] as String? ?? 'User');
      return VerificationRequest(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        userName: name,
        userRole: (profile?['role'] as String?) ?? 'grower',
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  /// Admin: approve a request — marks it approved and flips the user's
  /// profile to verified.
  static Future<void> approve(String requestId, String userId) async {
    await supabase.from('verification_requests').update({'status': 'approved'}).eq('id', requestId);
    await supabase.from('profiles').update({'is_verified': true}).eq('id', userId);
  }

  /// Admin: reject a request without verifying the user.
  static Future<void> reject(String requestId) async {
    await supabase.from('verification_requests').update({'status': 'rejected'}).eq('id', requestId);
  }
}
