import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:manus/domain/entities/chat_message.dart';
import 'package:manus/presentation/chat/notifier/chat_notifier.dart';
import 'package:manus/presentation/chat/notifier/chat_state.dart';
import 'package:manus/presentation/chat/widgets/streaming_markdown/streaming_markdown_view.dart';
import 'package:manus/theme/app_colors.dart';
import 'package:manus/theme/app_text_styles.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  bool _hasText = false;

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.maxScrollExtent - pos.pixels < 40;
  }

  @override
  void initState() {
    super.initState();
    _inputController.addListener(
      () => setState(() => _hasText = _inputController.text.trim().isNotEmpty),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    ref.read(chatProvider(widget.conversationId).notifier).sendMessage(text);
    _jumpToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider(widget.conversationId));

    // Auto-scroll when streaming content arrives
    ref.listen(
      chatProvider(widget.conversationId)
          .select((s) => s.streamingContent),
      (_, _) {
        if (_isNearBottom) _jumpToBottom();
      },
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _ChatAppBar(
        title: state.conversation?.title ?? 'Manus 1.6 Lite',
        isStreaming: state.isStreaming,
        onStop: () =>
            ref.read(chatProvider(widget.conversationId).notifier).stopStream(),
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(state, isDark, cs),
          ),
          _ChatInputBar(
            controller: _inputController,
            hasText: _hasText,
            isStreaming: state.isStreaming,
            onSend: _sendMessage,
            onStop: () =>
                ref.read(chatProvider(widget.conversationId).notifier).stopStream(),
            isDark: isDark,
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState state, bool isDark, ColorScheme cs) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.messages.isEmpty) {
      return Center(
        child: Text(
          state.error ?? 'Something went wrong',
          style: AppTextStyles.body(color: cs.error),
        ),
      );
    }

    final messages = state.messages;
    final streamingContent = state.streamingContent;

    // The streaming placeholder message (status==streaming) is rendered
    // by _StreamingBubble instead, so only that widget rebuilds per token.
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      itemCount: messages.length +
          (streamingContent != null ? 1 : 0) + // streaming bubble appended
          1, // always reserve last slot for extras
      itemBuilder: (_, i) {
        // Skip the streaming placeholder message — rendered by _StreamingBubble
        if (i < messages.length) {
          final msg = messages[i];
          if (msg.status == MessageStatus.streaming) {
            // Render streaming bubble for this slot
            return _StreamingBubble(
              conversationId: widget.conversationId,
            );
          }
          return _MessageItem(
            message: msg,
            isDark: isDark,
            cs: cs,
            isLast: i == messages.length - 1,
          );
        }

        // After all messages: rating card for last completed assistant msg
        final lastAssistant = messages.lastOrNull;
        if (lastAssistant != null &&
            lastAssistant.role == MessageRole.assistant &&
            lastAssistant.isComplete &&
            !state.isStreaming) {
          return _BottomExtras(cs: cs);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isStreaming;
  final VoidCallback onStop;
  final VoidCallback onBack;

  const _ChatAppBar({
    required this.title,
    required this.isStreaming,
    required this.onStop,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      leading: IconButton(
        onPressed: onBack,
        icon: Icon(Icons.chevron_left, size: 28.r, color: cs.onSurface),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title.length > 18
                    ? 'Manus 1.6 Lite'
                    : title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18.r,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.ios_share_outlined, size: 22.r, color: cs.onSurface),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.assignment_outlined,
                size: 22.r,
                color: cs.onSurface,
              ),
            ),
            Positioned(
              top: 8.r,
              right: 8.r,
              child: Container(
                width: 7.r,
                height: 7.r,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.more_horiz, size: 22.r, color: cs.onSurface),
        ),
      ],
    );
  }
}

// ── Message items ────────────────────────────────────────────

