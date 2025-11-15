import 'package:flutter/material.dart';

import '../models/chat_message_model.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final String currentUserName;
  final int otherUserId;
  final String otherUserName;
  final String eventTitle;
  final int conversationId;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserId,
    required this.otherUserName,
    required this.eventTitle,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final msgs = await _api.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });

      // biraz aşağı kaydır
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    try {
      await _api.sendMessage(
        conversationId: widget.conversationId,
        fromUserId: widget.currentUserId,
        fromUserName: widget.currentUserName,
        text: text,
      );

      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mesaj gönderilemedi: $e")),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            Text(
              widget.eventTitle,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
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
                                onPressed: _loadMessages,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Tekrar dene"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final m = _messages[index];
                            final fromMe =
                                m.fromUserId == widget.currentUserId;

                            final align = fromMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft;
                            final color = fromMe
                                ? theme.colorScheme.primary.withOpacity(0.9)
                                : Colors.grey.shade300;
                            final textColor =
                                fromMe ? Colors.white : Colors.black87;

                            return Align(
                              alignment: align,
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  m.text,
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: "Mesaj yaz...",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
