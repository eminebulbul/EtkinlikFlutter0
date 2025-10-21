// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class ApiService {
  // !!! DİKKAT !!!
  // Buradaki 5123 port numarasını, kendi .NET projendeki
  // Properties/launchSettings.json dosyasında bulduğun http portu ile DEĞİŞTİR.
  final String apiUrl = "http://10.0.2.2:5251/api/Events";

  Future<List<EventModel>> fetchEvents() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

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
}