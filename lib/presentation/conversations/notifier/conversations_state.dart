import 'package:manus/domain/entities/conversation.dart';

enum ConversationsFilter { all, agent, scheduled, favorites }

class ConversationsState {
  final List<Conversation> conversations;
  final ConversationsFilter filter;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const ConversationsState({
    this.conversations = const [],
    this.filter = ConversationsFilter.all,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  List<Conversation> get displayed {
    var list = conversations;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((c) => c.title.toLowerCase().contains(q)).toList();
    }
    // Agent / Scheduled / Favorites are stubs — show empty for now
    if (filter != ConversationsFilter.all) return [];
    return list;
  }

  ConversationsState copyWith({
    List<Conversation>? conversations,
    ConversationsFilter? filter,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
