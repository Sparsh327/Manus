import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manus/core/providers/core_providers.dart';
import 'package:manus/data/data_sources/remote/gemini/gemini_service.dart';
import 'package:manus/data/providers/chat_data_providers.dart';
import 'package:manus/domain/entities/chat_message.dart';
import 'package:manus/domain/entities/conversation.dart';
import 'package:manus/presentation/chat/notifier/chat_state.dart';
import 'package:manus/presentation/conversations/notifier/conversations_notifier.dart';

final chatProvider = NotifierProvider.family<ChatNotifier, ChatState, String>(
  ChatNotifier.new,
);

class ChatNotifier extends FamilyNotifier<ChatState, String> {
  // arg is conversationId
  CancelToken? _cancelToken;
  StreamSubscription<String>? _streamSub;

  @override
  ChatState build(String arg) {
    ref.onDispose(_cleanup);
    Future.microtask(() => _loadConversation(arg));
    return const ChatState();
  }

  // ── Public API ───────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final logger = ref.read(loggerProvider);
    final conversation = state.conversation;
    if (conversation == null) return;

    final isFirstMessage =
        state.messages.isEmpty && conversation.title == 'New conversation';

    // Snapshot history BEFORE adding new messages to state — correct context.
    final prevHistory = _buildHistory();

    final userMsg = _buildMessage(
      conversation.id,
      MessageRole.user,
      trimmed,
      MessageStatus.complete,
    );
    final assistantMsg = _buildMessage(
      conversation.id,
      MessageRole.assistant,
      '',
      MessageStatus.streaming,
    );

    // ⚡ OPTIMISTIC — update UI immediately, before any I/O.
    // User bubble + thinking indicator appear in the same frame as the tap.
    state = state.copyWith(
      status: ChatStatus.streaming,
      messages: [...state.messages, userMsg, assistantMsg],
      streamingContent: '',
    );

    // Fire-and-forget I/O — never block the stream start.
    _persistMessage(userMsg)
        .catchError((Object e) => logger.error('persist user msg failed', e));
    _updateConversationMeta(conversation, trimmed, isFirstMessage)
        .catchError((Object e) => logger.error('update meta failed', e));

    // Start Gemini stream immediately after UI update.
    _cancelToken = CancelToken();
    final gemini = ref.read(geminiServiceProvider);
    var accumulated = '';

