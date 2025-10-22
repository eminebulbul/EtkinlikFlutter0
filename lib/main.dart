// main.dart'ın GÜNCELLENMİŞ hali

import 'package:etkinlik/screens/home_screen.dart';

import 'package:flutter/material.dart';
// 1. Değişiklik: Artık LoginScreen'i import ediyoruz
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MateVent', // Proje adına güncelledim
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      // 2. Değişiklik: Artık doğrudan HomeScreen'i değil, LoginScreen'i gösteriyoruz.
    
      // HomeScreen'e, yoksa LoginScreen'e yönlendirme yapacağız.

      home: const HomeScreen(), 

      debugShowCheckedModeBanner: false,
    );
  }
}