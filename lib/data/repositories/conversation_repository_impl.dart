import 'package:dartz/dartz.dart';
import 'package:manus/core/error/exception.dart';
import 'package:manus/core/error/failure.dart';
import 'package:manus/data/data_sources/local/conversation_local_data_source.dart';
import 'package:manus/data/model/conversation_model.dart';
import 'package:manus/domain/entities/conversation.dart';
import 'package:manus/domain/repositories/conversation_repository.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationLocalDataSource _local;

  ConversationRepositoryImpl(this._local);

  @override
  Future<Either<Failure, List<Conversation>>> getAllConversations() async {
    try {
      return Right(_local.getAll());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Conversation>> createConversation({
    required String title,
  }) async {
    try {
      final now = DateTime.now();
      final model = ConversationModel(
        id: _generateId(),
        title: title,
        createdAt: now,
        updatedAt: now,
      );
      _local.save(model);
      return Right(model);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateConversation(
    Conversation conversation,
  ) async {
    try {
      _local.save(ConversationModel.fromEntity(conversation));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversation(String id) async {
    try {
      _local.delete(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<Conversation>>>>
      getGroupedConversations() async {
    try {
      final all = _local.getAll().where((c) => !c.isArchived).toList();
      return Right(_groupByDate(all));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> searchConversations(String query) async {
    // Filtering is done in-memory — no separate impl needed
    return const Right(null);
  }

  // ── Helpers ────────────────────────────────────────────────

  Map<String, List<Conversation>> _groupByDate(List<Conversation> all) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final sevenDaysStart = todayStart.subtract(const Duration(days: 7));

    final today = <Conversation>[];
    final yesterday = <Conversation>[];
    final prev7 = <Conversation>[];
    final older = <Conversation>[];

    for (final c in all) {
      if (c.updatedAt.isAfter(todayStart)) {
        today.add(c);
      } else if (c.updatedAt.isAfter(yesterdayStart)) {
        yesterday.add(c);
      } else if (c.updatedAt.isAfter(sevenDaysStart)) {
        prev7.add(c);
      } else {
        older.add(c);
      }
    }

    return {
      if (today.isNotEmpty) 'Today': today,
      if (yesterday.isNotEmpty) 'Yesterday': yesterday,
      if (prev7.isNotEmpty) 'Previous 7 Days': prev7,
      if (older.isNotEmpty) 'Older': older,
    };
  }

  String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
}
