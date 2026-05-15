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
PHASE       : Phase 0 — Foundation
SUB-TASK    : Foundation complete. All infrastructure in place.
BLOCKING    : None.
NEXT ACTION : Start Phase 1 — Chat domain entities + Hive models + GeminiService integration.
              ⚠️  Screenshots needed before Phase 2 (Chat Screen UI).
```

---

## Milestone Overview

| Milestone | Phase | Status | Est. Duration |
|---|---|---|---|
| M0: Foundation complete | Phase 0 | 🔄 In Progress | ~4 hours |
| M1: Chat engine working (stream + cancel + persist) | Phase 1 | ⬜ Not started | ~1.5 days |
| M2: Chat screen UI complete | Phase 2 | ⬜ Not started | ~1 day |
| M3: Home + Auth + Onboarding + Splash | Phases 3–4 | ⬜ Not started | ~1 day |
| M4: Drawer + remaining screens | Phases 5–6 | ⬜ Not started | ~1 day |
| M5: Polish + Performance + Submission | Phase 7 | ⬜ Not started | ~1 day |

---

## Phase 0 — Foundation

**Goal:** Every subsequent screen can be built on stable infrastructure. No rework after this phase.

| # | Task | Priority | Status | Notes |
|---|---|---|---|---|
| 0.1 | Riverpod migration (remove BLoC, Freezed, GetIt) | P0 | ✅ Done | Notifier pattern in place |
| 0.2 | Update AGENTS.md (Riverpod rules, forbidden patterns) | P0 | ✅ Done | |
| 0.3 | Create PROJECT_PLAN.md | P0 | ✅ Done | |
| 0.4 | Create TASK_TRACKER.md | P0 | ✅ Done | |
| 0.5 | Add missing packages to pubspec.yaml | P0 | ✅ Done | flutter_animate, cached_network_image, flutter_svg, talker_flutter, google_fonts |
| 0.6 | Asset directory structure (fonts/, images/, icons/) | P0 | ✅ Done | assets/images/ + assets/icons/ declared in pubspec |
| 0.7 | Declare Inter + JetBrains Mono fonts (Android only) | P0 | ✅ Done | google_fonts used — no bundling needed, cached after first fetch |
| 0.8 | Full AppTheme (light + dark token sets) | P0 | ✅ Done | app_colors.dart (tokens) + app_theme.dart (ThemeData) |
| 0.9 | Platform-aware typography in ThemeData | P0 | ✅ Done | null fontFamily on iOS → SF Pro; GoogleFonts.interTextTheme on Android |
| 0.10 | Animated theme switching (200ms cross-fade) | P1 | ✅ Done | MaterialApp uses AnimatedTheme internally at kThemeAnimationDuration=200ms |
| 0.11 | Talker logger wired up globally | P0 | ✅ Done | loggerProvider in core_providers.dart; TalkerDioLogger on Dio |
| 0.12 | GeminiService (raw Dio SSE + CancelToken) | P0 | ✅ Done | data/data_sources/remote/gemini/gemini_service.dart |
| 0.13 | AppTheme provider (Riverpod, persisted to Hive) | P1 | ✅ Done | themeProvider (ThemeNotifier) → persisted to Hive settings box |
| 0.14 | CommonButton, CommonTextField wrappers | P1 | ✅ Done | app_button.dart, app_text_field.dart; ScreenStateRenderer fixed |

---

## Phase 1 — Chat Domain + Core Engine

**Goal:** Full end-to-end chat works in code (no UI yet). Message → stream → persist → cancel → recover.

| # | Task | Priority | Status | Notes |
|---|---|---|---|---|
| 1.1 | `Conversation` entity (id, title, createdAt, updatedAt, pinned, archived) | P0 | ⬜ Todo | |
| 1.2 | `ChatMessage` entity (id, conversationId, role, content, status, createdAt) | P0 | ⬜ Todo | status: sending/streaming/complete/stopped/error |
| 1.3 | Hive models for Conversation + ChatMessage | P0 | ⬜ Todo | See PD-1 in PROJECT_PLAN.md for TypeAdapter decision |
| 1.4 | ConversationRepository interface + Hive implementation | P0 | ⬜ Todo | CRUD + grouped query (today/yesterday/7days/older) |
| 1.5 | ChatMessageRepository interface + Hive implementation | P0 | ⬜ Todo | |
| 1.6 | Riverpod providers for chat data layer | P0 | ⬜ Todo | |
| 1.7 | GeminiService SSE stream method | P0 | ⬜ Todo | `Stream<String> streamResponse(prompt, {cancelToken})` |
| 1.8 | ChatNotifier (Notifier<ChatState>) | P0 | ⬜ Todo | See CE-2 in PROJECT_PLAN.md |
| 1.9 | ChatState (plain immutable class) | P0 | ⬜ Todo | messages, isStreaming, activeConversationId, action |
| 1.10 | Stream cancellation (stopStream) | P0 | ⬜ Todo | CancelToken.cancel() + partial preserve + stopped badge |
| 1.11 | Edit message + fork (editAndResend) | P1 | ⬜ Todo | Remove messages after edit point, resend |
| 1.12 | App lifecycle stream handler | P1 | ⬜ Todo | Background → interrupted → "tap to retry" inline |
| 1.13 | Custom streaming markdown parser | P0 | ⬜ Todo | See CE-1 in PROJECT_PLAN.md. Block-segmented. |
| 1.14 | StreamingMarkdownView widget | P0 | ⬜ Todo | Column of keyed MarkdownBlockWidget |
| 1.15 | Code block widget (horizontal scroll, language label) | P0 | ⬜ Todo | Part of markdown renderer |

---

## Phase 2 — Chat Screen UI

**Goal:** Chat screen is pixel-perfect, animations complete, matches Manus side-by-side.

⚠️ **Do not start this phase without screenshots from the live Manus app.**

| # | Task | Priority | Status | Notes |
|---|---|---|---|---|
| 2.1 | ChatScreen scaffold (ConsumerStatefulWidget for ScrollController) | P0 | ⬜ Todo | |
| 2.2 | User message bubble (right-aligned, spring entrance) | P0 | ⬜ Todo | Animate: spring scale + fade |
| 2.3 | Assistant message (left-aligned, no bubble bg, spring entrance) | P0 | ⬜ Todo | |
| 2.4 | Streaming caret pulse on active assistant bubble | P0 | ⬜ Todo | AnimatedOpacity loop |
| 2.5 | Message list (ListView.builder, stable ValueKeys) | P0 | ⬜ Todo | Never rebuild messages above fold |
| 2.6 | Smart auto-scroll + scroll release/re-engage | P0 | ⬜ Todo | See CE-3 in PROJECT_PLAN.md |
| 2.7 | "Jump to latest" pill (fade in/out, never snap) | P0 | ⬜ Todo | AnimatedOpacity + jumpTo on tap |
| 2.8 | Input bar (multiline, animated height, max 6 lines) | P0 | ⬜ Todo | Keyboard avoidance: no gap, no overlap |
| 2.9 | Send button morph (plane → spinner → stop → plane) | P0 | ⬜ Todo | Morph not crossfade. See CONTEXT.md 4.5c |
| 2.10 | Copy button checkmark morph (1.5s revert + haptic) | P1 | ⬜ Todo | |
| 2.11 | Tool-call collapsible (spring expand/collapse, no scroll shift) | P1 | ⬜ Todo | See CONTEXT.md 4.4 |
| 2.12 | Inline image rendering in messages | P2 | ⬜ Todo | cached_network_image |
| 2.13 | Long-press text selection on streaming messages | P1 | ⬜ Todo | See CONTEXT.md 4.15 — hard problem |
| 2.14 | Inline error bubble (API error + retry button) | P0 | ⬜ Todo | Never dialogs |
| 2.15 | Network reconnect indicator (thin bar at top) | P1 | ⬜ Todo | connectivity_plus |
| 2.16 | Haptics (send, copy, chip tap, empty send) | P1 | ⬜ Todo | See CONTEXT.md 4.12 |

---

## Phase 3 — Home / Empty State

⚠️ **Do not start without screenshot of Home empty state.**

| # | Task | Priority | Status | Notes |
|---|---|---|---|---|
| 3.1 | Home screen scaffold (replaces boilerplate HomeScreen) | P0 | ⬜ Todo | |
| 3.2 | Suggestion chips (stagger animate in: 60ms, easeOutCubic, Y translate) | P0 | ⬜ Todo | Most weighted single animation |
| 3.3 | Chip → input field hero animation | P0 | ⬜ Todo | See CE-6 in PROJECT_PLAN.md |
| 3.4 | Model picker pill (icon morphs on mode change) | P1 | ⬜ Todo | |
| 3.5 | Home → Chat screen transition | P1 | ⬜ Todo | Shared element or custom route transition |

---

## Phase 4 — Auth + Onboarding + Splash

⚠️ **Do not start without screenshots of splash sequence and onboarding slides.**

| # | Task | Priority | Status | Notes |
|---|---|---|---|---|
| 4.1 | Splash screen (animated logo, gradient, spring timing) | P1 | ⬜ Todo | First impression — must match Manus exactly |
| 4.2 | Onboarding slide 1 (animated illustration) | P1 | ⬜ Todo | Illustrations animate in, not appear |
| 4.3 | Onboarding slide 2 | P1 | ⬜ Todo | |
| 4.4 | Onboarding slide 3 + "Get Started" CTA | P1 | ⬜ Todo | |
| 4.5 | Swipeable page indicator (spring physics between dots) | P1 | ⬜ Todo | |
| 4.6 | Auth screen (email field, Google button, Apple button) | P1 | ⬜ Todo | Mock flow — no real OAuth |
| 4.7 | Error shake animation on auth failure | P1 | ⬜ Todo | Snappy, not linear |
| 4.8 | Success transition (auth → home, animated) | P1 | ⬜ Todo | |

---

## Phase 5 — Chat Drawer + History

⚠️ **Do not start without screenshot of drawer open state.**

| # | Task | Priority | Status | Notes |
|---|---|---|---|---|
| 5.1 | Drawer scaffold (spring physics open/close) | P1 | ⬜ Todo | Damped, matches iOS sheet physics, on Android too |
| 5.2 | Grouped history list from Hive (Today/Yesterday/7days/Older) | P1 | ⬜ Todo | Section headers that stick |
| 5.3 | Search bar with 300ms debounce | P1 | ⬜ Todo | |
| 5.4 | Swipe-to-delete with undo snackbar | P1 | ⬜ Todo | Snackbar is allowed here (ephemeral confirm) |
| 5.5 | Long-press context menu (iOS-style scale + blur) | P1 | ⬜ Todo | Rename / Pin / Archive / Delete |
| 5.6 | Pull-to-refresh (drawer only — disabled in chat) | P2 | ⬜ Todo | |
| 5.7 | Infinite scroll (older conversations) | P2 | ⬜ Todo | |
| 5.8 | Pixel-stable underlying chat (no flicker behind drawer) | P1 | ⬜ Todo | RepaintBoundary on chat content |

---

## Phase 6 — Remaining Screens

| # | Task | Priority | Status | Notes |
|---|---|---|---|---|
| 6.1 | Mode Picker bottom sheet (Chat/Agent/Browse/Image) | P2 | ⬜ Todo | Icon morphs between modes |
| 6.2 | Attachment tray (animated reveal upward from input bar) | P2 | ⬜ Todo | Camera/Photo/File/Screen capture |
| 6.3 | Attachment thumbnails (remove buttons, drag-to-reorder) | P2 | ⬜ Todo | |
| 6.4 | Settings screen (iOS-grouped-list layout on both platforms) | P2 | ⬜ Todo | Theme toggle wired to AppTheme provider |
| 6.5 | Paywall/Subscription screen (UI only) | P3 | ⬜ Todo | Monthly/Yearly toggle, feature comparison |
| 6.6 | Empty state screens (no history, offline, error, rate limited) | P2 | ⬜ Todo | Custom SVG illustrations |

---

## Phase 7 — Polish + Performance

| # | Task | Priority | Status | Notes |
|---|---|---|---|---|
| 7.1 | Haptics audit (all interaction points per CONTEXT.md 4.12) | P1 | ⬜ Todo | |
| 7.2 | Semantics labels on all interactive elements | P1 | ⬜ Todo | TalkBack / VoiceOver |
| 7.3 | Font scale 200% layout testing | P1 | ⬜ Todo | Must not break any layout |
| 7.4 | Tap target audit (min 48×48dp) | P1 | ⬜ Todo | |
| 7.5 | WCAG AA color contrast check (both themes) | P1 | ⬜ Todo | |
| 7.6 | 200-message conversation performance profiling | P0 | ⬜ Todo | Target: 60fps, zero dropped frames |
| 7.7 | Memory profiling | P0 | ⬜ Todo | Target: <250MB RSS with 5 images |
| 7.8 | Cold start timing | P1 | ⬜ Todo | <2.5s Pixel 6 / <2.0s iPhone 13 |
| 7.9 | Release APK size check | P1 | ⬜ Todo | `flutter build apk --release` — target <35MB |
| 7.10 | `flutter analyze` zero warnings | P0 | ⬜ Todo | Must pass before submission |
| 7.11 | `dart format --set-exit-if-changed lib/ test/` | P0 | ⬜ Todo | |
| 7.12 | Demo video recording (5–7 min per spec) | P0 | ⬜ Todo | See CONTEXT.md section 9 for required scenes |
| 7.13 | Side-by-side recording with real Manus app (≥30 sec) | P0 | ⬜ Todo | Key submission deliverable |

---

## Completed Tasks Log

| Date | Task | Notes |
|---|---|---|
| 2026-05-15 | BLoC → Riverpod migration | Removed flutter_bloc, freezed, freezed_annotation, get_it, build_runner. Added flutter_riverpod ^2.6.1. Converted ProductCubit → ProductNotifier. |
| 2026-05-15 | AGENTS.md updated | Riverpod-only rules, forbidden patterns, provider organization convention. |
| 2026-05-15 | ScreenState<T> rewritten | Removed @freezed. Plain immutable class with manual copyWith. |
| 2026-05-15 | Providers structure created | core/providers/core_providers.dart + data/providers/product_data_providers.dart |
| 2026-05-15 | PROJECT_PLAN.md created | Full engineering plan, CE decisions, tradeoffs, roadmap. |
| 2026-05-15 | TASK_TRACKER.md created | This file. |
| 2026-05-15 | Phase 0 complete | Packages, theme system (light/dark), platform typography, Hive settings box, ThemeNotifier, Talker logger, GeminiService (raw Dio SSE), AppButton/AppTextField wrappers. flutter analyze: 0 issues. |

---

## Blocked Items

*None currently.*

Template for blocked items:
```
| BLOCK-N | Description | Blocked by | Resolution needed |
```

---

## Architecture Decision Log

*Quick reference. Full reasoning in PROJECT_PLAN.md.*

| ID | Decision | Chosen | Rejected |
|---|---|---|---|
| AD-1 | State management | flutter_riverpod (Notifier) | BLoC/Cubit, StateNotifier |
| AD-2 | DI | Riverpod Providers | GetIt |
| AD-3 | Code generation | None (plain immutable classes) | freezed, riverpod_generator |
| AD-4 | Gemini integration | Raw Dio + SSE parsing | google_generative_ai SDK |
| AD-5 | Streaming markdown | Custom block-segmented renderer | flutter_markdown |
| AD-6 | Auto-scroll | ScrollController + jumpTo | animateTo, reverse ListView |
| AD-7 | Chat state model | Notifier + explicit StreamSubscription | StreamProvider, AsyncNotifier |
| AD-8 | Typography | Platform split in ThemeData (null=SF Pro on iOS) | Inter everywhere |
| AD-9 | Chip animation | Hero with custom flight path | AnimatedPositioned |
| AD-10 | Local persistence | Hive | Isar |

---

## Pending Decisions

| ID | Decision | Options | Blocking |
|---|---|---|---|
| PD-1 | Hive storage format for chat messages | TypeAdapters vs JSON Map | Phase 1 |
| PD-2 | Animation library for splash/logo | flutter_animate vs Rive | Phase 4 |
| PD-3 | Markdown parser: line-by-line vs token buffer | Both valid | Phase 1 |

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
```

---

*Last updated: 2026-05-15 | Phase 0 in progress*
