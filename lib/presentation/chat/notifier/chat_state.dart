import 'package:manus/domain/entities/chat_message.dart';
import 'package:manus/domain/entities/conversation.dart';

enum ChatStatus { initial, loading, ready, streaming, error }

class ChatState {
  final ChatStatus status;
  final Conversation? conversation;
  final List<ChatMessage> messages;

  // Lives outside messages so only _StreamingBubble rebuilds per token.
  // Null when not streaming.
  final String? streamingContent;

  final String? error;

  const ChatState({
    this.status = ChatStatus.initial,
    this.conversation,
    this.messages = const [],
    this.streamingContent,
    this.error,
  });

  bool get isStreaming => status == ChatStatus.streaming;
  bool get isLoading => status == ChatStatus.loading;
  bool get hasError => status == ChatStatus.error;
  bool get hasMessages => messages.isNotEmpty || streamingContent != null;

  ChatState copyWith({
    ChatStatus? status,
    Conversation? conversation,
    List<ChatMessage>? messages,
    // Use explicit null sentinel so callers can clear streamingContent.
    Object? streamingContent = _absent,
    String? error,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      streamingContent: identical(streamingContent, _absent)
          ? this.streamingContent
          : streamingContent as String?,
      error: error ?? this.error,
    );
  }
}

// Sentinel used by copyWith to distinguish "not passed" from "null passed".
const Object _absent = Object();
