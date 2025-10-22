// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../widgets/event_card.dart';
import 'login_screen.dart'; // 1. YENİ İMPORT: Çıkış yapınca yönlendirmek için

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<EventModel>> futureEvents;
  final ApiService _apiService = ApiService(); // 2. ApiService nesnesi

  @override
  void initState() {
    super.initState();
    // 3. _apiService üzerinden çağır
    futureEvents = _apiService.fetchEvents();
  }

  // 4. YENİ FONKSİYON: Çıkış Yap
  void _logout() async {
    await _apiService.logout(); // Token'ı sil
    
    if (mounted) {
      // LoginScreen'e geri dön ve Ana Sayfa'yı yığından kaldır
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.red),
            SizedBox(width: 8),
            Text('Ankara, Çankaya'),
          ],
        ),
        actions: [ // 'actions' listesini güncelledim
          // 5. YENİ BUTON: Çıkış Yap Butonu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Çıkış Yap',
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      body: FutureBuilder<List<EventModel>>(
        future: futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // ... (Hata yönetimi aynı) ...
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Bir hata oluştu:\n${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // ... (ListView aynı) ...
            final events = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: events.length,
              itemBuilder: (BuildContext context, int index) {
                return EventCard(event: events[index]);
              },
            );
          } else {
            return const Center(child: Text('Gösterilecek etkinlik bulunamadı.'));
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        // ... (BottomNavigationBar aynı) ...
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Mesajlar'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favoriler'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Etkinliklerim'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}