class _MessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final ColorScheme cs;
  final bool isLast;

  const _MessageItem({
    required this.message,
    required this.isDark,
    required this.cs,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    if (message.role == MessageRole.user) {
      return _UserBubble(message: message, isDark: isDark, cs: cs);
    }
    return _AssistantMessage(message: message, cs: cs, isLast: isLast);
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final ColorScheme cs;

  const _UserBubble({
    required this.message,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h, left: 48.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: SelectableText(
          message.content,
          style: AppTextStyles.body(color: cs.onSurface),
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme cs;
  final bool isLast;

  const _AssistantMessage({
    required this.message,
    required this.cs,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaticMarkdownView(content: message.content),
          if (message.isComplete && isLast) ...[
            SizedBox(height: 8.h),
            _TaskCompletedRow(cs: cs),
          ],
          if (message.isError) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.error_outline, size: 14.r, color: AppColors.error),
                SizedBox(width: 6.w),
                Text(
                  'Something went wrong. Try again.',
                  style: AppTextStyles.bodySmall(color: AppColors.error),
                ),
              ],
            ),
          ],
          if (message.isStopped) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.stop_circle_outlined,
                    size: 14.r, color: cs.onSurfaceVariant),
                SizedBox(width: 6.w),
                Text(
                  'Stopped',
                  style:
                      AppTextStyles.bodySmall(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Streaming bubble — only this widget rebuilds per token ───

class _StreamingBubble extends ConsumerWidget {
  final String conversationId;

  const _StreamingBubble({required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(
      chatProvider(conversationId).select((s) => s.streamingContent ?? ''),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: content.isEmpty
          ? _ThinkingIndicator()
          : StreamingMarkdownView(streamingContent: content),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Container(
          margin: EdgeInsets.only(right: 4.w),
          width: 7.r,
          height: 7.r,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeOut(
              duration: 600.ms,
              delay: (i * 200).ms,
              curve: Curves.easeInOut,
            )
            .then()
            .fadeIn(duration: 600.ms, curve: Curves.easeInOut),
      ),
    );
  }
}

// ── Bottom extras: task completed + rating ───────────────────

class _BottomExtras extends StatelessWidget {
  final ColorScheme cs;

  const _BottomExtras({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TaskCompletedRow(cs: cs),
        SizedBox(height: 16.h),
        _RatingCard(cs: cs),
        SizedBox(height: 16.h),
      ],
    );
  }
}

class _TaskCompletedRow extends StatelessWidget {
  final ColorScheme cs;
  const _TaskCompletedRow({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check, size: 16.r, color: AppColors.success),
        SizedBox(width: 6.w),
        Text(
          'Task completed',
          style: AppTextStyles.body(color: AppColors.success),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _RatingCard extends StatefulWidget {
  final ColorScheme cs;
  const _RatingCard({required this.cs});

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Rate this result',
              style: AppTextStyles.body(color: widget.cs.onSurfaceVariant),
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 24.r,
                    color: filled
                        ? const Color(0xFFF59E0B)
                        : widget.cs.onSurfaceVariant,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 150.ms);
  }
}

// ── Chat input bar ───────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool isDark;
  final ColorScheme cs;

  const _ChatInputBar({
    required this.controller,
    required this.hasText,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 12.w, 4.h),
            child: TextField(
              controller: controller,
              maxLines: 6,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: AppTextStyles.body(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Message Manus',
                hintStyle: AppTextStyles.body(color: cs.onSurfaceVariant),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 8.h),
            child: Row(
              children: [
                _BarIconButton(
                  icon: Icons.add,
                  onTap: () {},
                  cs: cs,
                ),
                SizedBox(width: 4.w),
                _BarIconButton(
                  icon: Icons.electrical_services_outlined,
                  onTap: () {},
                  cs: cs,
                ),
                const Spacer(),
                _BarIconButton(
                  icon: Icons.mic_none_rounded,
                  onTap: () {},
                  cs: cs,
                ),
                SizedBox(width: 4.w),
                _SendStopButton(
                  hasText: hasText,
                  isStreaming: isStreaming,
                  onSend: onSend,
                  onStop: onStop,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _BarIconButton({
    required this.icon,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(6.r),
        child: Icon(icon, size: 22.r, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _SendStopButton extends StatelessWidget {
  final bool hasText;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool isDark;

  const _SendStopButton({
    required this.hasText,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final active = hasText || isStreaming;
    final bg = active
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated);
    final fg = active
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary);

    return GestureDetector(
      onTap: isStreaming ? onStop : (hasText ? onSend : null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(
          isStreaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
          size: 20.r,
          color: fg,
        ),
      ),
    );
  }
}
