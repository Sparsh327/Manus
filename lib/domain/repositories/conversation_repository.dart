import 'package:dartz/dartz.dart';
import 'package:manus/core/error/failure.dart';
import 'package:manus/domain/entities/conversation.dart';

abstract class ConversationRepository {
  Future<Either<Failure, List<Conversation>>> getAllConversations();

  Future<Either<Failure, Conversation>> createConversation({
    required String title,
  });

  Future<Either<Failure, void>> updateConversation(Conversation conversation);

  Future<Either<Failure, void>> deleteConversation(String id);

  // Returns conversations grouped for the drawer:
  // {"Today": [...], "Yesterday": [...], "Previous 7 Days": [...], "Older": [...]}
  Future<Either<Failure, Map<String, List<Conversation>>>> getGroupedConversations();

  Future<Either<Failure, void>> searchConversations(String query);
}
