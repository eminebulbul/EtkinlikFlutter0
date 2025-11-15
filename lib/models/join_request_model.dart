class JoinRequestModel {
  final int id;
  final int eventId;
  final String eventTitle;
  final int fromUserId;
  final String fromUserName;
  final int toUserId;
  final String status;
  final DateTime createdAt;

  JoinRequestModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  factory JoinRequestModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return JoinRequestModel(
      id: parseInt(json['id']),
      eventId: parseInt(json['eventId']),
      eventTitle: json['eventTitle']?.toString() ?? '',
      fromUserId: parseInt(json['fromUserId']),
      fromUserName: json['fromUserName']?.toString() ?? '',
      toUserId: parseInt(json['toUserId']),
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
