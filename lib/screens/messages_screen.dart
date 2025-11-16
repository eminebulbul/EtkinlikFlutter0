import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation_model.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;

  int? _currentUserId;
  String _currentUserName = "Sen";

  List<ConversationModel> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id') ??
          int.tryParse(prefs.getString('auth_token') ?? '') ??
          0;
      final name = prefs.getString('user_name') ?? "Sen";

      if (id == 0) {
        setState(() {
          _error = "Mesajlarını görmek için giriş yapmalısın.";
          _isLoading = false;
        });
        return;
      }

      final convs = await _api.getUserConversations(id);

      if (!mounted) return;

      setState(() {
        _currentUserId = id;
        _currentUserName = name;
        _conversations = convs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return "$h:$m";
    }
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mesajlarım"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadConversations,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Tekrar dene"),
                        ),
                      ],
                    ),
                  ),
                )
              : _conversations.isEmpty
                  ? Center(
                      child: Text(
                        "Henüz hiç mesajın yok.",
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final c = _conversations[index];

                          return Card(
                            child: ListTile(
                              onTap: () {
                                if (_currentUserId == null) return;

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      currentUserId: _currentUserId!,
                                      currentUserName: _currentUserName,
                                      otherUserId: c.otherUserId,
                                      otherUserName: c.otherUserName,
                                      eventTitle: c.eventTitle,
                                      conversationId: c.id,
                                    ),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                child: Text(
                                  c.otherUserName.isNotEmpty
                                      ? c.otherUserName[0].toUpperCase()
                                      : "?",
                                ),
                              ),
                              title: Text(c.otherUserName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.eventTitle,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.lastMessageText.isEmpty
                                        ? "Henüz mesaj yok."
                                        : c.lastMessageText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              trailing: Text(
                                _formatTime(c.lastMessageAt),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}