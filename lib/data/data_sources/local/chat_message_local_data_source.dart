import 'package:hive/hive.dart';
import 'package:manus/core/error/exception.dart';
import 'package:manus/data/data_sources/local/hive_service.dart';
import 'package:manus/data/model/chat_message_model.dart';

abstract class ChatMessageLocalDataSource {
  List<ChatMessageModel> getMessages(String conversationId);
  void saveMessage(ChatMessageModel message);
  void updateMessage(ChatMessageModel message);
  void deleteMessagesFrom(String conversationId, int fromIndex);
  void deleteAllMessages(String conversationId);
}

class ChatMessageLocalDataSourceImpl implements ChatMessageLocalDataSource {
  final Box _box;

  ChatMessageLocalDataSourceImpl()
      : _box = Hive.box(HiveService.chatMessagesBox);

  // Key: conversationId → List of message JSON maps
  List<Map<String, dynamic>> _rawMessages(String conversationId) {
    final raw = _box.get(conversationId);
    if (raw == null) return [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  List<ChatMessageModel> getMessages(String conversationId) {
    try {
      return _rawMessages(conversationId)
          .map(ChatMessageModel.fromJson)
          .toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load messages: $e');
    }
  }

  @override
  void saveMessage(ChatMessageModel message) {
    try {
      final msgs = _rawMessages(message.conversationId);
      // Remove existing entry with same id (upsert)
      msgs.removeWhere((m) => m['id'] == message.id);
      msgs.add(message.toJson());
      _box.put(message.conversationId, msgs);
    } catch (e) {
      throw CacheException(message: 'Failed to save message: $e');
    }
  }

  @override
  void updateMessage(ChatMessageModel message) => saveMessage(message);

  @override
  void deleteMessagesFrom(String conversationId, int fromIndex) {
    try {
      final msgs = _rawMessages(conversationId);
      if (fromIndex >= msgs.length) return;
      _box.put(conversationId, msgs.sublist(0, fromIndex));
    } catch (e) {
      throw CacheException(message: 'Failed to delete messages: $e');
    }
  }

  @override
  void deleteAllMessages(String conversationId) {
    try {
      _box.delete(conversationId);
    } catch (e) {
      throw CacheException(message: 'Failed to delete messages: $e');
    }
  }
}
