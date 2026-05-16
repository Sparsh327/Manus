# TASK_TRACKER.md — Manus Clone: Task & Session State

---

## HOW TO USE THIS FILE (for any AI session)

```
1. Read "Current Status" block (10 seconds) — tells you exactly where we are
2. Read "Next Up" block (30 seconds) — tells you what to do this session
3. If implementing something complex, check PROJECT_PLAN.md → relevant CE-* section
4. Check AGENTS.md for coding rules before writing any code
5. Update this file at the END of your session (Completed → tick it, update "Current Status")
```

**File hierarchy:**
- `TASK_TRACKER.md` — WHERE we are + WHAT is next ← you are here
- `PROJECT_PLAN.md` — WHY decisions were made + engineering tradeoffs
- `AGENTS.md` — HOW to code (rules, patterns, forbidden things)
- `CONTEXT.md` — WHAT to build (original assignment brief — do not edit)

---

## Current Status

```
DATE        : 2026-05-15
PHASE       : Phases 0-6 (all major phases) complete. Phase 7 (Polish) remaining.
SUB-TASK    : Phase 5 done — ChatDrawer with grouped history (Today/Yesterday/This week/Older),
              300ms debounce search via AppTextField, swipe-to-delete Dismissible + undo snackbar,
              long-press context menu (Rename/Pin/Archive/Delete) via showModalBottomSheet,
              renameConversation method added to ConversationsNotifier.
              Drawer integrated in ChatScreen (scaffoldKey, onMenu hamburger button, onNewChat).
BLOCKING    : None.
NEXT ACTION : Phase 7 — Polish + Performance.
              Priority: dart format, semantics labels, performance profiling.
              Demo video recording (5-7 min) with side-by-side real Manus comparison.
```

---

## Milestone Overview

| Milestone | Phase | Status | Notes |
|---|---|---|---|
| M0: Foundation complete | Phase 0 | ✅ Done | Riverpod, Hive, Gemini SSE, AppTheme, Talker |
| M1: Chat engine (stream + cancel + persist) | Phase 1 | ✅ Done | ChatNotifier, streaming markdown, repositories |
| M2: Chat screen UI | Phase 2 | ✅ Done | Streaming bubble isolation, auto-scroll, input bar, rating card |
| M3: All Chats + Auth + Splash + Profile + Subscription | Phases 3–4, 6 | ✅ Done | All screens scaffolded |
| M4: Suggestion chips empty state (CRITICAL) | Phase 3 | ✅ Done | 15% eval weight — CE-6 fly animation, stagger chips, blinking cursor |
| M5: Chat screen polish | Phase 2 polish | ✅ Done | Jump-to-latest pill, send morph (AnimatedSwitcher), haptics |
| M6: Drawer + history | Phase 5 | ✅ Done | Grouped history, search debounce, swipe-to-delete, context menu |
| M7: Polish + Performance | Phase 7 | ⬜ Not started | Before submission |

---

## Phase 0 — Foundation ✅ COMPLETE

| # | Task | Status | Notes |
|---|---|---|---|
| 0.1 | Riverpod migration (remove BLoC, Freezed, GetIt) | ✅ Done | |
| 0.2 | Update AGENTS.md (Riverpod rules, forbidden patterns) | ✅ Done | |
| 0.3 | Create PROJECT_PLAN.md | ✅ Done | |
| 0.4 | Create TASK_TRACKER.md | ✅ Done | |
| 0.5 | Add missing packages to pubspec.yaml | ✅ Done | flutter_animate, flutter_riverpod, talker_flutter, google_fonts, etc. |
| 0.6 | Asset directory structure | ✅ Done | assets/images/ + assets/icons/ declared |
| 0.7 | Platform-aware typography (AppFonts) | ✅ Done | null fontFamily on iOS → SF Pro; GoogleFonts.interTextTheme on Android |
| 0.8 | Full AppTheme (light + dark token sets) | ✅ Done | app_colors.dart + app_theme.dart |
| 0.9 | Animated theme switching (200ms) | ✅ Done | MaterialApp AnimatedTheme |
| 0.10 | Talker logger wired globally | ✅ Done | loggerProvider, TalkerDioLogger |
| 0.11 | GeminiService (raw Dio SSE + CancelToken) | ✅ Done | gemini_service.dart |
| 0.12 | ThemeNotifier (Hive-persisted) | ✅ Done | |
| 0.13 | AppButton, AppTextField wrappers | ✅ Done | No raw ElevatedButton/TextField |
| 0.14 | HiveService (4 boxes: conversations, chatMessages, settings) | ✅ Done | |

