class RatingModel {
  final int id;
  final int targetUserId;
  final int fromUserId;
  final String fromUserName;
  final int score; // 1–5
  final String comment;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.targetUserId,
    required this.fromUserId,
    required this.fromUserName,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return RatingModel(
      id: parseInt(json['id']),
      targetUserId: parseInt(json['targetUserId']),
      fromUserId: parseInt(json['fromUserId']),
      fromUserName: json['fromUserName']?.toString() ?? '',
      score: parseInt(json['score']),
      comment: json['comment']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}
