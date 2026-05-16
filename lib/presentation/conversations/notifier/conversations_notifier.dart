import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manus/data/providers/chat_data_providers.dart';
import 'package:manus/presentation/conversations/notifier/conversations_state.dart';

final conversationsProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(
      ConversationsNotifier.new,
    );

class ConversationsNotifier extends Notifier<ConversationsState> {
  @override
  ConversationsState build() {
    Future.microtask(loadConversations);
    return const ConversationsState(isLoading: true);
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true);
    final result = await ref
        .read(conversationRepositoryProvider)
        .getAllConversations();
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (conversations) => state = state.copyWith(
        isLoading: false,
        conversations: conversations,
        error: null,
      ),
    );
  }

  void setFilter(ConversationsFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // Returns the new conversation ID, or null on failure.
  Future<String?> createConversation() async {
    final result = await ref
        .read(conversationRepositoryProvider)
        .createConversation(title: 'New conversation');
    return result.fold((_) => null, (conv) {
      state = state.copyWith(conversations: [conv, ...state.conversations]);
      return conv.id;
    });
  }

  Future<void> deleteConversation(String id) async {
    await ref.read(conversationRepositoryProvider).deleteConversation(id);
    state = state.copyWith(
      conversations: state.conversations.where((c) => c.id != id).toList(),
    );
  }

  Future<void> pinConversation(String id, {required bool pinned}) async {
    final conv = state.conversations.firstWhere((c) => c.id == id);
    final updated = conv.copyWith(isPinned: pinned, updatedAt: DateTime.now());
    await ref.read(conversationRepositoryProvider).updateConversation(updated);
    state = state.copyWith(
      conversations: state.conversations
          .map((c) => c.id == id ? updated : c)
          .toList(),
    );
  }

  Future<void> renameConversation(String id, String newTitle) async {
    final conv = state.conversations.firstWhere((c) => c.id == id);
    final updated = conv.copyWith(title: newTitle, updatedAt: DateTime.now());
    await ref.read(conversationRepositoryProvider).updateConversation(updated);
    state = state.copyWith(
      conversations: state.conversations
          .map((c) => c.id == id ? updated : c)
          .toList(),
    );
  }

  // Called by ChatNotifier after the first message to rename from default title.
  Future<void> refreshConversation(String id) async {
    await loadConversations();
  }
}
