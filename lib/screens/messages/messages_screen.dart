import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../repositories/message_repository.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<ChatThread>> _threadsFuture;

  @override
  void initState() {
    super.initState();
    _threadsFuture = MessageRepository.fetchThreads();
  }

  Future<void> _refresh() async {
    setState(() {
      _threadsFuture = MessageRepository.fetchThreads();
    });
    await _threadsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.search_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ChatThread>>(
          future: _threadsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final threads = snapshot.data ?? [];
            if (threads.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textGrey)),
                  SizedBox(height: 12),
                  Center(child: Text('No conversations yet', style: TextStyle(color: AppColors.textGrey))),
                  SizedBox(height: 4),
                  Center(child: Text('Message a seller from a product page to start', style: TextStyle(color: AppColors.textGrey, fontSize: 12))),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = threads[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: t.otherUserId, otherUserName: t.otherUserName)),
                    );
                    _refresh();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 24, backgroundColor: AppColors.primaryLight, child: Icon(Icons.store, color: AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.otherUserName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(t.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(DateFormat('d MMM').format(t.lastMessageAt), style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                            if (t.unreadCount > 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: Center(child: Text('${t.unreadCount}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
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