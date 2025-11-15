class ChatMessageModel {
  final int id;
  final int conversationId;
  final int fromUserId;
  final String fromUserName;
  final String text;
  final DateTime sentAt;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.fromUserId,
    required this.fromUserName,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return ChatMessageModel(
      id: _parseInt(json['id']),
      conversationId: _parseInt(json['conversationId']),
      fromUserId: _parseInt(json['fromUserId']),
      fromUserName: json['fromUserName']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      sentAt:
          DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
