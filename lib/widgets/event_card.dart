import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_model.dart';
import '../models/join_request_model.dart';
import '../services/api_service.dart';
import '../screens/user_profile_screen.dart';

class EventCard extends StatefulWidget {
  final EventModel event;
  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final ApiService _api = ApiService();

  int? _currentUserId;
  String _currentUserName = "Kullanıcı";

  JoinRequestModel? _request; // Bu etkinlik için benim isteğim (varsa)
  bool _buttonLoading = false;

  @override
  void initState() {
    super.initState();
    _initUserAndRequest();
  }

  Future<void> _initUserAndRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id') ??
        int.tryParse(prefs.getString('auth_token') ?? '') ??
        0;
    final name = prefs.getString('user_name') ?? "Kullanıcı";

    JoinRequestModel? existing;
    if (id != 0 && id != widget.event.organizerUserId) {
      try {
        existing = await _api.getMyJoinRequestForEvent(
          eventId: widget.event.id,
          userId: id,
        );
      } catch (_) {
        // sessiz geç
      }
    }

    if (!mounted) return;
    setState(() {
      _currentUserId = id;
      _currentUserName = name;
      _request = existing;
    });
  }

  String _formatDate(DateTime d) {
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');

    const aylar = [
      "Ocak",
      "Şubat",
      "Mart",
      "Nisan",
      "Mayıs",
      "Haziran",
      "Temmuz",
      "Ağustos",
      "Eylül",
      "Ekim",
      "Kasım",
      "Aralık"
    ];

    final ay = aylar[d.month - 1];
    return "${d.day} $ay $hour:$min";
  }

  Future<void> _onJoinButtonPressed() async {
    if (_currentUserId == null || _currentUserId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("İstek göndermek için önce giriş yapmalısın."),
        ),
      );
      return;
    }

    // 🔒 Kendi etkinliğine katılamazsın
    if (_currentUserId == widget.event.organizerUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kendi açtığın etkinliğe katılamazsın."),
        ),
      );
      return;
    }

    // Henüz istek yok → istek gönder
    if (_request == null) {
      setState(() {
        _buttonLoading = true;
      });

      try {
        final req = await _api.sendJoinRequest(
          eventId: widget.event.id,
          eventTitle: widget.event.title,
          fromUserId: _currentUserId!,
          fromUserName: _currentUserName,
          toUserId: widget.event.organizerUserId,
        );

        if (!mounted) return;

        setState(() {
          _request = req;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Katılma isteği gönderildi."),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("İstek gönderilemedi: $e")),
        );
      } finally {
        if (!mounted){
        setState(() {
          _buttonLoading = false;
        });
      }}

      return;
    }

    // Zaten bir istek var → eğer Pending ise iptal etme seçeneği
    if (_request!.status == "Pending") {
      setState(() {
        _buttonLoading = true;
      });

      try {
        await _api.cancelJoinRequest(_request!.id);

        if (!mounted) return;

        setState(() {
          _request = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Katılma isteğin geri çekildi."),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("İstek geri çekilemedi: $e")),
        );
      } finally {
        if (!mounted) {
        setState(() {
          _buttonLoading = false;
        });
      }
      }
      return;
    }

    // Accepted / Rejected ise, şimdilik sadece bilgilendirme yapalım
    if (_request!.status == "Accepted") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bu etkinlik için isteğin zaten kabul edildi."),
        ),
      );
    } else if (_request!.status == "Rejected") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bu etkinlik için isteğin reddedilmiş."),
        ),
      );
    }
  }

  void _openHostProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: widget.event.organizerUserId,
          userName: widget.event.hostName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String buttonText = "Katıl";
    bool buttonEnabled = true;

    if (_currentUserId != null &&
        _currentUserId != 0 &&
        _currentUserId == widget.event.organizerUserId) {
      buttonText = "Senin etkinliğin";
      buttonEnabled = false;
    } else if (_request == null) {
      buttonText = "Katıl";
      buttonEnabled = true;
    } else if (_request!.status == "Pending") {
      buttonText = "Katılma isteğini iptal et";
      buttonEnabled = true;
    } else if (_request!.status == "Accepted") {
      buttonText = "İstek kabul edildi";
      buttonEnabled = false;
    } else if (_request!.status == "Rejected") {
      buttonText = "İstek reddedildi";
      buttonEnabled = false;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üstte etkinlik resmi
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              widget.event.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Text(
                  widget.event.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Kaç kişi aranıyor + tarih
                Row(
                  children: [
                    Icon(Icons.group, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      "${widget.event.peopleNeeded} kişi aranıyor",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule,
                        size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(widget.event.date),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Konum
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.event.location,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Divider(),

                // Ev sahibi + Katıl butonu
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openHostProfile,
                      child: CircleAvatar(
                        radius: 18,
                        child: Text(
                          widget.event.hostName.isNotEmpty
                              ? widget.event.hostName[0].toUpperCase()
                              : "?",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _openHostProfile,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.hostName,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "Etkinliği oluşturan",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          (!_buttonLoading && buttonEnabled) ? _onJoinButtonPressed : null,
                      child: _buttonLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(buttonText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}