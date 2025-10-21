// lib/models/event_model.dart

class EventModel {
  final int id;
  final String title;
  final String imageUrl;
  final String peopleNeeded;
  final String hostName;
  final String hostImageUrl;
  final String date; // Tarihi şimdilik String olarak alıyoruz
  final String location;

  EventModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.peopleNeeded,
    required this.hostName,
    required this.hostImageUrl,
    required this.date,
    required this.location,
  });

  // Gelen JSON verisini EventModel nesnesine çeviren metot
  factory EventModel.fromJson(Map<String, dynamic> json) {
    // C#'taki DateTime formatını "Yıl-Ay-Gün Saat:Dakika" şeklinde daha okunaklı yapıyoruz
    String formattedDate = DateTime.parse(json['date']).toString().substring(0, 16).replaceAll('T', ' ');

    return EventModel(
      id: json['id'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      peopleNeeded: json['peopleNeeded'],
      hostName: json['hostName'],
      hostImageUrl: json['hostImageUrl'],
      date: formattedDate,
      location: json['location'],
    );
  }
}