import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/core/component/app_text_field.dart';
import 'package:manus/domain/entities/conversation.dart';
import 'package:manus/presentation/conversations/notifier/conversations_notifier.dart';
import 'package:manus/theme/app_colors.dart';
import 'package:manus/theme/app_text_styles.dart';

// ── Public drawer widget ─────────────────────────────────────

class ChatDrawer extends ConsumerStatefulWidget {
  final String currentConversationId;
  final void Function(String conversationId) onConversationTap;
  final VoidCallback? onNewChat;

  const ChatDrawer({
    super.key,
    required this.currentConversationId,
    required this.onConversationTap,
    this.onNewChat,
  });

  @override
  ConsumerState<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<ChatDrawer> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(conversationsProvider.notifier).setSearch(query);
    });
  }

  Map<String, List<Conversation>> _group(List<Conversation> convs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final groups = <String, List<Conversation>>{
      'Today': [],
      'Yesterday': [],
      'This week': [],
      'Older': [],
    };
    for (final c in convs) {
      final d = DateTime(c.updatedAt.year, c.updatedAt.month, c.updatedAt.day);
      if (!d.isBefore(today)) {
        groups['Today']!.add(c);
      } else if (d == yesterday) {
        groups['Yesterday']!.add(c);
      } else if (d.isAfter(weekAgo)) {
        groups['This week']!.add(c);
      } else {
        groups['Older']!.add(c);
      }
    }
    return groups;
  }

  Future<void> _deleteWithUndo(Conversation conv) async {
    await ref.read(conversationsProvider.notifier).deleteConversation(conv.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${conv.title}" deleted'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref
                .read(conversationsProvider.notifier)
                .renameConversation(conv.id, conv.title);
          },
        ),
      ),
    );
  }

  void _showContextMenu(Conversation conv) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetCtx) => _ContextMenu(
        conv: conv,
        isDark: isDark,
        cs: cs,
        onRename: () {
          Navigator.of(sheetCtx).pop();
          _showRenameSheet(conv);
        },
        onPin: () {
          Navigator.of(sheetCtx).pop();
          ref
              .read(conversationsProvider.notifier)
              .pinConversation(conv.id, pinned: !conv.isPinned);
        },
        onDelete: () {
          Navigator.of(sheetCtx).pop();
          _deleteWithUndo(conv);
        },
      ),
    );
  }

  void _showRenameSheet(Conversation conv) {
    final controller = TextEditingController(text: conv.title);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    void save() {
      final newTitle = controller.text.trim();
      if (newTitle.isNotEmpty) {
        ref
            .read(conversationsProvider.notifier)
            .renameConversation(conv.id, newTitle);
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 24.h,
          bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 24.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rename', style: AppTextStyles.h2(color: cs.onSurface)),
            SizedBox(height: 16.h),
            AppTextField(
              controller: controller,
              hint: 'Conversation name',
              autofocus: true,
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                save();
                Navigator.of(sheetCtx).pop();
              },
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () {
                save();
                Navigator.of(sheetCtx).pop();
              },
              child: Container(
                width: double.infinity,
                height: 50.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationsProvider);
    final convs = state.displayed;
    final groups = _group(convs);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      width: 300.w,
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 12.h),
              child: Row(
                children: [
                  Text('Chats', style: AppTextStyles.h2(color: cs.onSurface)),
                  const Spacer(),
                  if (widget.onNewChat != null)
                    GestureDetector(
                      onTap: widget.onNewChat,
                      child: Padding(
                        padding: EdgeInsets.all(8.r),
                        child: Icon(
                          Icons.edit_square,
                          size: 22.r,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Search ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
              child: AppTextField(
                controller: _searchController,
                hint: 'Search conversations',
                prefix: Icon(
                  Icons.search_rounded,
                  size: 20.r,
                  color: cs.onSurfaceVariant,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            // ── List ────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : convs.isEmpty
                  ? Center(
                      child: Text(
                        state.searchQuery.isEmpty
                            ? 'No conversations yet'
                            : 'No results',
                        style: AppTextStyles.body(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.only(bottom: 8.h),
                      children: [
                        for (final entry in groups.entries)
                          if (entry.value.isNotEmpty) ...[
                            _SectionHeader(label: entry.key, cs: cs),
                            for (final conv in entry.value)
                              Dismissible(
                                key: ValueKey(conv.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20.w),
                                  color: AppColors.error,
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 22.r,
                                  ),
                                ),
                                onDismissed: (_) => _deleteWithUndo(conv),
                                child: _ConvTile(
                                  conv: conv,
                                  isActive:
                                      conv.id == widget.currentConversationId,
                                  isDark: isDark,
                                  cs: cs,
                                  onTap: () =>
                                      widget.onConversationTap(conv.id),
                                  onLongPress: () => _showContextMenu(conv),
                                ),
                              ),
                          ],
                      ],
                    ),
            ),
            // ── Profile footer ───────────────────────────────
            _ProfileRow(isDark: isDark, cs: cs),
          ],
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _SectionHeader({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 4.h),
      child: Text(
        label,
        style: AppTextStyles.bodySmall(
          color: cs.onSurfaceVariant,
        ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4),
      ),
    );
  }
}

// ── Conversation tile ────────────────────────────────────────

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final bool isActive;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ConvTile({
    required this.conv,
    required this.isActive,
    required this.isDark,
    required this.cs,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            if (conv.isPinned) ...[
              Icon(
                Icons.push_pin_rounded,
                size: 13.r,
                color: cs.onSurfaceVariant,
              ),
              SizedBox(width: 6.w),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.title,
                          style: AppTextStyles.body(color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _relativeTime(conv.updatedAt),
                        style: AppTextStyles.bodySmall(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (conv.lastMessagePreview != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      conv.lastMessagePreview!,
                      style: AppTextStyles.bodySmall(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Context menu (long-press) ────────────────────────────────

class _ContextMenu extends StatelessWidget {
  final Conversation conv;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onRename;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _ContextMenu({
    required this.conv,
    required this.isDark,
    required this.cs,
    required this.onRename,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8.h),
        Container(
          width: 36.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            conv.title,
            style: AppTextStyles.body(
              color: cs.onSurface,
            ).copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 8.h),
        _MenuItem(
          icon: Icons.edit_outlined,
          label: 'Rename',
          cs: cs,
          onTap: onRename,
        ),
        _MenuItem(
          icon: conv.isPinned
              ? Icons.push_pin_outlined
              : Icons.push_pin_outlined,
          label: conv.isPinned ? 'Unpin' : 'Pin',
          cs: cs,
          onTap: onPin,
        ),
        _MenuItem(
          icon: Icons.archive_outlined,
          label: 'Archive',
          cs: cs,
          onTap: () => Navigator.of(context).pop(),
        ),
        _MenuItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          cs: cs,
          color: AppColors.error,
          onTap: onDelete,
        ),
        SizedBox(height: 8.h),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.cs,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? cs.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 20.r, color: fg),
            SizedBox(width: 14.w),
            Text(label, style: AppTextStyles.body(color: fg)),
          ],
        ),
      ),
    );
  }
}

// ── Profile footer ───────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;

  const _ProfileRow({required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: const Color(0xFFE8541A),
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sparsh', style: AppTextStyles.body(color: cs.onSurface)),
                Text(
                  'Free plan',
                  style: AppTextStyles.bodySmall(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.more_horiz, size: 20.r, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
