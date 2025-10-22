// lib/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart'; // ApiService'i import ediyoruz

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Kontrol işlemi için bir Future tanımlıyoruz
  late Future<bool> _checkTokenFuture;

  @override
  void initState() {
    super.initState();
    // ApiService'teki yeni hasToken() fonksiyonumuzu çağırıyoruz
    _checkTokenFuture = ApiService().hasToken();
  }

  @override
  Widget build(BuildContext context) {
    // Bu FutureBuilder, _checkTokenFuture'dan cevap gelene kadar bekler
    return FutureBuilder<bool>(
      future: _checkTokenFuture,
      builder: (context, snapshot) {
        // 1. Durum: Henüz cevap gelmedi, beklemedeyiz.
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Basit bir yüklenme ekranı göster
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. Durum: Cevap geldi ve 'true' (yani token var)
        if (snapshot.hasData && snapshot.data == true) {
          // Ana Ekrana (HomeScreen) yönlendir
          return const HomeScreen();
        }

        // 3. Durum: Cevap 'false' (token yok) veya hata oluştu
        // Giriş Ekranına (LoginScreen) yönlendir
        return const LoginScreen();
      },
    );
  }
}