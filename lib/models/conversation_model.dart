class ConversationModel {
  final int id;
  final int userAId;
  final String userAName;
  final int userBId;
  final String userBName;
  final int eventId;
  final String eventTitle;
  final int otherUserId;
  final String otherUserName;
  final String lastMessageText;
  final DateTime lastMessageAt;

  ConversationModel({
    required this.id,
    required this.userAId,
    required this.userAName,
    required this.userBId,
    required this.userBName,
    required this.eventId,
    required this.eventTitle,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessageText,
    required this.lastMessageAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    DateTime parseDate(dynamic v) {
      return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    }

    return ConversationModel(
      id: parseInt(json['id']),
      userAId: parseInt(json['userAId']),
      userAName: json['userAName']?.toString() ?? '',
      userBId: parseInt(json['userBId']),
      userBName: json['userBName']?.toString() ?? '',
      eventId: parseInt(json['eventId']),
      eventTitle: json['eventTitle']?.toString() ?? '',
      otherUserId: parseInt(json['otherUserId']),
      otherUserName: json['otherUserName']?.toString() ?? '',
      lastMessageText: json['lastMessageText']?.toString() ?? '',
      lastMessageAt: parseDate(json['lastMessageAt']),
    );
  }
}