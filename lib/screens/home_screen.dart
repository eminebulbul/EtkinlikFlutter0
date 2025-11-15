import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../models/event_model.dart';
import '../widgets/event_card.dart';
import 'login_screen.dart';
import 'add_event_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  late Future<List<EventModel>> _futureEvents;

  int _currentIndex = 0; // 0: Etkinlikler, 1: Bildirimler, 2: Profil

  @override
  void initState() {
    super.initState();
    _futureEvents = _loadEvents();
  }

  Future<List<EventModel>> _loadEvents() async {
    return _api.getEvents();
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _futureEvents = _loadEvents();
    });
    await _futureEvents;
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildEventsBody(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: FutureBuilder<List<EventModel>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        "Etkinlikler yüklenirken bir hata oluştu.",
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refreshEvents,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Tekrar dene"),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    "Şu an listelenecek etkinlik yok.",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(event: event);
            },
          );
        },
      ),
    );
  }

  Widget _buildProfilePlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          "Profil sayfası için henüz geliştirme yapılmadı.\n\n"
          "Şu anda odak: etkinlikler, istekler ve DM akışı 😊",
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_currentIndex == 0) {
      body = _buildEventsBody(context);
    } else if (_currentIndex == 1) {
      body = const NotificationsScreen();
    } else {
      body = _buildProfilePlaceholder(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("MateVent"),
        actions: [
          IconButton(
            tooltip: "Çıkış yap",
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: body,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddEventScreen()),
                );
                if (result == true) {
                  _refreshEvents();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Etkinlikler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Bildirimler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
