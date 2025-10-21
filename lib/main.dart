// main.dart'ın YENİ ve TEMİZ hali
import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // 1. Değişiklik: Yeni ekranımızı tanıttık

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Etkinlik Arkadaşı', 
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const HomeScreen(), // 2. Değişiklik: Artık bizim ekranımızı gösteriyor
      debugShowCheckedModeBanner: false,
    );
  }
}

// ARTIK ALTINDA BAŞKA KOD YOK, TERTEMİZ!