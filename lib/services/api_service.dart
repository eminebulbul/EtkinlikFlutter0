import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart'; // en üst importlara eklemeyi unutma
import '../models/event_model.dart';
import '../models/join_request_model.dart';

const String baseUrl = "http://localhost:5221/api";

class LoginResult {
  final String token; // şimdilik userId string'i
  final int userId;
  final String name;

  LoginResult({
    required this.token,
    required this.userId,
    required this.name,
  });
}

class ApiService {
  /// GİRİŞ
  /// AuthController.Login -> body: { email, password }
  Future<LoginResult> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/Auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final user = data['user'] as Map<String, dynamic>?;
      final rawId = user?['id'];
      final rawName = user?['name'];

      int userId;
      if (rawId is int) {
        userId = rawId;
      } else {
        userId = int.tryParse(rawId?.toString() ?? '') ?? 0;
      }

      final name = rawName?.toString() ?? '';

      return LoginResult(
        token: userId.toString(),
        userId: userId,
        name: name,
      );
    }

    try {
      final data = jsonDecode(response.body);
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        throw Exception(message);
      }
    } catch (_) {}

    throw Exception("Giriş başarısız (status ${response.statusCode})");
  }

  /// KAYIT
  Future<void> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/Auth/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    try {
      final data = jsonDecode(response.body);
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        throw Exception(message);
      }
    } catch (_) {}

    throw Exception("Kayıt başarısız (status ${response.statusCode})");
  }

  /// ETKİNLİK LİSTESİ
  Future<List<EventModel>> getEvents() async {
    final url = Uri.parse('$baseUrl/Events');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((e) => EventModel.fromJson(e)).toList();
      }
      throw Exception("Beklenmeyen veri formatı (liste değil)");
    }

    throw Exception("Etkinlikler alınamadı (status ${response.statusCode})");
  }

  /// ETKİNLİK OLUŞTURMA
  Future<void> createEvent({
    required String title,
    required String imageUrl,
    required String peopleNeeded,
    required String hostName,
    required String hostImageUrl,
    required DateTime date,
    required String location,
    required int organizerUserId,
  }) async {
    final url = Uri.parse('$baseUrl/Events');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "title": title,
        "imageUrl": imageUrl,
        "peopleNeeded": peopleNeeded,
        "hostName": hostName,
        "hostImageUrl": hostImageUrl,
        "date": date.toIso8601String(),
        "location": location,
        "organizerUserId": organizerUserId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    try {
      final data = jsonDecode(response.body);
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        throw Exception(message);
      }
    } catch (_) {}

    throw Exception("Etkinlik oluşturulamadı (status ${response.statusCode})");
  }

  /// KATILIM İSTEĞİ GÖNDERME
  Future<void> sendJoinRequest({
    required int eventId,
    required String eventTitle,
    required int fromUserId,
    required String fromUserName,
    required int toUserId,
  }) async {
    final url = Uri.parse('$baseUrl/JoinRequests');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "eventId": eventId,
        "eventTitle": eventTitle,
        "fromUserId": fromUserId,
        "fromUserName": fromUserName,
        "toUserId": toUserId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    throw Exception("İstek gönderilemedi (status ${response.statusCode})");
  }

  /// İLAN SAHİBİ İÇİN GELEN İSTEKLER
  Future<List<JoinRequestModel>> getIncomingRequests(int userId) async {
    final url = Uri.parse('$baseUrl/JoinRequests/incoming/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((e) => JoinRequestModel.fromJson(e)).toList();
      }
      throw Exception("Beklenmeyen veri formatı (liste değil)");
    }

    throw Exception(
        "Gelen istekler alınamadı (status ${response.statusCode})");
  }

    /// KABUL EDİLEN GÖNDERDİĞİM İSTEKLER
    
  Future<List<JoinRequestModel>> getAcceptedOutgoingRequests(int userId) async {
    final url = Uri.parse('$baseUrl/JoinRequests/outgoing/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((e) => JoinRequestModel.fromJson(e)).toList();
      }
      throw Exception("Beklenmeyen veri formatı (liste değil)");
    }

    // Eğer nedense 404 dönerse, "hiç kabul edilmiş isteğim yok" gibi davran
    if (response.statusCode == 404) {
      return [];
    }

    throw Exception(
        "Kabul edilen istekler alınamadı (status ${response.statusCode})");
  }



  /// İSTEĞİ KABUL / REDDET
  Future<void> respondToJoinRequest({
    required int requestId,
    required bool accept,
  }) async {
    final url = Uri.parse('$baseUrl/JoinRequests/$requestId/respond');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"accept": accept}),
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(
        "İstek yanıtlanamadı (status ${response.statusCode})");
  }
    /// KONUŞMA BAŞLAT / BUL
  /// Aynı ikili + event için varsa onu döner, yoksa yeni conversation yaratır.
  Future<int> startConversation({
    required int userAId,
    required String userAName,
    required int userBId,
    required String userBName,
    required int eventId,
    required String eventTitle,
  }) async {
    final url = Uri.parse('$baseUrl/Conversations/start');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userAId": userAId,
        "userAName": userAName,
        "userBId": userBId,
        "userBName": userBName,
        "eventId": eventId,
        "eventTitle": eventTitle,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final idRaw = data['id'];
      if (idRaw is int) return idRaw;
      return int.tryParse(idRaw?.toString() ?? '') ?? 0;
    }

    throw Exception(
        "Konuşma başlatılamadı (status ${res.statusCode})");
  }

  /// MESAJ LİSTESİ
  Future<List<ChatMessageModel>> getMessages(int conversationId) async {
    final url = Uri.parse('$baseUrl/Conversations/$conversationId/messages');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded.map((e) => ChatMessageModel.fromJson(e)).toList();
      }
      throw Exception("Beklenmeyen veri formatı (liste değil)");
    }

    throw Exception(
        "Mesajlar alınamadı (status ${res.statusCode})");
  }

  /// MESAJ GÖNDER
  Future<void> sendMessage({
    required int conversationId,
    required int fromUserId,
    required String fromUserName,
    required String text,
  }) async {
    final url =
        Uri.parse('$baseUrl/Conversations/$conversationId/messages');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "fromUserId": fromUserId,
        "fromUserName": fromUserName,
        "text": text,
      }),
    );

    if (res.statusCode == 200) {
      return;
    }

    throw Exception(
        "Mesaj gönderilemedi (status ${res.statusCode})");
  }
}
