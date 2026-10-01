import '../main.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String body;
  final DateTime createdAt;
  final bool read;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.createdAt,
    required this.read,
  });
}

class ChatThread {
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatThread({
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });
}

class MessageRepository {
  /// Groups all of the current user's messages by the other participant.
  static Future<List<ChatThread>> fetchThreads() async {
    final myId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('messages')
        .select()
        .or('sender_id.eq.$myId,receiver_id.eq.$myId')
        .order('created_at', ascending: false);

    final messages = (rows as List).cast<Map<String, dynamic>>();

    // Group by "the other person" in each message.
    final Map<String, List<Map<String, dynamic>>> byOther = {};
    for (final m in messages) {
      final other = m['sender_id'] == myId ? m['receiver_id'] as String : m['sender_id'] as String;
      byOther.putIfAbsent(other, () => []).add(m);
    }

    if (byOther.isEmpty) return [];

    final names = await supabase.from('profiles_public').select('id, full_name, business_name').inFilter('id', byOther.keys.toList());
    final nameById = <String, String>{};
    for (final row in (names as List)) {
      nameById[row['id'] as String] = (row['business_name'] as String?) ?? (row['full_name'] as String?) ?? 'User';
    }

    return byOther.entries.map((entry) {
      final otherId = entry.key;
      final msgs = entry.value; // already newest-first
      final last = msgs.first;
      final unread = msgs.where((m) => m['receiver_id'] == myId && m['read'] == false).length;
      return ChatThread(
        otherUserId: otherId,
        otherUserName: nameById[otherId] ?? 'User',
        lastMessage: last['body'] as String,
        lastMessageAt: DateTime.parse(last['created_at'] as String),
        unreadCount: unread,
      );
    }).toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  static Future<List<ChatMessage>> fetchConversation(String otherUserId) async {
    final myId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('messages')
        .select()
        .or('and(sender_id.eq.$myId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$myId)')
        .order('created_at', ascending: true);

    // Mark incoming messages as read.
    await supabase.from('messages').update({'read': true}).eq('sender_id', otherUserId).eq('receiver_id', myId).eq('read', false);

    return (rows as List)
        .map((row) => ChatMessage(
              id: row['id'] as String,
              senderId: row['sender_id'] as String,
              receiverId: row['receiver_id'] as String,
              body: row['body'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              read: row['read'] as bool,
            ))
        .toList();
  }

  static Future<void> sendMessage({required String receiverId, required String body}) async {
    final myId = supabase.auth.currentUser!.id;
    await supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': receiverId,
      'body': body,
    });
  }

  static Future<int> fetchUnreadCount() async {
    final myId = supabase.auth.currentUser!.id;
    final rows = await supabase.from('messages').select('id').eq('receiver_id', myId).eq('read', false);
    return (rows as List).length;
  }
}