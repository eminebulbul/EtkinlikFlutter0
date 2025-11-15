import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/join_request_model.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();

  List<JoinRequestModel> _incoming = []; // Bana gelen istekler
  List<JoinRequestModel> _myRequests = []; // Benim gönderdiğim istekler

  bool _isLoading = true;
  String? _error;
  int? _currentUserId;
  String? _currentUserName;

  bool _showIncoming = true; // true: Gelenler, false: İsteklerim

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('auth_token');
      final userName = prefs.getString('user_name') ?? 'Kullanıcı';

      if (userIdStr == null || userIdStr.trim().isEmpty) {
        setState(() {
          _error = "Bildirimleri görmek için giriş yapmalısın.";
          _isLoading = false;
        });
        return;
      }

      final userId = int.tryParse(userIdStr) ?? 0;
      if (userId == 0) {
        setState(() {
          _error = "Kullanıcı bilgisi okunamadı.";
          _isLoading = false;
        });
        return;
      }

      final incoming = await _api.getIncomingRequests(userId);
      final myRequests =
          await _api.getAcceptedOutgoingRequests(userId); // artık tüm istekler

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
        _currentUserName = userName;
        _incoming = incoming;
        _myRequests = myRequests;
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

  Future<void> _respond(JoinRequestModel request, bool accept) async {
    try {
      await _api.respondToJoinRequest(
        requestId: request.id,
        accept: accept,
      );

      if (!mounted) return;

      setState(() {
        _incoming.removeWhere((r) => r.id == request.id);
      });

      // Kabul ettiyse, konuşma başlat ve DM'e git
      if (accept && _currentUserId != null) {
        final convId = await _api.startConversation(
          userAId: _currentUserId!,
          userAName: _currentUserName ?? 'Sen',
          userBId: request.fromUserId,
          userBName: request.fromUserName,
          eventId: request.eventId,
          eventTitle: request.eventTitle,
        );

        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              currentUserId: _currentUserId!,
              currentUserName: _currentUserName ?? 'Sen',
              otherUserId: request.fromUserId,
              otherUserName: request.fromUserName,
              eventTitle: request.eventTitle,
              conversationId: convId,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İstek yanıtlanamadı: $e")),
      );
    }
  }

  Widget _buildIncomingList(BuildContext context) {
    final theme = Theme.of(context);

    if (_incoming.isEmpty) {
      return Center(
        child: Text(
          "Şu anda bekleyen isteğin yok.",
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _incoming.length,
        itemBuilder: (context, index) {
          final r = _incoming[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.eventTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${r.fromUserName}, etkinliğine katılmak istiyor.",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _respond(r, false),
                        child: const Text("Reddet"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _respond(r, true),
                        child: const Text("Kabul Et"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyRequestsList(BuildContext context) {
    final theme = Theme.of(context);

    if (_myRequests.isEmpty) {
      return Center(
        child: Text(
          "Henüz herhangi bir etkinliğe istek göndermedin.",
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          final r = _myRequests[index];

          String statusText;
          Color statusColor;

          switch (r.status) {
            case "Accepted":
              statusText = "İsteğin kabul edildi.";
              statusColor = Colors.green;
              break;
            case "Rejected":
              statusText = "İsteğin reddedildi.";
              statusColor = Colors.red;
              break;
            default:
              statusText = "İsteğin gönderildi, yanıt bekleniyor.";
              statusColor = Colors.orange;
          }

          final canOpenChat = r.status == "Accepted";

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.eventTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (canOpenChat)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentUserId == null) return;

                          try {
                            final convId = await _api.startConversation(
                              userAId: _currentUserId!,
                              userAName: _currentUserName ?? 'Sen',
                              userBId: r.toUserId,
                              userBName: "Etkinlik Sahibi",
                              eventId: r.eventId,
                              eventTitle: r.eventTitle,
                            );

                            if (!context.mounted) return;

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  currentUserId: _currentUserId!,
                                  currentUserName:
                                      _currentUserName ?? 'Sen',
                                  otherUserId: r.toUserId,
                                  otherUserName: "Etkinlik Sahibi",
                                  eventTitle: r.eventTitle,
                                  conversationId: convId,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Mesaja gidilirken hata: $e"),
                              ),
                            );
                          }
                        },
                        child: const Text("Mesaja git"),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
                onPressed: _loadRequests,
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrar dene"),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showIncoming = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _showIncoming
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: const Text("Gelen istekler"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showIncoming = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: !_showIncoming
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: const Text("İsteklerim"),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _showIncoming
              ? _buildIncomingList(context)
              : _buildMyRequestsList(context),
        ),
      ],
    );
  }
}
