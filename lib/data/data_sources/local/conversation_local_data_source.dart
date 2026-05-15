import 'package:hive/hive.dart';
import 'package:manus/core/error/exception.dart';
import 'package:manus/data/data_sources/local/hive_service.dart';
import 'package:manus/data/model/conversation_model.dart';

abstract class ConversationLocalDataSource {
  List<ConversationModel> getAll();
  void save(ConversationModel conversation);
  void delete(String id);
}

class ConversationLocalDataSourceImpl implements ConversationLocalDataSource {
  final Box _box;

  ConversationLocalDataSourceImpl()
      : _box = Hive.box(HiveService.conversationsBox);

  @override
  List<ConversationModel> getAll() {
    try {
      final raw = _box.values.toList();
      return raw
          .map((e) => ConversationModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList()
        ..sort((a, b) {
          // Pinned first, then by updatedAt descending
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
    } catch (e) {
      throw CacheException(message: 'Failed to load conversations: $e');
    }
  }

  @override
  void save(ConversationModel conversation) {
    try {
      _box.put(conversation.id, conversation.toJson());
    } catch (e) {
      throw CacheException(message: 'Failed to save conversation: $e');
    }
  }

  @override
  void delete(String id) {
    try {
      _box.delete(id);
    } catch (e) {
      throw CacheException(message: 'Failed to delete conversation: $e');
    }
  }
}
