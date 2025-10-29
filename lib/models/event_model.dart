class EventModel {
  final int id;
  final String title;
  final String imageUrl;
  final String peopleNeeded;
  final String hostName;
  final String hostImageUrl;
  final DateTime date;
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

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json["id"] as int,
      title: json["title"] ?? "",
      imageUrl: json["imageUrl"] ?? "",
      peopleNeeded: json["peopleNeeded"] ?? "",
      hostName: json["hostName"] ?? "",
      hostImageUrl: json["hostImageUrl"] ?? "",
      date: DateTime.parse(json["date"].toString()),
      location: json["location"] ?? "",
    );
  }
}
