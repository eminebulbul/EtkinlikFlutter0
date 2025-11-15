import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_model.dart';
import '../services/api_service.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  const EventCard({super.key, required this.event});

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

  Future<void> _handleJoin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    // user_id int, auth_token da string olarak userId
    final userId = prefs.getInt('user_id') ??
        int.tryParse(prefs.getString('auth_token') ?? '') ??
        0;
    final userName = prefs.getString('user_name') ?? 'Kullanıcı';

    if (userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("İstek göndermek için önce giriş yapmalısın."),
        ),
      );
      return;
    }

    // 🔒 Kendi etkinliğine katılamazsın
    if (userId == event.organizerUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kendi açtığın etkinliğe katılamazsın."),
        ),
      );
      return;
    }

    final api = ApiService();

    try {
      await api.sendJoinRequest(
        eventId: event.id,
        eventTitle: event.title,
        fromUserId: userId,
        fromUserName: userName,
        toUserId: event.organizerUserId,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Etkinlik sahibine istek gönderildi."),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("İstek gönderilemedi: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              event.imageUrl,
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
                  event.title,
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
                      "${event.peopleNeeded} kişi aranıyor",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule,
                        size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(event.date),
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
                        event.location,
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
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(event.hostImageUrl),
                      onBackgroundImageError: (error, stackTrace) {},
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.hostName,
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
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleJoin(context),
                      child: const Text("Katıl"),
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
