import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../models/rating_model.dart';
import '../services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;

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
      // Tüm etkinlikleri ve bu kullanıcının gönderdiği istekleri al
      final eventsFuture = _api.getEvents();
      final outgoingFuture =
          _api.getAcceptedOutgoingRequests(widget.userId);
      final ratingsFuture = _api.getUserRatings(widget.userId);

      final allEvents = await eventsFuture;
      final outgoing = await outgoingFuture;
      List<RatingModel> ratings = [];
      try {
        ratings = await ratingsFuture;
      } catch (_) {
        ratings = [];
      }

      final created = allEvents
          .where((e) => e.organizerUserId == widget.userId)
          .toList();

      final acceptedReqs =
          outgoing.where((r) => r.status == "Accepted").toList();

      final Map<int, EventModel> eventById = {
        for (final e in allEvents) e.id: e,
      };

      final joined = <EventModel>[];
      for (final r in acceptedReqs) {
        final ev = eventById[r.eventId];
        if (ev != null) {
          joined.add(ev);
        }
      }

      double avg = 0.0;
      if (ratings.isNotEmpty) {
        avg = ratings
                .map((r) => r.score)
                .reduce((a, b) => a + b) /
            ratings.length;
      }

      if (!mounted) return;

      setState(() {
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(
            widget.userName.isNotEmpty
                ? widget.userName[0].toUpperCase()
                : "?",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Profil görüntüleme",
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final theme = Theme.of(context);

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
              value: _createdEvents.length.toString(),
            ),
            _buildStatItem(
              theme,
              label: "Katıldığı etkinlik",
              value: _joinedEvents.length.toString(),
            ),
            _buildStatItem(
              theme,
              label: "Puan",
              value: _ratings.isEmpty
                  ? "-"
                  : _averageRating.toStringAsFixed(1),
              extra: _ratings.isEmpty ? null : "(${_ratings.length})",
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
            onBackgroundImageError: (_, _) {},
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
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
                          onPressed: _loadProfile,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Tekrar dene"),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        _buildStatsCard(context),

                        _buildSectionTitle("Açtığı etkinlikler"),
                        _buildEventList(
                          _createdEvents,
                          "Bu kullanıcının açtığı etkinlik bulunmuyor.",
                        ),

                        _buildSectionTitle("Katıldığı etkinlikler"),
                        _buildEventList(
                          _joinedEvents,
                          "Bu kullanıcının katıldığı etkinlik bulunmuyor.",
                        ),

                        _buildSectionTitle("Bu kullanıcı hakkındaki puanlamalar"),
                        _buildRatingsList(),
                      ],
                    ),
                  ),
                ),
    );
  }
}