// lib/services/api_service.dart

import 'dart:convert';
// 1. YENİ IMPORT: debugPrint için bu paket gerekli
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = "http://localhost:5221/api";
class ApiService {
  final String _baseUrl = baseUrl; 
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // YENİ FONKSİYON: Token var mı diye hızlıca bak
  Future<bool> hasToken() async {
    String? token = await _storage.read(key: 'auth_token');
    // Token null değilse VE boş değilse true döner
    return token != null && token.isNotEmpty;
  }
  
  // YENİ FONKSİYON: Çıkış yaparken token'ı sil
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<List<EventModel>> fetchEvents() async {
    // ... (fetchEvents fonksiyonun aynı kalabilir) ...
    try {
      final token = await _getToken(); 
      
      final response = await http.get(
        Uri.parse("$_baseUrl/Events")
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<EventModel> events =
            body.map((dynamic item) => EventModel.fromJson(item)).toList();
        return events;
      } else {
        throw Exception('API\'den veri yüklenemedi. Hata Kodu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı. Backend\'in çalıştığından emin misin?: $e');
    }
  }

  Future<bool> register(String username, String email, String password) async {
    try {
      // ... (register fonksiyonunun içeriği aynı) ...
      final response = await http.post(
        Uri.parse("$_baseUrl/Auth/Register"), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;

    } catch (e) {
      // 2. DEĞİŞİKLİK: 'print' yerine 'debugPrint'
      debugPrint('Register API Hatası: ${e.toString()}'); 
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // ... (login fonksiyonunun içeriği aynı) ...
      final response = await http.post(
        Uri.parse("$_baseUrl/Auth/Login"), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        String token = responseBody['token']; 
        await _storage.write(key: 'auth_token', value: token);
        return true;
      } else {
        return false;
      }

    } catch (e) {
      // 3. DEĞİŞİKLİK: 'print' yerine 'debugPrint'
      debugPrint('Login API Hatası: ${e.toString()}');
      return false;
    }
  }
}