class ChatMsg {
  final int id;
  final String user;
  final String createdAt;
  final String message;
  final String conversationId;

  const ChatMsg(
      {required this.id,
      required this.user,
      required this.createdAt,
      required this.message,
      required this.conversationId});

  factory ChatMsg.fromJson(Map<String, dynamic> json) => ChatMsg(
      id: json['id'],
      user: json['user'],
      createdAt: json['createdAt'],
      message: json['message'],
      conversationId: json['conversationId']);

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user,
        'createdAt': createdAt,
        'message': message,
        'conversationId': conversationId
      };
}