    try {
      final stream = gemini.streamResponse(
        prompt: trimmed,
        history: prevHistory,
        cancelToken: _cancelToken!,
      );

      _streamSub = stream.listen(
        (token) {
          accumulated += token;
          state = state.copyWith(streamingContent: accumulated);
        },
        onDone: () => _finalizeStream(assistantMsg.id, accumulated),
        onError: (Object e) {
          if (e is DioException && CancelToken.isCancel(e)) {
            _finalizeStream(assistantMsg.id, accumulated, stopped: true);
          } else {
            logger.error('Gemini stream error', e);
            _markStreamError(assistantMsg.id, accumulated);
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      logger.error('Failed to start Gemini stream', e);
      _markStreamError(assistantMsg.id, accumulated);
    }
  }

  Future<void> _updateConversationMeta(
    Conversation conversation,
    String firstText,
    bool isFirstMessage,
  ) async {
    if (isFirstMessage) {
      final autoTitle =
          firstText.length > 45 ? '${firstText.substring(0, 45)}…' : firstText;
      final renamed = conversation.copyWith(
        title: autoTitle,
        updatedAt: DateTime.now(),
      );
      await ref
          .read(conversationRepositoryProvider)
          .updateConversation(renamed);
      state = state.copyWith(conversation: renamed);
      ref
          .read(conversationsProvider.notifier)
          .refreshConversation(renamed.id);
    } else {
      await _touchConversation(conversation);
    }
  }

  Future<void> stopStream() async {
    _cancelToken?.cancel('User stopped');
  }

  /// Truncates history to [fromIndex] (exclusive) and re-sends [newText].
  Future<void> editAndResend(int messageIndex, String newText) async {
    await _cleanup();
    final conversation = state.conversation;
    if (conversation == null) return;

    // Delete persisted messages from [messageIndex] onward.
    await ref
        .read(chatMessageRepositoryProvider)
        .deleteMessagesFrom(conversation.id, messageIndex);

    state = state.copyWith(
      status: ChatStatus.ready,
      messages: state.messages.sublist(0, messageIndex),
      streamingContent: null,
    );

    await sendMessage(newText);
  }

  Future<void> retryLast() async {
    final msgs = state.messages;
    if (msgs.isEmpty) return;
    // Find the last user message.
    final lastUserIdx = msgs.lastIndexWhere((m) => m.role == MessageRole.user);
    if (lastUserIdx == -1) return;
    await editAndResend(lastUserIdx, msgs[lastUserIdx].content);
  }

  // ── Private ──────────────────────────────────────────────────

  Future<void> _loadConversation(String conversationId) async {
    state = state.copyWith(status: ChatStatus.loading);

    final convRepo = ref.read(conversationRepositoryProvider);
    final msgRepo = ref.read(chatMessageRepositoryProvider);

    final convResult = await convRepo.getAllConversations();
    final Conversation? conversation = convResult.fold(
      (_) => null,
      (list) => list.where((c) => c.id == conversationId).firstOrNull,
    );

    if (conversation == null) {
      state = state.copyWith(
        status: ChatStatus.error,
        error: 'Conversation not found',
      );
      return;
    }

    final msgsResult = await msgRepo.getMessages(conversationId);
    final messages = msgsResult.fold((_) => <ChatMessage>[], (m) => m);

    state = state.copyWith(
      status: ChatStatus.ready,
      conversation: conversation,
      messages: messages,
    );
  }

  Future<void> _finalizeStream(
    String assistantMsgId,
    String content, {
    bool stopped = false,
  }) async {
    final status = stopped ? MessageStatus.stopped : MessageStatus.complete;
    final updatedMsgs = state.messages.map((m) {
      if (m.id == assistantMsgId) {
        return m.copyWith(content: content, status: status);
      }
      return m;
    }).toList();

    state = state.copyWith(
      status: ChatStatus.ready,
      messages: updatedMsgs,
      streamingContent: null,
    );

    // Persist the finalized assistant message.
    final finalMsg = updatedMsgs.firstWhere((m) => m.id == assistantMsgId);
    await _persistMessage(finalMsg);

    // Save last message preview to conversation for history screen.
    final conv = state.conversation;
    if (conv != null && content.isNotEmpty) {
      final preview =
          content.length > 80 ? '${content.substring(0, 80)}…' : content;
      final updated = conv.copyWith(
        lastMessagePreview: preview,
        updatedAt: DateTime.now(),
      );
      await ref
          .read(conversationRepositoryProvider)
          .updateConversation(updated);
      state = state.copyWith(conversation: updated);
      ref.read(conversationsProvider.notifier).refreshConversation(updated.id);
    }
  }

  void _markStreamError(String assistantMsgId, String partial) {
    final updatedMsgs = state.messages.map((m) {
      if (m.id == assistantMsgId) {
        return m.copyWith(
          content: partial.isEmpty ? 'An error occurred.' : partial,
          status: MessageStatus.error,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(
      status: ChatStatus.ready,
      messages: updatedMsgs,
      streamingContent: null,
      error: 'Stream failed',
    );
  }

  Future<void> _persistMessage(ChatMessage message) async {
    await ref.read(chatMessageRepositoryProvider).saveMessage(message);
  }

  Future<void> _touchConversation(Conversation conversation) async {
    final updated = conversation.copyWith(updatedAt: DateTime.now());
    await ref.read(conversationRepositoryProvider).updateConversation(updated);
    state = state.copyWith(conversation: updated);
  }

  List<Map<String, dynamic>> _buildHistory() {
    return state.messages
        .where((m) => m.status == MessageStatus.complete)
        .map(
          (m) => {
            'role': m.role == MessageRole.user ? 'user' : 'model',
            'parts': [
              {'text': m.content},
            ],
          },
        )
        .toList();
  }

  Future<void> _cleanup() async {
    await _streamSub?.cancel();
    _streamSub = null;
    _cancelToken?.cancel('Disposed');
    _cancelToken = null;
  }

  ChatMessage _buildMessage(
    String conversationId,
    MessageRole role,
    String content,
    MessageStatus status,
  ) {
    return ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
      conversationId: conversationId,
      role: role,
      content: content,
      status: status,
      createdAt: DateTime.now(),
    );
  }
}
