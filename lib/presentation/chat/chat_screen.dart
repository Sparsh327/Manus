import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:manus/domain/entities/chat_message.dart';
import 'package:manus/presentation/chat/notifier/chat_notifier.dart';
import 'package:manus/presentation/chat/notifier/chat_state.dart';
import 'package:manus/presentation/chat/widgets/chat_drawer.dart';
import 'package:manus/presentation/chat/widgets/streaming_markdown/streaming_markdown_view.dart';
import 'package:manus/presentation/chat/widgets/suggestion_chips.dart';
import 'package:manus/presentation/conversations/notifier/conversations_notifier.dart';
import 'package:manus/router/app_routes.dart';
import 'package:manus/theme/app_colors.dart';
import 'package:manus/theme/app_text_styles.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputBarKey = GlobalKey();
  bool _hasText = false;
  bool _showJumpPill = false;
  bool _pendingScrollJump = false;

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
    _scrollController.addListener(_onScrollChange);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onScrollChange() {
    final show = !_isNearBottom;
    if (show != _showJumpPill) setState(() => _showJumpPill = show);
  }

  void _jumpToBottom() {
    if (_pendingScrollJump) return;
    _pendingScrollJump = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingScrollJump = false;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _inputController.clear();
    ref.read(chatProvider(widget.conversationId).notifier).sendMessage(text);
    _jumpToBottom();
  }

  void _stopStream() {
    HapticFeedback.mediumImpact();
    ref.read(chatProvider(widget.conversationId).notifier).stopStream();
  }

  void _onChipTap(BuildContext chipCtx, String text) {
    HapticFeedback.selectionClick();

    final chipBox = chipCtx.findRenderObject() as RenderBox?;
    final inputBox =
        _inputBarKey.currentContext?.findRenderObject() as RenderBox?;

    if (chipBox == null || inputBox == null) {
      _inputController.text = text;
      return;
    }

    final chipRect = chipBox.localToGlobal(Offset.zero) & chipBox.size;
    final inputRect = inputBox.localToGlobal(Offset.zero) & inputBox.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ChipFlyAnimation(
        startRect: chipRect,
        endRect: inputRect,
        text: text,
        isDark: isDark,
        onComplete: () {
          entry.remove();
          _inputController.text = text;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: text.length),
          );
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    // Select only non-streaming fields — _StreamingBubble handles streamingContent
    // via its own .select(), so per-token updates never rebuild this widget.
    final s = ref.watch(
      chatProvider(widget.conversationId).select(
        (st) => (
          status: st.status,
          messages: st.messages,
          conversation: st.conversation,
          error: st.error,
        ),
      ),
    );

    ref.listen(
      chatProvider(widget.conversationId).select((st) => st.streamingContent),
      (_, _) {
        if (_isNearBottom) _jumpToBottom();
      },
    );

    final isStreaming = s.status == ChatStatus.streaming;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: cs.surface,
      drawer: ChatDrawer(
        currentConversationId: widget.conversationId,
        onConversationTap: (id) {
          _scaffoldKey.currentState?.closeDrawer();
          context.go(AppRoutes.chat(id));
        },
        onNewChat: () async {
          _scaffoldKey.currentState?.closeDrawer();
          final id = await ref
              .read(conversationsProvider.notifier)
              .createConversation();
          if (id != null && context.mounted) context.go(AppRoutes.chat(id));
        },
      ),
      appBar: _ChatAppBar(
        title: s.conversation?.title ?? 'Manus 1.6 Lite',
        isStreaming: isStreaming,
        onStop: _stopStream,
        onBack: () => context.pop(),
        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildMessageList(s.status, s.messages, s.error, isDark, cs),
                Positioned(
                  bottom: 16.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _showJumpPill ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_showJumpPill,
                        child: _JumpToLatestPill(
                          onTap: () {
                            _jumpToBottom();
                            setState(() => _showJumpPill = false);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ChatInputBar(
            containerKey: _inputBarKey,
            controller: _inputController,
            hasText: _hasText,
            isStreaming: isStreaming,
            onSend: _sendMessage,
            onStop: _stopStream,
            isDark: isDark,
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    ChatStatus status,
    List<ChatMessage> messages,
    String? error,
    bool isDark,
    ColorScheme cs,
  ) {
    if (status == ChatStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == ChatStatus.error && messages.isEmpty) {
      return Center(
        child: Text(
          error ?? 'Something went wrong',
          style: AppTextStyles.body(color: cs.error),
        ),
      );
    }

    final isStreaming = status == ChatStatus.streaming;

    if (messages.isEmpty && !isStreaming) {
      return SuggestionChipsEmptyState(onChipTap: _onChipTap);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      itemCount: messages.length + 1,
      itemBuilder: (_, i) {
        if (i < messages.length) {
          final msg = messages[i];
          if (msg.status == MessageStatus.streaming) {
            return _StreamingBubbleEntry(
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

        final lastMsg = messages.lastOrNull;
        if (lastMsg != null &&
            lastMsg.role == MessageRole.assistant &&
            lastMsg.isComplete &&
            !isStreaming) {
          return _BottomExtras(cs: cs);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Jump-to-latest pill ──────────────────────────────────────

class _JumpToLatestPill extends StatelessWidget {
  final VoidCallback onTap;

  const _JumpToLatestPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16.r,
              color: cs.onSurfaceVariant,
            ),
            SizedBox(width: 4.w),
            Text(
              'Jump to latest',
              style: AppTextStyles.bodySmall(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isStreaming;
  final VoidCallback onStop;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  const _ChatAppBar({
    required this.title,
    required this.isStreaming,
    required this.onStop,
    required this.onBack,
    required this.onMenu,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 14.h),
              child: Icon(Icons.chevron_left, size: 28.r, color: cs.onSurface),
            ),
          ),
          GestureDetector(
            onTap: onMenu,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 16.h),
              child: Icon(Icons.menu_rounded, size: 22.r, color: cs.onSurface),
            ),
          ),
        ],
      ),
      leadingWidth: 72.w,
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title.length > 18 ? 'Manus 1.6 Lite' : title,
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
          color: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.lightSurfaceElevated,
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
                Icon(
                  Icons.stop_circle_outlined,
                  size: 14.r,
                  color: cs.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Stopped',
                  style: AppTextStyles.bodySmall(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Streaming bubble entry — plays entrance animation exactly once ───
// Separating entrance animation into a StatefulWidget is critical:
// flutter_animate's _AnimateWidget compares effects lists by reference,
// so .animate() called in a ConsumerWidget.build() restarts the animation
// on every token rebuild, causing visible flicker.

class _StreamingBubbleEntry extends StatefulWidget {
  final String conversationId;
  const _StreamingBubbleEntry({required this.conversationId});

  @override
  State<_StreamingBubbleEntry> createState() => _StreamingBubbleEntryState();
}

class _StreamingBubbleEntryState extends State<_StreamingBubbleEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: RepaintBoundary(
          child: _StreamingBubble(conversationId: widget.conversationId),
        ),
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
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: content.isEmpty
            ? const _ThinkingIndicator(key: ValueKey('thinking'))
            : _StreamingContent(
                key: const ValueKey('content'),
                content: content,
                cs: cs,
              ),
      ),
    );
  }
}

class _StreamingContent extends StatelessWidget {
  final String content;
  final ColorScheme cs;

  const _StreamingContent({
    super.key,
    required this.content,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamingMarkdownView(streamingContent: content),
        SizedBox(height: 2.h),
        _BlinkingCursor(),
      ],
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 26.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          3,
          (i) => Container(
            margin: EdgeInsets.only(right: 5.w),
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(
                begin: 0.4,
                end: 1.0,
                duration: 460.ms,
                delay: (i * 160).ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scaleXY(
                begin: 1.0,
                end: 0.4,
                duration: 460.ms,
                curve: Curves.easeInOut,
              ),
        ),
      ),
    ).animate().fadeIn(duration: 180.ms);
  }
}

class _BlinkingCursor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text('|', style: AppTextStyles.body(color: cs.onSurface))
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeOut(duration: 500.ms, curve: Curves.easeInOut);
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
  final GlobalKey containerKey;
  final TextEditingController controller;
  final bool hasText;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool isDark;
  final ColorScheme cs;

  const _ChatInputBar({
    required this.containerKey,
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

    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
      child: Container(
        key: containerKey,
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
                  _BarIconButton(icon: Icons.add, onTap: () {}, cs: cs),
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
        : (isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.lightSurfaceElevated);
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isStreaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
            key: ValueKey(isStreaming),
            size: 20.r,
            color: fg,
          ),
        ),
      ),
    );
  }
}
