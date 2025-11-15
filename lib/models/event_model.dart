class EventModel {
  final int id;
  final String title;
  final String imageUrl;
  final String peopleNeeded;
  final String hostName;
  final String hostImageUrl;
  final DateTime date;
  final String location;
  final int organizerUserId;

  EventModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.peopleNeeded,
    required this.hostName,
    required this.hostImageUrl,
    required this.date,
    required this.location,
    required this.organizerUserId,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return EventModel(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      peopleNeeded: json['peopleNeeded']?.toString() ?? '',
      hostName: json['hostName']?.toString() ?? '',
      hostImageUrl: json['hostImageUrl']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      location: json['location']?.toString() ?? '',
      organizerUserId: parseInt(json['organizerUserId']),
    );
  }
}
