import 'package:dartz/dartz.dart';
import 'package:manus/core/error/failure.dart';
import 'package:manus/domain/entities/chat_message.dart';

abstract class ChatMessageRepository {
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String conversationId,
  );

  Future<Either<Failure, void>> saveMessage(ChatMessage message);

  Future<Either<Failure, void>> updateMessage(ChatMessage message);

  // Deletes all messages at or after [fromIndex] in the conversation.
  // Used by edit-and-resend (fork point).
  Future<Either<Failure, void>> deleteMessagesFrom(
    String conversationId,
    int fromIndex,
  );

  Future<Either<Failure, void>> deleteAllMessages(String conversationId);
}