---

## Phase 1 — Chat Domain + Core Engine ✅ COMPLETE

| # | Task | Status | Notes |
|---|---|---|---|
| 1.1 | `Conversation` entity | ✅ Done | id, title, createdAt, updatedAt, isPinned, isArchived, copyWith |
| 1.2 | `ChatMessage` entity | ✅ Done | MessageRole, MessageStatus enums, copyWith |
| 1.3 | ConversationModel + ChatMessageModel | ✅ Done | fromJson/toJson/fromEntity, millisecondsSinceEpoch |
| 1.4 | ConversationLocalDataSource | ✅ Done | Hive, pinned-first sort |
| 1.5 | ChatMessageLocalDataSource | ✅ Done | conversationId-keyed JSON lists, upsert |
| 1.6 | ConversationRepositoryImpl | ✅ Done | Either<Failure,Output>, _groupByDate |
| 1.7 | ChatMessageRepositoryImpl | ✅ Done | |
| 1.8 | chat_data_providers.dart | ✅ Done | Riverpod wiring for all layers |
| 1.9 | ChatState | ✅ Done | streamingContent separate from messages (perf key) |
| 1.10 | ChatNotifier | ✅ Done | NotifierProvider.family, CancelToken, StreamSubscription, sendMessage/stop/editAndResend |
| 1.11 | MarkdownBlock + MarkdownParser | ✅ Done | Line-by-line state machine, 7 block types |
| 1.12 | StreamingMarkdownView | ✅ Done | _CachedBlockWidget (build() once), _ActiveBlockWidget |
| 1.13 | CodeBlockWidget | ✅ Done | Horizontal scroll, copy button, language label |

---

## Phase 2 — Chat Screen UI ✅ DONE (partial polish remaining)

| # | Task | Status | Notes |
|---|---|---|---|
| 2.1 | ChatScreen scaffold (ConsumerStatefulWidget + ScrollController) | ✅ Done | |
| 2.2 | User message bubble (right-aligned, fade+slide entrance) | ✅ Done | |
| 2.3 | Assistant message (left-aligned, StaticMarkdownView) | ✅ Done | |
| 2.4 | _StreamingBubble (only widget that rebuilds per token) | ✅ Done | chatProvider.select(streamingContent) |
| 2.5 | _ThinkingIndicator (3-dot pulse when streamingContent is empty) | ✅ Done | flutter_animate repeat |
| 2.6 | Smart auto-scroll (_isNearBottom getter, 40px threshold, jumpTo) | ✅ Done | |
| 2.7 | _TaskCompletedRow (green ✓) + _RatingCard (5 interactive stars) | ✅ Done | Appear after last complete assistant msg |
| 2.8 | ChatAppBar (title+dropdown, share, task+blue-dot, more) | ✅ Done | |
| 2.9 | _ChatInputBar (multiline, +/tools/mic icons) | ✅ Done | |
| 2.10 | _SendStopButton (animated circle, stop during stream) | ✅ Done | |
| 2.11 | **"Jump to latest" pill** | ✅ Done | AnimatedOpacity + IgnorePointer + jumpTo on tap |
| 2.12 | **Send button morph (arrow → stop → arrow)** | ✅ Done | AnimatedSwitcher + ScaleTransition |
| 2.13 | **Haptics** (send, stop, chip tap) | ✅ Done | lightImpact/mediumImpact/selectionClick |
| 2.14 | **Streaming caret pulse** | ✅ Done | _BlinkingCursor, flutter_animate repeat |
| 2.15 | Inline error bubble (API error + retry) | ✅ Done | Shows error row below message |
| 2.16 | Stopped message badge | ✅ Done | Shows "Stopped" row below message |

---

## Phase 3 — Home / Empty State ⚠️ HIGHEST PRIORITY NEXT

**Evaluation weight: 15% — single most-weighted animation in the entire assignment.**

The "empty state" is the ChatScreen when it's a brand-new conversation (no messages).
It should show animated suggestion chips. Tapping a chip → CE-6 hero animation → fills input.

