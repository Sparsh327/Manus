import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manus/data/data_sources/local/chat_message_local_data_source.dart';
import 'package:manus/data/data_sources/local/conversation_local_data_source.dart';
import 'package:manus/data/repositories/chat_message_repository_impl.dart';
import 'package:manus/data/repositories/conversation_repository_impl.dart';
import 'package:manus/domain/repositories/chat_message_repository.dart';
import 'package:manus/domain/repositories/conversation_repository.dart';

final conversationLocalDataSourceProvider =
    Provider<ConversationLocalDataSource>(
  (_) => ConversationLocalDataSourceImpl(),
);

final chatMessageLocalDataSourceProvider =
    Provider<ChatMessageLocalDataSource>(
  (_) => ChatMessageLocalDataSourceImpl(),
);

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepositoryImpl(
    ref.watch(conversationLocalDataSourceProvider),
  ),
);

final chatMessageRepositoryProvider = Provider<ChatMessageRepository>(
  (ref) => ChatMessageRepositoryImpl(
    ref.watch(chatMessageLocalDataSourceProvider),
  ),
);
