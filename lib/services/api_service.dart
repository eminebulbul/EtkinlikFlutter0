import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

const String baseUrl = "http://localhost:5221/api";

class ApiService {
  Future<bool> login(String email, String password) async {
      final url = Uri.parse('$baseUrl/auth/login'); // küçük harfli olmalı

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("✅ Login başarılı: $decoded");
        return true;
      } else {
        print("❌ Login başarısız: ${response.body}");
        return false;
      }
    }


  Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Register failed: ${response.body}');
      return false;
    }
  }

  Future<List<EventModel>> getEvents() async {
    final url = Uri.parse('$baseUrl/Events');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((e) => EventModel.fromJson(e)).toList();
      }
    }
    throw Exception("Etkinlikler alınamadı (status ${response.statusCode})");
  }
}