| # | Task | Status | Notes |
|---|---|---|---|
| 3.1 | **Suggestion chips data model** | ✅ Done | 4 suggestions in _suggestions const |
| 3.2 | **SuggestionChip widget** | ✅ Done | Pill border, tap → fill input, haptic |
| 3.3 | **Stagger animate-in** (80ms offset, easeOutCubic, slideY+scaleXY+fadeIn) | ✅ Done | suggestion_chips.dart |
| 3.4 | **Chip → input Overlay animation** | ✅ Done | CE-6. ChipFlyAnimation, dart:ui lerpDouble, pill→rect morph, fade last 25% |
| 3.5 | Empty state heading + waving hand icon | ✅ Done | SuggestionChipsEmptyState, fadeIn animations |
| 3.6 | ConversationsScreen empty state | ⬜ Todo | Low priority |

---

## Phase 4 — Auth + Splash ✅ COMPLETE

| # | Task | Status | Notes |
|---|---|---|---|
| 4.1 | SplashScreen (centered logo, "from ∞ Meta", 2.2s → Login) | ✅ Done | flutter_animate fade+scale |
| 4.2 | LoginScreen (Welcome + social auth buttons + colored dot grid) | ✅ Done | CustomPainter dot pattern |
| 4.3 | EmailLoginScreen (email field, Cloudflare mock, Continue) | ✅ Done | |
| 4.4 | Mock auth flow (any button → conversations screen) | ✅ Done | |

---

## Phase 5 — Chat Drawer + History ⬜ NOT STARTED

**Evaluation weight: ~10%**

| # | Task | Status | Notes |
|---|---|---|---|
| 5.1 | Drawer scaffold (Scaffold.drawer, standard physics) | ✅ Done | ChatDrawer, scaffoldKey, hamburger icon in AppBar |
| 5.2 | Grouped history list (Today/Yesterday/This week/Older) | ✅ Done | _group() date bucketing, _SectionHeader |
| 5.3 | Search with 300ms debounce | ✅ Done | AppTextField + Timer debounce |
| 5.4 | Swipe-to-delete + undo snackbar | ✅ Done | Dismissible endToStart, SnackBar with undo action |
| 5.5 | Long-press context menu (Rename/Pin/Archive/Delete) | ✅ Done | showModalBottomSheet, rename sheet with AppTextField |

---

## Phase 6 — Remaining Screens 🔄 PARTIAL

| # | Task | Status | Notes |
|---|---|---|---|
| 6.1 | ProfileScreen | ✅ Done | Orange avatar, Free plan, 6 settings rows, Upgrade → Subscription |
| 6.2 | SubscriptionScreen | ✅ Done | Monthly/Annually radio, feature card, Upgrade now CTA |
| 6.3 | ConversationsScreen (All Chats) | ✅ Done | Filter tabs, Agent promo tile, FAB, long-press delete |
| 6.4 | Mode Picker bottom sheet | ⬜ Todo | Low priority |
| 6.5 | Attachment tray | ⬜ Todo | Low priority |

---

## Phase 7 — Polish + Performance ⬜ NOT STARTED

| # | Task | Status | Notes |
|---|---|---|---|
| 7.1 | Haptics audit | ⬜ Todo | All interaction points |
| 7.2 | Semantics labels | ⬜ Todo | TalkBack / VoiceOver |
| 7.3 | 200-message performance profiling | ⬜ Todo | 60fps target |
| 7.4 | Memory profiling | ⬜ Todo | <250MB RSS |
| 7.5 | Release APK build + size | ⬜ Todo | <35MB |
| 7.6 | `flutter analyze` zero warnings | ✅ Current | Passing |
| 7.7 | `dart format` | ⬜ Todo | Before submission |
| 7.8 | Demo video recording | ⬜ Todo | 5–7 min per spec |
| 7.9 | Side-by-side recording with real Manus app | ⬜ Todo | Key submission deliverable |

---

## Completed Tasks Log

