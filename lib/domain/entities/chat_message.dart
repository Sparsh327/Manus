import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

// sending   — user msg being persisted (brief, rarely visible)
// streaming — assistant msg receiving tokens
// complete  — final persisted message
// stopped   — user cancelled mid-stream (partial preserved)
// error     — network/API error on assistant turn
enum MessageStatus { sending, streaming, complete, stopped, error }

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  bool get isFromUser => role == MessageRole.user;
  bool get isFromAssistant => role == MessageRole.assistant;
  bool get isComplete => status == MessageStatus.complete;
  bool get isStopped => status == MessageStatus.stopped;
  bool get isError => status == MessageStatus.error;

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, conversationId, role, content, status, createdAt];
}
