import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manus/domain/entities/conversation.dart';
import 'package:manus/presentation/conversations/notifier/conversations_notifier.dart';
import 'package:manus/presentation/conversations/notifier/conversations_state.dart';
import 'package:manus/router/app_routes.dart';
import 'package:manus/theme/app_colors.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDark, cs),
            if (_searchOpen) _buildSearchBar(cs),
            _buildFilterTabs(state, isDark, cs),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildList(state, isDark, cs),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(isDark),
    );
  }

  Widget _buildTopBar(bool isDark, ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.profile),
            child: Icon(
              Icons.person_outline_rounded,
              size: 26.r,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            'manus',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.library_books_outlined,
                  size: 24.r,
                  color: cs.onSurface,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: 16.w),
              IconButton(
                onPressed: () {
                  setState(() {
                    _searchOpen = !_searchOpen;
                    if (!_searchOpen) {
                      _searchCtrl.clear();
                      ref.read(conversationsProvider.notifier).setSearch('');
                    }
                  });
                },
                icon: Icon(
                  Icons.search,
                  size: 24.r,
                  color: cs.onSurface,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: (v) =>
            ref.read(conversationsProvider.notifier).setSearch(v),
        style: TextStyle(fontSize: 15.sp, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Search conversations…',
          prefixIcon: Icon(Icons.search, size: 20.r, color: cs.onSurfaceVariant),
          suffixIcon: IconButton(
            onPressed: () {
              _searchCtrl.clear();
              ref.read(conversationsProvider.notifier).setSearch('');
            },
            icon: Icon(Icons.close, size: 18.r, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(
      ConversationsState state, bool isDark, ColorScheme cs) {
    const filters = ConversationsFilter.values;
    final labels = ['All', 'Agent', 'Scheduled', 'Favorites'];

    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: filters.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final active = state.filter == filters[i];
          return GestureDetector(
            onTap: () =>
                ref.read(conversationsProvider.notifier).setFilter(filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: active
                    ? (isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? cs.onSurface
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(
      ConversationsState state, bool isDark, ColorScheme cs) {
    final conversations = state.displayed;

    // Build item list: Agent promo card always first, then real conversations
    return ListView.builder(
      padding: EdgeInsets.only(top: 8.h, bottom: 100.h),
      itemCount: conversations.length + 1, // +1 for Agent promo
      itemBuilder: (_, i) {
        if (i == 0) {
          return _AgentPromoTile(isDark: isDark, cs: cs)
              .animate()
              .fadeIn(duration: 300.ms);
        }
        final conv = conversations[i - 1];
        return _ConversationTile(
          conversation: conv,
          isDark: isDark,
          cs: cs,
          onTap: () => context.push(AppRoutes.chat(conv.id)),
          onDelete: () =>
              ref.read(conversationsProvider.notifier).deleteConversation(conv.id),
        ).animate().fadeIn(duration: 250.ms, delay: (i * 40).ms);
      },
    );
  }

  Widget _buildFAB(bool isDark) {
    return FloatingActionButton(
      onPressed: () async {
        final id = await ref
            .read(conversationsProvider.notifier)
            .createConversation();
        if (id != null && mounted) {
          context.push(AppRoutes.chat(id));
        }
      },
      backgroundColor: isDark ? Colors.white : Colors.black,
      elevation: 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: isDark ? Colors.black : Colors.white,
            size: 22.r,
          ),
          Positioned(
            top: 6.r,
            right: 6.r,
            child: Icon(
              Icons.add,
              color: isDark ? Colors.black : Colors.white,
              size: 13.r,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Agent promo tile ─────────────────────────────────────────

class _AgentPromoTile extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;

  const _AgentPromoTile({required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            children: [
              _AgentAvatar(isDark: isDark),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Agent',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _NewBadge(),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Claim your personalized agent',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
      ],
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  final bool isDark;
  const _AgentAvatar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.r,
      height: 52.r,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Icon(
        Icons.radar_rounded,
        size: 26.r,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        'New',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Conversation tile ────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.isDark,
    required this.cs,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ConvAvatar(isDark: isDark),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.title,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _formatTime(conversation.updatedAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Manus will continue working after your request…',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete conversation'),
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDays = today.subtract(const Duration(days: 7));
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) {
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final hour = h % 12 == 0 ? 12 : h % 12;
      return '$hour:$m $period';
    } else if (msgDay == yesterday) {
      return 'Yesterday';
    } else if (msgDay.isAfter(sevenDays)) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    }
  }
}

class _ConvAvatar extends StatelessWidget {
  final bool isDark;
  const _ConvAvatar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.r,
      height: 52.r,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.forum_outlined,
        size: 24.r,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
    );
  }
}
