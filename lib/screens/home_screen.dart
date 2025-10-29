import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';
import '../widgets/event_card.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  late Future<List<EventModel>> _futureEvents;
  String? _token;
  int _selectedIndex = 2;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureEvents = _api.getEvents();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('auth_token');
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Etkinlikler"),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Çıkış yap",
          ),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔍 Arama ve Filtre Barı
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Etkinlik ara...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      // İleriye dönük filtreleme sayfası
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Filtre özelliği yakında :)")),
                      );
                    },
                    icon: const Icon(Icons.filter_list),
                  ),
                ],
              ),
            ),

            // 🧩 Etkinlik listesi
            Expanded(
              child: FutureBuilder<List<EventModel>>(
                future: _futureEvents,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Hata: ${snapshot.error}"),
                    );
                  }

                  final events = snapshot.data ?? [];
                  final filtered = events
                      .where((e) =>
                          e.title.toLowerCase().contains(_searchQuery) ||
                          e.location.toLowerCase().contains(_searchQuery))
                      .toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("Hiç etkinlik bulunamadı 😢"));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return EventCard(event: filtered[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 🔻 Alt Navigasyon Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Keşfet'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favoriler'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Bildirimler'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profilim'),
        ],
      ),
    );
  }
}
