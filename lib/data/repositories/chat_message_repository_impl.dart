import 'package:dartz/dartz.dart';
import 'package:manus/core/error/exception.dart';
import 'package:manus/core/error/failure.dart';
import 'package:manus/data/data_sources/local/chat_message_local_data_source.dart';
import 'package:manus/data/model/chat_message_model.dart';
import 'package:manus/domain/entities/chat_message.dart';
import 'package:manus/domain/repositories/chat_message_repository.dart';

class ChatMessageRepositoryImpl implements ChatMessageRepository {
  final ChatMessageLocalDataSource _local;

  ChatMessageRepositoryImpl(this._local);

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String conversationId,
  ) async {
    try {
      return Right(_local.getMessages(conversationId));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> saveMessage(ChatMessage message) async {
    try {
      _local.saveMessage(ChatMessageModel.fromEntity(message));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateMessage(ChatMessage message) async {
    try {
      _local.updateMessage(ChatMessageModel.fromEntity(message));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessagesFrom(
    String conversationId,
    int fromIndex,
  ) async {
    try {
      _local.deleteMessagesFrom(conversationId, fromIndex);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllMessages(String conversationId) async {
    try {
      _local.deleteAllMessages(conversationId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
