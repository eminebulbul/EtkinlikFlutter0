import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../models/event_model.dart';
import '../models/rating_model.dart';
import 'profile_edit_screen.dart';
import '../models/join_request_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;

  String _userName = "Kullanıcı";
  String? _profileImageUrl;
  String? _bio;

  List<EventModel> _createdEvents = [];
  List<EventModel> _joinedEvents = [];

  List<RatingModel> _ratings = [];
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final id =
          prefs.getInt('user_id') ??
              int.tryParse(prefs.getString('auth_token') ?? '') ??
              0;

      if (id == 0) {
        setState(() {
          _error = "Profil bilgileri için önce giriş yapmalısın.";
          _isLoading = false;
        });
        return;
      }

      final name = prefs.getString('user_name') ?? "Kullanıcı";
      final bio = prefs.getString('profile_bio');
      final avatar = prefs.getString('profile_image_url');

      // API çağrılarını paralel alalım
      final eventsFuture = _api.getEvents();
      final myRequestsFuture = _api.getAcceptedOutgoingRequests(id);
      final ratingsFuture = _api.getUserRatings(id);

      final List<EventModel> allEvents = await eventsFuture;
      final List<JoinRequestModel> myRequests = await myRequestsFuture;
      List<RatingModel> ratings = [];
      try {
        ratings = await ratingsFuture;
      } catch (_) {
        ratings = [];
      }

      // Açtığı etkinlikler
      final created = allEvents
          .where((e) => e.organizerUserId == id)
          .toList();

      // Katıldığı etkinlikler: Accepted join request'ler
      final acceptedRequests = myRequests
          .where((r) => r.status == "Accepted")
          .toList();

      final Map<int, EventModel> eventById = {
        for (final e in allEvents) e.id: e,
      };

      final joined = <EventModel>[];
      for (final r in acceptedRequests) {
        final ev = eventById[r.eventId];
        if (ev != null) {
          joined.add(ev);
        }
      }

      // Rating ortalaması
      double avg = 0.0;
      if (ratings.isNotEmpty) {
        avg = ratings.map((r) => r.score).reduce((a, b) => a + b) /
            ratings.length;
      }

      if (!mounted) return;

      setState(() {
        _userName = name;
        _bio = bio;
        _profileImageUrl = avatar;
        _createdEvents = created;
        _joinedEvents = joined;
        _ratings = ratings;
        _averageRating = avg;
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

  void _openEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ProfileEditScreen(),
      ),
    );

    if (updated == true) {
      _loadProfile();
    }
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: (_profileImageUrl != null &&
                  _profileImageUrl!.trim().isNotEmpty)
              ? NetworkImage(_profileImageUrl!)
              : null,
          child: (_profileImageUrl == null ||
                  _profileImageUrl!.trim().isEmpty)
              ? Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : "?",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (_bio != null && _bio!.trim().isNotEmpty)
                Text(
                  _bio!,
                  style: theme.textTheme.bodyMedium,
                )
              else
                Text(
                  "Kendin hakkında kısa bir bio ekleyebilirsin.",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: "Profili düzenle",
          onPressed: _openEditProfile,
          icon: const Icon(Icons.edit),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final theme = Theme.of(context);
    final createdCount = _createdEvents.length;
    final joinedCount = _joinedEvents.length;
    final ratingCount = _ratings.length;

    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              theme,
              label: "Açtığı etkinlik",
              value: createdCount.toString(),
            ),
            _buildStatItem(
              theme,
              label: "Katıldığı etkinlik",
              value: joinedCount.toString(),
            ),
            _buildStatItem(
              theme,
              label: "Puan",
              value: ratingCount == 0
                  ? "-"
                  : _averageRating.toStringAsFixed(1),
              extra: ratingCount == 0 ? null : "($ratingCount)",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required String label,
    required String value,
    String? extra,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (extra != null) ...[
          const SizedBox(height: 2),
          Text(
            extra,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey.shade700),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildEventList(List<EventModel> events, String emptyText) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(
          emptyText,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return Column(
      children: events.map((e) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: NetworkImage(e.imageUrl),
            onBackgroundImageError: (error, stackTrace) {},
          ),
          title: Text(e.title),
          subtitle: Text(e.location),
        );
      }).toList(),
    );
  }

  Widget _buildRatingsList() {
    if (_ratings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        child: Text(
          "Bu kullanıcı için henüz puanlama yapılmamış.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return Column(
      children: _ratings.map((r) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Text(
              r.fromUserName.isNotEmpty
                  ? r.fromUserName[0].toUpperCase()
                  : "?",
            ),
          ),
          title: Text(r.fromUserName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (index) {
                  final filled = index < r.score;
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 16,
                    color: filled ? Colors.amber : Colors.grey,
                  );
                }),
              ),
              if (r.comment.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    r.comment,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrar dene"),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildStatsCard(context),

            _buildSectionTitle("Açtığın etkinlikler"),
            _buildEventList(
              _createdEvents,
              "Henüz bir etkinlik açmamışsın.",
            ),

            _buildSectionTitle("Katıldığın etkinlikler"),
            _buildEventList(
              _joinedEvents,
              "Henüz katıldığın etkinlik yok.",
            ),

            _buildSectionTitle("Senin hakkındaki puanlamalar"),
            _buildRatingsList(),
          ],
        ),
      ),
    );
  }
}