| Date | Task | Notes |
|---|---|---|
| 2026-05-15 | Phase 0 complete | Riverpod migration, AppTheme, Talker, GeminiService (Dio SSE), Hive, platform typography. flutter analyze: 0 issues. |
| 2026-05-15 | Phase 1 complete | All domain entities, Hive models, repositories, ChatNotifier (family, CancelToken, StreamSubscription), streaming markdown engine (block-segmented, _CachedBlockWidget, CodeBlockWidget). 0 issues. |
| 2026-05-15 | Phase 2 complete | ChatScreen (ConsumerStatefulWidget, ScrollController), _StreamingBubble isolation, smart auto-scroll (jumpTo, 40px threshold), _ThinkingIndicator, _TaskCompletedRow, _RatingCard, ChatAppBar, _ChatInputBar, _SendStopButton. 0 issues. |
| 2026-05-15 | Phase 4 complete | SplashScreen (2.2s, logo, "from Meta"), LoginScreen (dot-grid, social buttons), EmailLoginScreen (email field, CAPTCHA mock). |
| 2026-05-15 | Phase 6 partial | ConversationsScreen (filter tabs, Agent promo, FAB flow, relative time formatter), ConversationsNotifier (create/delete/pin/search/filter), ProfileScreen (orange avatar, Free/Upgrade, settings rows), SubscriptionScreen (Monthly/Annually radio, features card, animated CTA). |
| 2026-05-15 | Router wired | All 7 routes: splash → login → email-login → chats → chat/:id → profile → subscription |
| 2026-05-15 | Phase 3 complete | SuggestionChipsEmptyState (waving hand, subtitle, stagger chips). CE-6 chip→input Overlay fly animation (ChipFlyAnimation, dart:ui lerpDouble, radius morph, fade). |
| 2026-05-15 | Phase 2 polish complete | Jump-to-latest pill (AnimatedOpacity + IgnorePointer). Send/stop AnimatedSwitcher morph. _BlinkingCursor (flutter_animate repeat). Haptics (lightImpact send, mediumImpact stop, selectionClick chip). |

---

## Architecture Decision Log

*Quick reference. Full reasoning in PROJECT_PLAN.md.*

| ID | Decision | Chosen | Rejected |
|---|---|---|---|
| AD-1 | State management | flutter_riverpod (Notifier) | BLoC/Cubit, StateNotifier |
| AD-2 | DI | Riverpod Providers | GetIt |
| AD-3 | Code generation | None (plain immutable classes) | freezed, riverpod_generator |
| AD-4 | Gemini integration | Raw Dio + SSE parsing | google_generative_ai SDK |
| AD-5 | Streaming markdown | Custom block-segmented renderer | flutter_markdown full-text |
| AD-6 | Auto-scroll | ScrollController + jumpTo + addPostFrameCallback | animateTo |
| AD-7 | Chat state model | Notifier<ChatState>.family + StreamSubscription | StreamProvider, AsyncNotifier |
| AD-8 | Typography | Platform split: null fontFamily on iOS = SF Pro | Inter everywhere |
| AD-9 | Chip animation | Hero with custom HeroFlightShuttleBuilder | AnimatedPositioned |
| AD-10 | Local persistence | Hive (JSON map, no TypeAdapters — avoids build_runner) | Isar, TypeAdapters |
| AD-11 | streamingContent | Separate field outside messages list | Token-appended to message |
| AD-12 | Streaming placeholder | status==streaming message in list; _StreamingBubble renders it | Append-only list |

---

## Pending Decisions

| ID | Decision | Options | Status |
|---|---|---|---|
| PD-2 | Animation library for chip morph | flutter_animate Hero (chosen plan) vs Rive | Resolved → flutter_animate + Hero (CE-6) |

---

## Session Start Checklist

*Run through this at the start of every AI session:*

```
□ Read "Current Status" block above
□ Identify which phase/task to work on
□ Check if any Blocked Items affect the task
□ Review relevant CE-* section in PROJECT_PLAN.md if task is complex
□ Check AGENTS.md forbidden patterns before writing any new code
□ If building a screen: confirm screenshot has been reviewed first
□ Run `flutter analyze` before starting to confirm clean baseline
```

---

## Session End Checklist

*Run through this at the end of every AI session:*

```
□ Update "Current Status" block with what was done and what's next
□ Tick off completed tasks in the relevant Phase table
□ Add completed tasks to "Completed Tasks Log" with date + notes
□ Add any new blockers to "Blocked Items"
□ Add any new architecture decisions to "Architecture Decision Log"
□ Run `flutter analyze` — must pass zero warnings
□ Run `dart format lib/` to keep code formatted
□ Commit + push
```

---

*Last updated: 2026-05-15 | Phases 0–2 + partial 4 & 6 complete. Next: Phase 3 suggestion chips (15% eval weight).*
