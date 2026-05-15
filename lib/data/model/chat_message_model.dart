import 'package:manus/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.role,
    required super.content,
    required super.status,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      role: MessageRole.values.byName(json['role'] as String),
      content: json['content'] as String,
      status: MessageStatus.values.byName(json['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'role': role.name,
        'content': content,
        'status': status.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory ChatMessageModel.fromEntity(ChatMessage m) => ChatMessageModel(
        id: m.id,
        conversationId: m.conversationId,
        role: m.role,
        content: m.content,
        status: m.status,
        createdAt: m.createdAt,
      );
}
