# Manus AI Clone — Complete Interview Preparation Guide

> Every answer in this document is derived from the actual codebase. File paths,
> class names, and line references are precise. Read the code alongside this guide.

---

## 1. Project Overview

### What the app does

Manus is a pixel-faithful Flutter clone of the Manus AI Agent app — a chat-first
agentic interface backed by Google Gemini 2.5 Flash. Users can start conversations,
send prompts, receive streaming markdown responses in real time, and manage their
conversation history. The app is evaluated against the real Manus app on a physical
device; the bar is CRED / Linear / Arc-level polish.

### Core features

- Live streaming chat using Gemini API (SSE over raw Dio)
- Block-segmented markdown rendering without rebuild jank
- Smart auto-scroll that releases on user scroll and re-engages near bottom
- Ticker-driven smooth character reveal (72 chars/sec adaptive speed)
- Full conversation persistence via Hive (survives app restarts)
- Light / dark / system theme with Hive-persisted preference
- Chat drawer with grouping (Today / Yesterday / This week / Older), search (300ms debounce), swipe-to-delete, long-press context menu
- Mode picker sheet (Chat / Agent / Browse / Image) and attachment tray (Camera / Photos / Files / Screen)
- Suggestion chip fly-animation into the input field
- Stream cancellation via Dio CancelToken — actually cancels the HTTP request
- Platform-aware typography: SF Pro on iOS (null font family), Inter + JetBrains Mono on Android

### Main technical challenges

1. Streaming markdown without full tree rebuilds per token
2. Decoupling network token speed from render rate (60fps cap on display)
3. Auto-scroll synchronisation after layout grows asynchronously
4. Duplicate-key crash when markdown parser block count fluctuates
5. Platform font rendering (Inter on iOS = immediate rejection by evaluators)
6. Theme cross-fade without flash of unstyled content
7. Keyboard-safe empty-state layout on all device classes
8. True HTTP-level stream cancellation (not just ignoring tokens)

### Why the architecture/design choices were made

The spec (`CONTEXT.md`) explicitly mandates: Riverpod `Notifier` API, GoRouter,
Dio with CancelToken, Hive, no `StateNotifier`, no codegen, no `Navigator.push`.
Beyond compliance, these choices also make technical sense:

- **Riverpod `Notifier`** gives fine-grained `.select()` subscriptions so per-token
  state updates only rebuild the one widget that needs them.
- **Raw Dio SSE** exposes `CancelToken` — the `google_generative_ai` SDK wraps its
  own HTTP client so you cannot cancel at the network layer through it.
- **Custom block-segmented renderer** avoids `flutter_markdown`'s full re-parse
  on every token build call. At 10 tokens/second over 500 tokens that is 5,000
  full parse-and-render cycles — guaranteed jank on mid-range devices.
- **Hive with raw JSON maps** (no TypeAdapters) eliminates code-gen friction while
  still satisfying the persistence requirement.

### High-level app flow

```
SplashScreen (animated logo, 2s) → LoginScreen (mock OAuth buttons)
  → EmailLoginScreen → ConversationsScreen (list + drawer)
    → ChatScreen (streaming markdown, input bar, mode picker, attachment tray)
      → ProfileScreen → SubscriptionScreen
```

GoRouter handles all navigation. Each route maps to a `GoRoute` in
`lib/router/app_router.dart` with path constants in `lib/router/app_routes.dart`.

---

## 2. Architecture Deep Dive

### Folder structure

```
lib/
├── core/
│   ├── component/        # AppButton, AppTextField, CommonScreen (project wrappers)
│   ├── error/            # Failure, Exception (domain-layer error types)
│   ├── network/          # NetworkInfo interface + impl (connectivity_plus)
│   ├── presentation/     # ScreenState<T>, ScreenStateRenderer
│   ├── providers/        # core_providers.dart — Dio, Talker, Connectivity, NetworkInfo
│   └── usecase/          # Abstract UseCase<O,P> base class
├── data/
│   ├── data_sources/
│   │   ├── local/        # HiveService, ChatMessageLocalDataSource, ConversationLocalDataSource
│   │   └── remote/
│   │       ├── api_client.dart          # boilerplate REST client
│   │       └── gemini/gemini_service.dart  # SSE streaming implementation
│   ├── model/            # ChatMessageModel, ConversationModel (extend entities, add fromJson/toJson)
│   ├── providers/        # chat_data_providers.dart — repository providers
│   └── repositories/     # ChatMessageRepositoryImpl, ConversationRepositoryImpl
├── domain/
│   ├── entities/         # ChatMessage, Conversation, Product (pure Dart + Equatable)
│   ├── repositories/     # Abstract interfaces (ChatMessageRepository, ConversationRepository)
│   └── usecases/         # GetProducts (boilerplate, unused in chat feature)
├── presentation/
│   ├── auth/             # LoginScreen, EmailLoginScreen
│   ├── chat/
│   │   ├── notifier/     # ChatNotifier, ChatState
│   │   └── widgets/
│   │       ├── streaming_markdown/  # MarkdownBlock, MarkdownParser, StreamingMarkdownView
│   │       ├── attachment_tray.dart
│   │       ├── chat_drawer.dart
│   │       ├── mode_picker_sheet.dart
│   │       └── suggestion_chips.dart
│   ├── conversations/    # ConversationsScreen, ConversationsNotifier, ConversationsState
│   ├── profile/          # ProfileScreen (ConsumerWidget, theme switcher)
│   ├── splash/           # SplashScreen
│   ├── subscription/     # SubscriptionScreen (UI-only)
│   └── theme/notifier/   # ThemeNotifier (Hive-persisted ThemeMode)
├── router/               # AppRouter (GoRouter config), AppRoutes (path constants)
├── theme/                # AppTheme, AppColors, AppFonts, AppTextStyles
├── utility/              # Extensions, AppLevelUiHelper
└── values/               # GeminiConstants, AppStrings, AppDimensions, AppAssets
```

### Feature/module organisation

Each feature follows the same vertical slice:
`domain entity → repository interface → data source → repository impl →
data providers → notifier + state → screen`

The chat feature is the most complex:
- `ChatMessage` entity (domain) → `ChatMessageModel` (data, adds JSON)
- `ChatMessageRepository` interface → `ChatMessageRepositoryImpl` (data)
- `ChatMessageLocalDataSource` (Hive, box `chat_messages`) → `chat_data_providers.dart`
- `ChatNotifier` / `ChatState` (presentation) → `ChatScreen`

### State management approach and why

**`flutter_riverpod` with `Notifier<S>` and `FamilyNotifier<S,A>`.**

`chatProvider` is a `NotifierProvider.family<ChatNotifier, ChatState, String>` where
the arg is `conversationId`. This means one independent notifier instance per
conversation ID — they don't share state or interfere.

Why not `StreamProvider`: cannot cancel a stream and preserve partial content —
cancelling a `StreamProvider` resets state to `AsyncLoading`.

Why not `AsyncNotifier`: it is designed for a single initial `Future` lifecycle.
The `state` setter semantics conflict with continuous stream management where you
need to append tokens to state without resetting the loading indicator.

Why not BLoC: the spec explicitly requires Riverpod. Beyond compliance, Riverpod's
`.select()` operator allows subscribing to sub-fields of state, which is critical
for preventing full `ChatScreen` rebuilds on every streaming token.

### Dependency injection strategy

All DI is through Riverpod providers — no `GetIt`, no service locator.

Hierarchy:
```
core_providers.dart
  loggerProvider (Talker)       → used by everything
  dioProvider (Dio + TalkerDioLogger interceptor)
  connectivityProvider (Connectivity)
  apiClientProvider (ApiClient)
  networkInfoProvider (NetworkInfo)

chat_data_providers.dart
  chatMessageLocalDataSourceProvider → ChatMessageLocalDataSourceImpl
  chatMessageRepositoryProvider → ChatMessageRepositoryImpl(local)
  conversationLocalDataSourceProvider
  conversationRepositoryProvider

gemini/gemini_service.dart
  geminiServiceProvider → GeminiService(dio, talker)

presentation/chat/notifier/chat_notifier.dart
  chatProvider (family) → ChatNotifier
```

Providers are lazy by default — only instantiated when first watched. This means
`geminiServiceProvider` is not created until the first `ChatScreen` opens, keeping
cold-start fast.

### Repository/service pattern usage

The Repository pattern provides a clean seam between the domain and data layers:

```
ChatNotifier.sendMessage()
  → ref.read(geminiServiceProvider).streamResponse(...)    [remote]
  → ref.read(chatMessageRepositoryProvider).saveMessage()  [local]
```

`GeminiService` is not a repository — it is a service that produces a `Stream<String>`.
It lives in `data/data_sources/remote/gemini/` and is consumed directly by `ChatNotifier`
via `geminiServiceProvider`. This avoids introducing a `ChatStreamRepository` layer
that would add boilerplate with no benefit (there is no local fallback for streaming).

Repositories (`ChatMessageRepositoryImpl`, `ConversationRepositoryImpl`) wrap `Either<Failure, T>`
returns so the notifier never sees raw exceptions — all errors are typed `Failure` subclasses.

### Data flow across layers

```
User taps send
  ↓
_ChatScreenState._sendMessage()
  ↓
ChatNotifier.sendMessage(text)           [presentation → data via ref.read]
  ↓ optimistic state update (user bubble + thinking indicator appear immediately)
  ↓
GeminiService.streamResponse(...)        [data: raw Dio SSE]
  ↓ each token via StreamSubscription.listen
ChatNotifier: state = state.copyWith(streamingContent: accumulated)
  ↓
ref.listen in _StreamingBubbleState       [presentation: no rebuild]
  _source = next (just assignment, no setState)
  ↓
Ticker._onTick() at ≤60fps              [presentation: controlled reveal]
  setState(() => _displayed = ...)
  ↓
StreamingMarkdownView rebuilds          [presentation: only this widget]
  ↓
MarkdownParser.parse(_displayed)
  ↓
_CachedBlockWidgets (completed blocks, never rebuilt) +
_ActiveBlockWidget (in-progress block, rebuilds per tick)
```

### Separation of concerns

- **Domain**: Pure Dart. No Flutter imports. `ChatMessage`, `Conversation` are plain
  `Equatable` classes. Repository interfaces declare contracts. No business logic.
- **Data**: Implements domain interfaces. Handles Hive (local) and Dio (remote).
  Models extend entities and add serialisation. Providers wire everything together.
- **Presentation**: `ConsumerWidget` screens are purely reactive — zero business
  logic. All logic lives in `Notifier`s. Screens call notifier methods via
  `ref.read(provider.notifier).method()`. Navigation intent is passed via callbacks
  (`onTap`, `onConversationTap`) — notifiers never hold `BuildContext`.
- **Theme**: `AppColors` → `AppFonts` → `AppTheme` → `MaterialApp`. No widget
  reads raw `Color` values — everything flows through `ColorScheme` tokens.

### Scalability considerations

- `NotifierProvider.family` for `chatProvider` means adding more conversations is O(1)
  — each conversation gets its own isolated notifier.
- Block-segmented markdown renderer scales to arbitrarily long messages because
  completed blocks are never rebuilt.
- Hive's flat-map storage (key = conversationId, value = list of JSON maps) works
  fine for hundreds of conversations but would need migration to Isar for tens of
  thousands with complex queries.
- `ListView.builder` with stable `ValueKey` IDs ensures only visible items are
  built even in 200-message conversations.

### Trade-offs of the chosen architecture

| Trade-off | What was sacrificed | What was gained |
|-----------|--------------------|--------------------|
| No TypeAdapters in Hive | No compile-time schema safety | Zero code-gen setup friction |
| Manual `copyWith` on all state classes | ~10 extra lines per class | No `build_runner`, no `@freezed` |
| No `UseCase` layer for chat feature | Slight coupling between notifier and repository | Faster development, less boilerplate |
| Raw JSON map storage | Type safety at persistence boundary | Schema flexibility, easy to iterate |
| `FamilyNotifier` per conversation | One notifier instance per open conversation | Perfect isolation, no cross-contamination |

### Alternative approaches and why they were not chosen

- **BLoC**: More verbose than Riverpod for per-token streaming. Would require
  `StreamBloc` with complex event/state mapping. Spec forbids it anyway.
- **Provider (vanilla)**: Lacks `.select()` — would require `ProxyProvider` chains
  to avoid over-rebuilding.
- **GetX**: No compile-time DI, opinionated navigation conflicts with GoRouter
  requirement, discouraged by spec.
- **Isar**: Would give better query performance than Hive for large datasets but
  requires more setup. Hive was already in the boilerplate.

---

## 3. Streaming Chat & Growing Bubble System

### How streaming responses work (network layer)

`GeminiService.streamResponse()` in `lib/data/data_sources/remote/gemini/gemini_service.dart`:

1. Sends a `POST` to `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse&key={KEY}`
2. Uses `ResponseType.stream` so Dio gives back a `ResponseBody` with a raw byte stream
3. `_parseSSE()` reads the byte stream chunk by chunk, decodes UTF-8, accumulates
   incomplete lines in a `StringBuffer`, splits on `\n`, extracts `data:` lines
4. Each `data:` line is JSON-decoded via `_extractToken()` which navigates:
   `candidates[0].content.parts[0].text`
5. Tokens are `yield`-ed as `String`s forming a `Stream<String>`

The critical design decision: `cancelToken` is checked inside `_parseSSE` on every
chunk (`if (cancelToken.isCancelled) return`), ensuring no tokens are emitted after
the user taps Stop — even if bytes are already in the Dart buffer.

### SSE parser details

```dart
// lib/data/data_sources/remote/gemini/gemini_service.dart:89-128
Stream<String> _parseSSE(Stream<List<int>> byteStream, CancelToken cancelToken) async* {
  final buffer = StringBuffer();
  await for (final chunk in byteStream) {
    if (cancelToken.isCancelled) return;
    buffer.write(utf8.decode(chunk, allowMalformed: true));
    final raw = buffer.toString();
    buffer.clear();
    final lines = raw.split('\n');
    buffer.write(lines.removeLast());  // keep incomplete last line
    for (final line in lines) {
      if (!trimmed.startsWith('data:')) continue;
      final token = _extractToken(jsonStr);
      if (token != null && token.isNotEmpty) yield token;
    }
  }
}
```

The `lines.removeLast()` trick is essential: network chunks do not align with SSE
line boundaries. Without this, you would attempt to JSON-decode a partial line and
get parse errors on every other token. The incomplete line is kept in `buffer` and
prepended to the next chunk.

### How the growing message bubble is implemented

The bubble rendering is a 3-layer architecture:

**Layer 1 — State (`ChatState.streamingContent`)**

`streamingContent` is stored outside the `messages` list. The key insight: if you
put the accumulating string inside a `ChatMessage` object in `messages`, every
token update replaces the entire `messages` list → every `.select(messages)` watcher
rebuilds on every token.

By keeping it separate: `ref.watch(chatProvider.select((s) => (status, messages,
conversation, error)))` in `ChatScreen.build()` never sees token updates.

**Layer 2 — Ticker-driven render buffer (`_StreamingBubbleState`)**

`_StreamingBubble` is a `ConsumerStatefulWidget` with `SingleTickerProviderStateMixin`.
Two strings:
- `_source`: updated via `ref.listen` (no rebuild, just assignment)
- `_displayed`: the substring shown to the user, grown by the Ticker

The Ticker fires at vsync frequency (≤60fps). On each tick:
```
behind = _source.length - _displayed.length
if behind > 280: jump immediately (buffer too far behind)
else: speed = 72.0 * (1.0 + 2.0 * behind / 280)   // 72–216 chars/sec
      pendingChars += speed * dtSec
      n = pendingChars.floor()
      _displayed = _source.substring(0, _displayed.length + n)
```

**Layer 3 — Block-segmented markdown (`StreamingMarkdownView`)**

`_displayed` is fed to `StreamingMarkdownView` which calls `MarkdownParser.parse()`,
producing `completedBlocks` (rendered once, cached) and `activeBlock` (rebuilt per tick).

### How incremental rendering works

`MarkdownParser` (line-by-line state machine in `lib/presentation/chat/widgets/streaming_markdown/markdown_parser.dart`):

1. Splits the full content string on `\n`
2. Identifies each line's `BlockType` via regex: `^#{1,6}\s` → heading, `^> ` → blockquote, etc.
3. Maintains current `active` block; when a blank line or type switch occurs, the
   active block is moved to `completedBlocks` and a new one starts
4. Code fences (```` ``` ````) are handled specially: `inCodeBlock` flag buffers
   all lines until closing ` ``` ` then emits a single `codeBlock` block

`StreamingMarkdownView` uses an append-only list `_cachedWidgets`:
```dart
for (var i = _cachedWidgets.length; i < completed.length; i++) {
  _cachedWidgets.add(_CachedBlockWidget(key: ValueKey(i), block: completed[i]));
}
```
Starting at `_cachedWidgets.length` (not 0) is the critical fix for the duplicate-key
crash: if the parser ever returns fewer `completedBlocks` due to re-parse edge cases,
the loop simply adds nothing rather than re-adding existing blocks.

`_CachedBlockWidget` is a `StatefulWidget` that builds its widget tree exactly once
in `initState`. It has no `didUpdateWidget` — intentional. Once a block is complete,
its content never changes.

### Why this rendering strategy was used

The alternative — `flutter_markdown` with `Markdown(data: fullText)` — re-parses
the entire string on every `setState`. At 72 chars/sec with 60fps ticks, that is
60 full Markdown parse operations per second. The `flutter_markdown` parser (Dart's
`markdown` package) converts the full string to an AST, then builds a widget tree.
This is O(n) in content length per frame — guaranteed jank on a mid-range phone
by the time the response reaches 500 characters.

With the block-segmented approach: per tick, the parser processes the full string
once (O(n)), but the widget tree only rebuilds one block — the active one. All
`_CachedBlockWidget` instances have `RepaintBoundary` wrapping them (set in
`_CachedBlockWidgetState.initState`) preventing raster-layer re-rendering.

### Performance considerations

- `ref.listen` (not `ref.watch`) for `streamingContent` in `_StreamingBubbleState.build()`:
  `ref.listen` fires a callback without causing a rebuild. The `_source` assignment
  happens in the callback — zero frames consumed.
- Ticker caps render rate at vsync (≤60fps) regardless of network burst speed.
- `RepaintBoundary` on `_CachedBlockWidget`: completed blocks have their own raster
  layer. The GPU composites them without re-rasterising when only the active block changes.
- `ChatScreen` selects only 4 fields from `ChatState`:
  ```dart
  ref.watch(chatProvider(id).select((st) => (status, messages, conversation, error)))
  ```
  `streamingContent` is deliberately excluded. Without `.select()`, every token
  would trigger a full `ChatScreen.build()`, re-running `_buildMessageList()`,
  rebuilding `ListView.builder`, etc.

### Rebuild optimisation techniques

1. **`.select()` for precise subscriptions** — `_StreamingBubble` independently
   watches `streamingContent` via its own listener; `ChatScreen` watches everything else
2. **`_StreamingBubbleEntry` as `StatefulWidget`** — separates the entrance animation
   (`AnimationController`) from the streaming content. Without this, `flutter_animate`'s
   `.animate()` would restart the slide-up entrance animation on every token rebuild
3. **`RepaintBoundary`** on completed blocks prevents GPU re-rasterisation
4. **`_CachedBlockWidget` never calls `didUpdateWidget`** — completed blocks are
   truly immutable from Flutter's perspective
5. **Ticker over `AnimationController`** for character reveal — a single `Ticker`
   running at vsync beats calling `setState` from a `StreamSubscription.listen` which
   fires at network speed (unbounded rebuilds per second)

### Auto-scroll synchronisation while bubble grows

The scroll callback chain:
```
_StreamingBubbleState._onTick()
  → setState (grows _displayed → grows widget → changes maxScrollExtent)
  → WidgetsBinding.instance.addPostFrameCallback((_) {
       widget.onScroll?.call();   // fires AFTER layout
     })
  ↑ wired through: _StreamingBubble.onScroll
                 → _StreamingBubbleEntry.onScroll
                 → _buildMessageList passes: onScroll: () { if (_isNearBottom) _jumpToBottom(); }
```

`addPostFrameCallback` is the essential synchronisation primitive: the bubble's
height grows in the current frame, `maxScrollExtent` updates during layout, and
the scroll command fires in the post-frame callback — guaranteeing it reads the
correct `maxScrollExtent`.

`_jumpToBottom` uses `animateTo(120ms, easeOut)` not `jumpTo`:
- `jumpTo` was the original choice (recommended in `PROJECT_PLAN.md` for avoiding
  competing animations at 10 tokens/sec)
- `animateTo` with 120ms creates a smooth glide that avoids the teleporting feel
- At 60fps with ~1.4 chars per tick at base speed, the 120ms animation completes
  before the next scroll trigger fires, so animations do not compound

`_pendingScrollJump` flag prevents queuing multiple `addPostFrameCallback` scroll
commands in the same frame:
```dart
void _jumpToBottom() {
  if (_pendingScrollJump) return;
  _pendingScrollJump = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _pendingScrollJump = false;
    _scrollController.animateTo(...);
  });
}
```

### Problems faced and solutions

| Problem | Root cause | Solution |
|---------|-----------|---------|
| Duplicate key crash `[<8>]` | `_lastCompletedCount` tracked loop start; parser block count fluctuated down under certain inputs, causing re-insertion of existing keys | Removed `_lastCompletedCount`; use `_cachedWidgets.length` as loop start — append-only |
| Auto-scroll not firing after ticker refactor | `ref.listen(streamingContent)` scroll trigger fired at network speed; layout grew at ticker speed; `maxScrollExtent` hadn't updated yet when scroll was called | Removed network-speed scroll listener; added `addPostFrameCallback` inside `_onTick` after `setState` |
| Entrance animation restarting on every token | `flutter_animate` restarts animations when the widget rebuilds; `_StreamingBubble` was rebuilding per tick | Introduced `_StreamingBubbleEntry` as a `StatefulWidget` that owns the `AnimationController` and only rebuilds the entrance animation once |
| Full ChatScreen rebuilding on every token | `ref.watch(chatProvider(...))` without `.select()` | Added `.select()` with a Dart 3 record that excludes `streamingContent` |

### Trade-offs between smoothness vs performance

- **Base speed 72 chars/sec**: Feels like fast reading cadence (≈300 words/min).
  Faster would feel artificial; slower would feel laggy behind the network.
- **Jump threshold 280 chars**: If the network delivers >280 chars ahead of display,
  the UI jumps to catch up. This prevents the streaming bubble from being frozen on
  old content when the stream ends and `StaticMarkdownView` is about to take over.
- **Adaptive speed (1× to 3×)**: A small buffer means the user is reading at a
  comfortable pace. A growing buffer means the network is fast — increase speed to
  keep up. This gives the "natural fast typing" feel of ChatGPT's streaming.

### How ChatGPT/Claude-like streaming UX was replicated

ChatGPT and Claude use the same conceptual pattern:
1. Network delivers tokens at variable speed (bursty)
2. A render buffer decouples network speed from display speed
3. The display grows at a controlled rate that feels like fast typing
4. When streaming ends, the display catches up instantly

The ticker approach achieves exactly this. The 72 chars/sec base rate corresponds
to approximately 14 characters per 16ms frame — imperceptibly fast but not
overwhelming. The `AnimatedSwitcher` between `_ThinkingIndicator` and
`_StreamingContent` provides the smooth "thinking → responding" transition.

### Why certain animation techniques were avoided

- **No `.animate()` on the streaming bubble directly**: Would restart entrance
  animation on every rebuild. `_StreamingBubbleEntry` owns the `AnimationController`.
- **No `AnimatedSize` wrapping individual blocks**: `AnimatedSize` has its own
  `Ticker` and runs a size interpolation — adding 60 more interpolations per second
  per block would be catastrophic. Blocks just grow naturally as text appends.
- **No `TweenAnimationBuilder` for character reveal**: Would require managing
  tween targets — complex and still rebuilds the widget on every tween tick.

---

## 4. Markdown Rendering System

### Markdown library used

`flutter_markdown: ^0.7.4` is in `pubspec.yaml` but is used only for **completed
(non-streaming) blocks** via `_MarkdownBodyBlock` in `streaming_markdown_view.dart`.
The streaming path uses `SelectableText` (raw text, no parsing overhead) via
`_ActiveBlockWidget`.

### Why `flutter_markdown` is used only for completed blocks

During streaming, the active block changes every 16ms. Parsing markdown on every
tick is wasteful and produces partially-valid markdown (e.g., unclosed bold `**`,
incomplete list items) that renders incorrectly. `SelectableText` shows the raw
text without any markdown processing — which is acceptable because partial markdown
looks like plain text, not broken formatting.

Once a block is completed (moved to `completedBlocks`), it is passed to
`_CachedBlockWidget` which creates a `_MarkdownBodyBlock`. This widget calls
`MarkdownBody()` from `flutter_markdown` with the full, well-formed block content.
Since this widget is built exactly once (in `initState`) and wrapped in
`RepaintBoundary`, the markdown parse cost is paid once per block.

### Custom markdown rendering logic

`MarkdownParser` is a hand-written line-by-line state machine:

```dart
static BlockType _classifyLine(String line) {
  if (RegExp(r'^#{1,6}\s').hasMatch(line)) return BlockType.heading;
  if (line.startsWith('> ')) return BlockType.blockquote;
  if (RegExp(r'^[-*+]\s').hasMatch(line)) return BlockType.bulletList;
  if (RegExp(r'^\d+\.\s').hasMatch(line)) return BlockType.numberedList;
  if (line.trimRight() == '---' || line.trimRight() == '***') return BlockType.horizontalRule;
  return BlockType.paragraph;
}
```

`_canContinue(current, next)` merges consecutive same-type lines into one block
(paragraphs absorb consecutive paragraph lines; lists absorb consecutive list lines).

`_isBlockTerminated(lines, i)` looks ahead one line — if the next line is blank or
a different type, the current block is considered complete.

Code fences use a dedicated `inCodeBlock` flag and `codeLang` variable. The closing
` ``` ` is detected by `line.trimRight() == '```'` — handles trailing whitespace.

### Streaming markdown challenges

**Partial inline markup**: A token boundary may fall mid-bold (`**hel` `lo**`).
During streaming, this renders as plain text (`**hello**`) because `_ActiveBlockWidget`
uses `SelectableText`. Once the paragraph block is complete, `_MarkdownBodyBlock`
re-renders it correctly with bold formatting. This is the core trade-off: accurate
inline formatting is deferred to block completion.

**Incomplete code fence**: If a streaming response is stopped mid-code-block, the
`inCodeBlock` flag is true but no closing ` ``` ` has arrived. In this case,
`MarkdownParser.parse()` will keep the code content in `activeBlock` indefinitely.
`_ActiveBlockWidget` handles `BlockType.codeBlock` by rendering `CodeBlockWidget`
directly — so the code renders with proper monospace styling even without a closing
fence.

**Block count fluctuation**: Rapid token bursts can cause the parser to emit
different numbers of `completedBlocks` between two calls to `MarkdownParser.parse()`.
This was the root cause of the duplicate-key crash. Fixed by the append-only cache.

### Code block widget

`CodeBlockWidget` (`lib/presentation/chat/widgets/streaming_markdown/code_block_widget.dart`):
- `language` label top-left (nullable, omitted if absent)
- `_Header` is `StatefulWidget` with `_copied` bool for copy animation
- Copy success: icon switches `Icons.copy_outlined` → `Icons.check`, label `'Copy'` → `'Copied'`
  for 2 seconds via `Future.delayed`
- `SingleChildScrollView(scrollDirection: Axis.horizontal)` for long lines
- `SelectableText` with `AppFonts.monospace()` — Courier on iOS (SF Mono fallback),
  JetBrains Mono on Android via `GoogleFonts.jetBrainsMono()`

### Rich text rendering performance

- `MarkdownStyleSheet` in `_MarkdownBodyBlock` sets styles for `p`, `h1`, `h2`,
  `h3`, `code`, `blockquoteDecoration` using `AppTextStyles` and `AppFonts`
- `selectable: true` on `MarkdownBody` enables text selection on completed blocks
- Heading/paragraph/list styles all flow through `Theme.of(context).colorScheme`
  so theme switching works without additional logic

### Why this approach is production-friendly

1. No custom parser for inline markdown — `flutter_markdown` handles bold/italic/
   inline code/links correctly on completed blocks
2. Partial blocks always render as plain text — never broken half-rendered markup
3. Code blocks render correctly mid-stream because `_ActiveBlockWidget` handles
   `BlockType.codeBlock` explicitly
4. The `RepaintBoundary` + build-once pattern means a 500-word response with 10 code
   blocks causes exactly 10 `MarkdownBody` parses total — not one per token

---

## 5. Animation System

### Bubble entrance animation

`_StreamingBubbleEntry` owns a 220ms entrance animation:
- `FadeTransition` (opacity: 0 → 1 via `CurvedAnimation(Curves.easeOut)`)
- `SlideTransition` (Y: 0.06 → 0 via same curve)

This is a `StatefulWidget` that wraps `_StreamingBubble`. The separation is critical:
`_StreamingBubble` rebuilds on every Ticker tick. If `flutter_animate`'s `.animate()`
was applied to a widget that rebuilds, the entrance animation restarts on every tick.
By isolating the `AnimationController` in `_StreamingBubbleEntryState`, the entrance
plays once and `_StreamingBubble` rebuilds freely underneath it.

### Thinking / blinking cursor

`_ThinkingIndicator` uses `flutter_animate`'s `.animate(onPlay: (c) => c.repeat(reverse: true))`:
- A 8×8 blue dot pulsing via `.scaleXY(begin: 0.55, end: 1.0, 850ms)` + `.fadeIn(begin: 0.4)`
- `AnimatedSwitcher` with 300ms `FadeTransition` wraps the switch from `_ThinkingIndicator`
  to `_StreamingContent` — seamless reveal when first token arrives

`_BlinkingCursor` uses the same repeat pattern: `|` character fades out/in via
`.fadeOut(500ms, repeat(reverse))`.

### Attachment tray reveal

`AnimatedSize` wraps the `AttachmentOptionsTray`:
```dart
AnimatedSize(
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeInOut,
  child: _attachTrayOpen ? AttachmentOptionsTray(...) : const SizedBox.shrink(),
)
```
`AnimatedSize` implicitly animates the height from 0 to content height. No
`AnimationController` needed — Flutter handles the interpolation.

`AnimatedRotation` for the paperclip → × button:
```dart
AnimatedRotation(
  turns: attachTrayOpen ? 0.125 : 0.0,  // 0.125 * 360° = 45°
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  child: Icon(Icons.add, ...),
)
```

### Mode icon swap

`AnimatedSwitcher` with `ScaleTransition` in `_ChatInputBar`:
```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
  child: Icon(currentMode.icon, key: ValueKey(currentMode), ...),
)
```
The `ValueKey(currentMode)` is essential — without it, `AnimatedSwitcher` cannot
distinguish old from new and would not animate.

### Send/Stop button

`_SendStopButton` uses:
- `AnimatedContainer` (180ms) for the background colour change (grey → black/white)
- `AnimatedSwitcher` with `ScaleTransition` for `Icons.arrow_upward_rounded` ↔ `Icons.stop_rounded`
- Badge dot (`Positioned` overlay) with `attachmentCount > 0` condition

### Suggestion chips entrance

`flutter_animate` with stagger in `_SuggestionChipItem`:
```dart
.animate()
.fadeIn(duration: 350.ms, delay: delayMs.ms, curve: Curves.easeOut)
.slideY(begin: 0.35, end: 0, duration: 350.ms, delay: delayMs.ms, curve: Curves.easeOutCubic)
.scaleXY(begin: 0.92, end: 1.0, duration: 350.ms, delay: delayMs.ms, curve: Curves.easeOutCubic)
```
`delayMs = 300 + index * 80` — 80ms stagger between chips.

### Chip-to-input fly animation

`ChipFlyAnimation` is an `OverlayEntry` that:
1. Captures source rect (`chipBox.localToGlobal(Offset.zero) & chipBox.size`)
2. Captures destination rect (`inputBox.localToGlobal(Offset.zero) & inputBox.size`)
3. Renders a `Positioned` widget that interpolates all four corners over 370ms
4. Border radius morphs from 20.0 (pill) to 24.0 (input bar radius)
5. Opacity fades from 1.0 to 0.0 in the last 25% of the animation
6. On completion: `entry.remove()` + `_inputController.text = text`

This uses `AnimatedBuilder` on a `CurvedAnimation(Curves.easeInOutCubic)` — not
`Hero` (which requires the same widget key in both tree locations and would complicate
the input bar layout).

### Theme switch animation

`MaterialApp` internally wraps `ThemeData` changes in `AnimatedTheme` with
`kThemeAnimationDuration` (200ms). No custom animation code needed — the comment
in `main.dart` documents this explicitly. Changing `themeMode` in `ThemeNotifier`
triggers an automatic cross-fade across all `Theme.of(context)` consumers.

### Implicit vs explicit animations

| Animation | Type | Widget |
|-----------|------|--------|
| Bubble entrance | Explicit | `AnimationController` in `_StreamingBubbleEntryState` |
| Send button bg | Implicit | `AnimatedContainer` |
| Send icon swap | Explicit | `AnimatedSwitcher` + `ScaleTransition` |
| Tray reveal | Implicit | `AnimatedSize` |
| Attach rotate | Implicit | `AnimatedRotation` |
| Mode icon swap | Explicit | `AnimatedSwitcher` + `ScaleTransition` |
| Chip entrance | Declarative | `flutter_animate` |
| Chip fly | Explicit | `AnimationController` in `_ChipFlyAnimationState` |
| Theme switch | Automatic | `AnimatedTheme` inside `MaterialApp` |
| Filter tabs | Implicit | `AnimatedContainer` |

Implicit animations are preferred for state-driven property changes (colour, size).
Explicit controllers are needed when the animation must fire exactly once (entrance)
or must be precisely timed to a user gesture (chip fly).

### Maintaining 60fps

- `RepaintBoundary` on completed markdown blocks
- `ConsumerStatefulWidget` with `Ticker` instead of `StreamSubscription.listen`
  for character reveal (caps at vsync)
- `_StreamingBubbleEntry` isolates entrance animation from content rebuilds
- `ref.watch(...).select(...)` minimises the rebuild surface
- `AnimatedSwitcher` for send/mode icons avoids layout recalculation

---

## 6. Auto Scroll & Chat UX

### Auto-scroll implementation

`_ChatScreenState` holds:
- `_scrollController`: bound to `ListView`
- `_showJumpPill`: drives `AnimatedOpacity` on the pill
- `_pendingScrollJump`: debounce flag preventing duplicate `addPostFrameCallback` calls

`_isNearBottom` getter:
```dart
bool get _isNearBottom {
  if (!_scrollController.hasClients) return true;
  final pos = _scrollController.position;
  return pos.maxScrollExtent - pos.pixels < 40;
}
```
40px threshold — small enough to feel "at bottom", large enough to handle rubber-band
overscroll and partial pixel snapping.

`_onScrollChange` listener:
```dart
void _onScrollChange() {
  final show = !_isNearBottom;
  if (show != _showJumpPill) setState(() => _showJumpPill = show);
}
```
`setState` is only called when `_showJumpPill` actually changes — avoids triggering
builds on every scroll pixel.

### Scroll synchronisation while streaming

The scroll command fires from the Ticker callback (inside `_StreamingBubbleState._onTick`):
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  widget.onScroll?.call();
});
```
This runs after the frame that grew `_displayed` has been laid out. The
`_scrollController.animateTo(maxScrollExtent)` call now reads the correct,
updated `maxScrollExtent`.

Without `addPostFrameCallback`, the scroll fires before Flutter has laid out the
new characters — `maxScrollExtent` still reflects the pre-growth value — and the
chat appears to not scroll.

### Preventing jumpy scrolling

`_pendingScrollJump` ensures at most one `animateTo` is in flight at a time:
```dart
void _jumpToBottom() {
  if (_pendingScrollJump) return;
  _pendingScrollJump = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _pendingScrollJump = false;
    _scrollController.animateTo(maxScrollExtent, duration: 120ms, curve: Curves.easeOut);
  });
}
```
At 60fps with one scroll per frame, without this flag you would queue 60 competing
`animateTo` calls per second — visible stutter as each animation is interrupted by
the next.

### User-scroll interruption handling

If `_isNearBottom` returns false when `_onScrollChange` fires, `_showJumpPill`
is set to true and the pill fades in. The scroll callback chain:
```dart
onScroll: () { if (_isNearBottom) _jumpToBottom(); }
```
If the user is not near bottom, `_jumpToBottom` simply doesn't execute. Auto-scroll
is suppressed until the user scrolls back to within 40px of the bottom (or taps the pill).

There is no explicit "auto-scroll enabled" boolean — the `_isNearBottom` check
acts as the re-engagement gate.

### "Jump to latest" pill

`_JumpToLatestPill` wrapped in `AnimatedOpacity`:
```dart
AnimatedOpacity(
  opacity: _showJumpPill ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 200),
  child: IgnorePointer(
    ignoring: !_showJumpPill,
    child: _JumpToLatestPill(onTap: () {
      _jumpToBottom();
      setState(() => _showJumpPill = false);
    }),
  ),
)
```
`IgnorePointer` prevents taps on the invisible pill. The 200ms fade is smooth and
doesn't draw attention when it appears during normal conversation.

### Keyboard interaction handling

`LayoutBuilder + SingleChildScrollView + ConstrainedBox(minHeight)` pattern in
`SuggestionChipsEmptyState`:
```dart
LayoutBuilder(builder: (context, constraints) {
  return SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: constraints.maxHeight),
      child: Center(child: Column(...)),
    ),
  );
})
```
When the keyboard opens, `constraints.maxHeight` shrinks. `ConstrainedBox(minHeight)`
allows the content to be its natural height (not forced to the smaller space),
and `SingleChildScrollView` makes the overflow scrollable rather than throwing
a 222px overflow error.

`ClampingScrollPhysics` prevents iOS elastic overscroll which would look wrong
on the empty state.

---

## 7. State Management Deep Dive

### State management library

`flutter_riverpod ^2.6.1` with `Notifier<S>` (sync build) and `FamilyNotifier<S,A>` (parameterised).
No `AsyncNotifier` (the chat stream is continuous, not a single future lifecycle).
No `StateNotifier` (deprecated). No `riverpod_generator` (forbidden by spec).

### Reactive flow

```
ChatNotifier.sendMessage(text)
  state = state.copyWith(streamingContent: accumulated)  // on each token

_StreamingBubbleState.build()
  ref.listen(chatProvider(id).select((s) => s.streamingContent ?? ''),
    (_, next) => _source = next)     // no rebuild, pure assignment
```

`ref.watch` triggers rebuild. `ref.listen` triggers a callback. The distinction is
what makes the streaming architecture work:
- `_StreamingBubble.build()` calls `ref.listen` → `_source` is updated silently
- The Ticker's `setState` is the only rebuild trigger — at vsync rate, not network rate

### Local vs global state

| State | Location | Why |
|-------|----------|-----|
| `streamingContent` | `ChatState` (Riverpod) | Needs to survive widget rebuilds, must be accessible by `_StreamingBubble` |
| `_displayed` | `_StreamingBubbleState` | Local widget state, ephemeral, does not need persistence |
| `_hasText` | `_ChatScreenState` | Local, just drives send button enable/disable |
| `_attachTrayOpen` | `_ChatScreenState` | Local UI state |
| `_currentMode` | `_ChatScreenState` | Local until a real backend is added |
| `themeMode` | `ThemeNotifier` (Riverpod + Hive) | Global, persisted, affects root MaterialApp |
| `conversations` | `ConversationsNotifier` (Riverpod + Hive) | Global, shared by drawer and list screen |

### State isolation techniques

`chatProvider` is a `.family` provider keyed by `conversationId`. Each conversation
gets its own `ChatNotifier` instance with independent `_cancelToken`, `_streamSub`,
`_source`. Opening two conversations simultaneously would not interfere.

`ConversationsState.displayed` computed getter applies search + filter:
```dart
List<Conversation> get displayed {
  // filter by filter enum, then by searchQuery
}
```
This avoids storing derived state — filtering is computed on-read, keeping the
single source of truth as the raw `conversations` list.

### Preventing unnecessary widget rebuilds

1. `ChatScreen` wraps its watch in `.select()` returning a Dart 3 record excluding `streamingContent`
2. `ConversationsScreen` is `ConsumerStatefulWidget` — `build()` only runs when
   `conversationsProvider` changes, not on every animation frame
3. `_ConversationTile` is `StatelessWidget` — receives all data as constructor params,
   never has its own state to trigger rebuilds
4. `_CachedBlockWidget` builds once and stops

### Async handling

`ChatNotifier.sendMessage()` uses `async` only for I/O:
- `_persistMessage()` and `_updateConversationMeta()` are fire-and-forget via
  `.catchError()` — they do not block the stream start
- The Gemini stream starts immediately after the optimistic state update

`ChatNotifier.build()` triggers `_loadConversation()` via `Future.microtask()`:
```dart
@override
ChatState build(String arg) {
  ref.onDispose(_cleanup);
  Future.microtask(() => _loadConversation(arg));
  return const ChatState();
}
```
`Future.microtask` schedules the load after the current build cycle completes,
so the provider does not block `ProviderScope` initialisation.

### Error state handling

Errors flow via `Either<Failure, T>`:
```dart
final result = await convRepo.getAllConversations();
result.fold(
  (failure) => state = state.copyWith(status: ChatStatus.error, error: failure.message),
  (list) => ...,
);
```
Stream errors are caught in `StreamSubscription.onError`:
```dart
onError: (Object e) {
  if (e is DioException && CancelToken.isCancel(e)) {
    _finalizeStream(assistantMsgId, accumulated, stopped: true);
  } else {
    _markStreamError(assistantMsgId, accumulated);
  }
}
```
`DioException` with `CancelToken.isCancel` is treated as user-initiated stop, not
an error. All other errors set `MessageStatus.error` on the assistant message,
which `_AssistantMessage` renders with an inline error badge.

### Trade-offs vs alternatives

| Alternative | Why not used |
|-------------|-------------|
| BLoC | More boilerplate; `StreamBloc` events for per-token state would be verbose; spec prohibits |
| GetX | No compile-time DI; navigation conflicts with GoRouter requirement |
| Provider (vanilla) | No `.select()` — would over-rebuild; no built-in `.family` |
| Riverpod `StateNotifier` | Deprecated; signals outdated API knowledge |
| `StreamProvider` | Cannot cancel without losing partial state |

---

## 8. Networking & Streaming Layer

### API architecture

All network I/O flows through `GeminiService`. It is a plain Dart class (not a
repository) created by `geminiServiceProvider` which injects `Dio` and `Talker`.

`Dio` is configured in `core_providers.dart` with `TalkerDioLogger` interceptor
that logs requests (not response bodies — streaming responses would flood logs).

### Streaming implementation

SSE (Server-Sent Events) over HTTP/2 POST. Not WebSocket. Not `dart:io` HttpClient.

Why POST for SSE: Gemini's streaming API requires POST (with the prompt body) and
returns an SSE-formatted response. The `?alt=sse` query parameter switches the
response format.

The `ResponseType.stream` option tells Dio to return a `ResponseBody` with a raw
byte stream instead of waiting for the full response body. This is the key to
getting the streaming data without buffering the entire response.

### Cancellation handling

```dart
_cancelToken = CancelToken();
final response = await _dio.post<ResponseBody>(
  GeminiConstants.streamEndpoint,
  cancelToken: cancelToken,  // ← passed to Dio
  ...
);
```

When `ChatNotifier.stopStream()` calls `_cancelToken?.cancel('User stopped')`:
1. Dio aborts the HTTP connection at the network layer
2. The `byteStream` in `_parseSSE` receives an error event
3. `onError` in `StreamSubscription.listen` catches `DioException`
4. `CancelToken.isCancel(e)` returns true
5. `_finalizeStream(assistantMsgId, accumulated, stopped: true)` preserves partial content

The double-check inside `_parseSSE`:
```dart
if (cancelToken.isCancelled) return;
```
handles the case where the token was cancelled between network packets (Dart
stream not yet errored but we know cancellation happened).

### Error handling

| Error type | Detection | Handling |
|-----------|-----------|---------|
| Network error mid-stream | `DioException` in `onError` (not `isCancel`) | `_markStreamError()` — sets `MessageStatus.error` on assistant message |
| API key missing | `if (_apiKey.isEmpty)` check at start | Throws `Exception('GEMINI_API_KEY not configured')` |
| JSON parse failure in SSE | `try/catch` in `_extractToken` | `_talker.warning(...)` and returns null — token skipped |
| Conversation not found | `conversation == null` in `_loadConversation` | `ChatStatus.error` state |

### Backpressure/performance

There is no explicit backpressure mechanism. Dart async generators (`async*`) and
`StreamSubscription` handle the byte stream naturally. The Gemini API typically
sends 20-50 tokens/second. The SSE parser has negligible CPU cost (string operations
on <1KB chunks). The real backpressure is in the render layer: even if 1000 tokens
arrive per second, the Ticker only processes them at 60fps (adaptive speed 72–216
chars/sec), so `_source` fills up and the buffer grows until the Ticker catches up.

### Why not `google_generative_ai` SDK

Documented explicitly in `gemini_service.dart`:
> "The SDK wraps its own HTTP client, making it impossible to pass a Dio CancelToken.
> The spec explicitly requires that tapping Stop actually cancels the HTTP request at
> the network layer — not just ignores future tokens."

The SDK's streaming API returns a `Stream<GenerateContentResponse>` but the underlying
HTTP cancellation is not exposed. Using it would make stop/cancel a UI-only illusion —
the request would continue consuming quota even after the user taps stop.

---

## 9. Performance Optimisations

### Rendering optimisation

- `RepaintBoundary` on every `_CachedBlockWidget`: completed blocks get their own
  raster layer. The GPU composites them without re-rasterising when the active block changes.
- `_CachedBlockWidget` wraps its built widget in `RepaintBoundary` in `initState`:
  ```dart
  _built = RepaintBoundary(child: _renderBlock(widget.block));
  ```
- `ListView.builder` with `padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h)`:
  only visible items are built. `ValueKey` on each `_MessageItem` allows Flutter to
  reuse render objects when the list rebuilds.

### Widget rebuild optimisation

- `.select()` on `chatProvider` in `ChatScreen.build()` returns a Dart 3 record
  excluding `streamingContent` — 0 `ChatScreen` rebuilds during streaming
- `ref.listen` (not `ref.watch`) in `_StreamingBubbleState.build()` for `streamingContent`
  — 0 rebuilds from Riverpod in the streaming bubble
- Ticker fires `setState` at vsync — max 60 rebuilds/sec in `_StreamingBubbleState`
- `_StreamingBubbleEntry` owns entrance `AnimationController` — the 220ms entrance
  plays once; subsequent rebuilds of `_StreamingBubble` don't restart it
- `_onScrollChange` only calls `setState` when `_showJumpPill` value changes:
  ```dart
  if (show != _showJumpPill) setState(() => _showJumpPill = show);
  ```

### Memory optimisation

- `_cachedWidgets` is an append-only list — no block widget is ever garbage-collected
  while streaming, but after streaming ends, the `_StreamingBubble` is replaced by
  `StaticMarkdownView` and `_cachedWidgets` is freed with the state
- `ChatNotifier` disposes `StreamSubscription` and cancels `CancelToken` on
  `ref.onDispose` — no memory leak from abandoned streams
- Hive stores messages as flat JSON maps — no object graph inflation from TypeAdapters

### List optimisation

- `ListView.builder` with `itemCount: messages.length + 1` — O(1) item lookup
- `ValueKey(message.id)` on each message item — stable keys allow Flutter to reuse
  `RenderObject` instances when the list grows
- The streaming bubble renders as a single `_StreamingBubbleEntry` at the index of
  the assistant message (its `MessageStatus == streaming`) — not appended separately

### Animation optimisation

- `AnimatedSwitcher` with `transitionBuilder: ScaleTransition` avoids adding extra
  layout passes (scale is a transform, not a layout)
- `AnimatedContainer` for send button background: uses implicit animation (no
  `AnimationController` allocation) while still being hardware-accelerated
- `flutter_animate` applies transforms at the compositing layer — stagger animations
  do not cause layout recalculations

### Stream optimisation

- `cancelOnError: true` in `StreamSubscription.listen` ensures the subscription
  is automatically cancelled if the network errors — no manual cleanup needed in that path
- `_cleanup()` called in both `stopStream()` and `ref.onDispose` — belt and suspenders
  to ensure no lingering subscriptions

### Flutter rendering pipeline considerations

Flutter's rendering pipeline: Build → Layout → Paint → Composite

- `RepaintBoundary` creates a new layer in the Composite phase. The layer is cached
  by the GPU until the `RepaintBoundary`'s subtree calls `markNeedsPaint()`.
  `_CachedBlockWidget` never calls `setState` after `initState`, so its
  `RepaintBoundary` never invalidates — the GPU layer is permanent.
- `AnimatedSwitcher` with `FadeTransition` (opacity) uses the compositing layer
  (hardware opacity) rather than pixel blending — smooth on all devices.
- `Ticker` runs on the engine's vsync signal — guaranteed to fire no more than 60×/sec
  on 60Hz displays, 120× on ProMotion. The adaptive speed formula means the character
  reveal automatically adjusts for higher refresh rate displays.

### Jank reduction strategies

1. Keep `build()` methods side-effect-free — no I/O, no parsing, no expensive computation
2. `MarkdownParser.parse()` is O(n) in content length but only runs in `StreamingMarkdownView`'s
   `didUpdateWidget` — not in `build()` of every widget in the tree
3. `Future.microtask` for `_loadConversation` defers I/O to after the first build frame
4. Optimistic state update in `sendMessage` — user sees their message and the thinking
   indicator in the same frame as the tap, not after the network round trip

---

## 10. Technical Trade-offs & Engineering Decisions

### Every major technical decision

| Decision | Why | Pros | Cons | Alternative considered |
|----------|-----|------|------|----------------------|
| `streamingContent` outside `messages` list | Prevents `messages` list rebuild per token | Only `_StreamingBubble` rebuilds | More complex state structure | Put token in `messages.last.content` — rejected because replaces entire list ref |
| Ticker for character reveal | Decouples network speed from render rate | Natural cadence, max 60fps, adaptive speed | Extra complexity vs direct setState in listener | `StreamSubscription.listen` calling setState directly — rejected (unbounded rebuilds) |
| `MarkdownParser.parse()` called on every tick | Always derives fresh parser state from `_displayed` | Simple, correct | O(n) parse per frame | Incremental parser tracking state between tokens — more complex, fragile on token boundaries |
| `_CachedBlockWidget` builds once in `initState` | Completed markdown never re-renders | ~O(1) render per completed block | Block cannot be updated if correction arrives | `AutomaticKeepAliveClientMixin` — rejected because doesn't prevent rebuild, only disposal |
| Append-only `_cachedWidgets` with length-as-start | Prevents duplicate key crash | Correct even when parser fluctuates | Cannot remove blocks once added | Index from 0 each time — causes duplicate keys when parser block count dips |
| Raw Dio SSE over `google_generative_ai` SDK | Need real CancelToken for network cancellation | True HTTP cancel, custom headers, full control | More implementation complexity, manual SSE parsing | SDK — rejected because no CancelToken exposure |
| Hive with JSON maps (no TypeAdapters) | No code-gen friction | Simple, schema-flexible | No compile-time type safety at persistence boundary | Isar — better query performance, stricter typing; rejected to avoid setup time |
| `FamilyNotifier` keyed by conversationId | Perfect isolation per conversation | No cross-contamination, GC when no longer watched | One notifier instance per conversation in memory | Single global `ChatNotifier` with conversation switching — rejected (state contamination risk) |
| Platform-null fontFamily for iOS | SF Pro requires null fontFamily (no explicit name) | Correct iOS typography | Requires Platform.isIOS branch | Using SF Pro font asset — impossible without Apple entitlement; `fontFamily: 'SFPro'` doesn't work |
| `addPostFrameCallback` for scroll | `maxScrollExtent` only updated after layout | Scroll fires with correct value | One-frame delay | Direct `jumpTo` in tick — fires before layout, reads stale maxScrollExtent |
| Manual `copyWith` on all state classes | No code-gen dependency | Clean, explicit, always works | ~10 extra lines per class | `@freezed` — removes those lines but adds build_runner, forbidden by spec |
| `ThemeNotifier.setTheme()` persists to Hive synchronously | Theme persistence must survive restart | Instant local storage | Hive `put` is async but called without await (acceptable for simple value) | SharedPreferences — same tradeoff, Hive already in project |

### What would be improved in production

1. **Hive → Isar**: Isar supports indexed queries (conversations by date, search by
   title text) which Hive cannot do without loading everything. At scale (10k conversations),
   Hive loads the entire `conversations` box into memory.

2. **MarkdownParser incremental state**: Current parser re-parses the full string on
   every tick. An incremental parser that only processes new characters since last tick
   would be O(delta) instead of O(n), critical for very long responses.

3. **True block immutability check**: `_CachedBlockWidget` uses `initState` to
   build once. In production, you'd add a `didUpdateWidget` that checks if `block.content`
   changed and rebuilds only then — supporting message edit flows.

4. **Retry logic**: Currently `retryLast()` exists in `ChatNotifier` but there is no
   UI to trigger it. An inline "Retry" button on error messages would be production-complete.

5. **App lifecycle handling**: The spec requires detecting OS-killed streams on iOS
   backgrounding. This is not implemented. `WidgetsBindingObserver` + `AppLifecycleState`
   handling would be the production approach.

6. **Selection during streaming**: `SelectableText` in `_ActiveBlockWidget` loses
   selection position when rebuilt. Production would require a custom `TextEditingController`
   approach or a platform channel for persistent selection.

7. **API key in build args**: `--dart-define-from-file=.env` works for development
   but production apps should proxy through a backend — never embed API keys in any client binary.

---

## 11. Possible Interview Questions

### Beginner questions

**Q: What state management solution is used and why?**

A: `flutter_riverpod` with `Notifier<S>` and `FamilyNotifier<S,A>`. Riverpod was
required by the spec. Beyond compliance, Riverpod's `.select()` operator enables
subscribing to sub-fields of state, which is critical here: during streaming, only
the `_StreamingBubble` should rebuild — not the entire `ChatScreen`. Without
`.select()`, every token would rebuild the whole screen.

Follow-up: *Why not `StateNotifier`?* — Deprecated by Riverpod team. Using it would
signal lack of knowledge of the current API.

---

**Q: How are conversations persisted?**

A: Hive with two boxes: `conversations` (metadata: id, title, timestamps, pinned flag)
and `chat_messages` (messages keyed by conversationId as JSON maps). No TypeAdapters —
messages are stored as `List<Map<String, dynamic>>`. `HiveService.init()` opens both
boxes before `runApp` in `main()`.

Follow-up: *Why not Isar?* — Hive was already in the boilerplate. Both satisfy the
persistence requirement. Isar would offer better query performance for large datasets.

---

**Q: How is the Gemini API key protected?**

A: Never hardcoded. Read via `String.fromEnvironment('GEMINI_API_KEY')` which is set
at build time via `--dart-define-from-file=.env`. The `.env` file is gitignored.
Without this flag, `_apiKey.isEmpty` is true and the service throws an error.

Follow-up: *Is this truly secure?* — No. The key is embedded in the compiled binary
and can be extracted. Production would proxy all API calls through a backend server.

---

### Mid-level questions

**Q: Explain the difference between `ref.watch` and `ref.listen` in this project.**

A: `ref.watch` rebuilds the widget when the watched value changes. `ref.listen`
fires a callback but does not cause a rebuild. In `_StreamingBubbleState.build()`,
`ref.listen` is used for `streamingContent` — on every token, `_source = next` is
assigned without rebuilding. The rebuild is triggered solely by the Ticker's `setState`.
This is the key that limits rebuilds to vsync rate (≤60fps) instead of network rate
(potentially hundreds per second for a fast model).

Follow-up: *What if you used `ref.watch` instead of `ref.listen` for `streamingContent` in the bubble?*
— The bubble would rebuild on every token (network speed, potentially 50-200ms intervals),
AND the Ticker would also call `setState` at 60fps. You'd get two competing rebuild sources.
The Ticker's adaptive logic would still work but the entrance `AnimatedSwitcher` would reset.

---

**Q: Why is `streamingContent` stored outside the `messages` list in `ChatState`?**

A: Every token update replaces `streamingContent` with a new string. If it were
stored inside `messages.last.content`, then `messages` itself would be replaced by a
new list on every token. Any `ref.watch(...).select((s) => s.messages)` would trigger
a rebuild on every token — including `_MessageItem` widgets for older messages.

By keeping it separate, `ChatScreen` can watch `messages` without being disturbed by
streaming, and only `_StreamingBubble` (which uses `ref.listen` for `streamingContent`)
is affected by tokens.

Follow-up: *The `_absent` sentinel in `ChatState.copyWith` — what does it do?*

A: Dart's `copyWith` pattern has a problem with nullable fields: you cannot distinguish
"caller passed null" from "caller didn't pass this field". The `_absent` sentinel
is a private const `Object()`. When `streamingContent` is not passed to `copyWith`,
`identical(streamingContent, _absent)` is true and the existing value is kept.
When `null` is explicitly passed, it clears the content.

---

**Q: Walk through the auto-scroll mechanism and why `addPostFrameCallback` is necessary.**

A: The Ticker's `setState` grows `_displayed` → Flutter rebuilds `_StreamingBubble`
→ `StreamingMarkdownView` renders more text → the `ListView` has a larger
`maxScrollExtent`. But `maxScrollExtent` is only updated after the layout phase of
the frame. If you call `scrollController.animateTo(maxScrollExtent)` inside `setState`
(during build), you read the *previous* frame's `maxScrollExtent` — the scroll goes
to the old bottom, and you see the chat appear to lag behind the growing content.

`addPostFrameCallback` fires after layout + paint, so `maxScrollExtent` reflects the
newly-grown bubble. The scroll command then goes to the correct position.

Additionally, `_pendingScrollJump` ensures only one `animateTo` is queued per frame —
without it, at 60fps you'd queue 60 `animateTo` calls per second, each interrupting
the previous one, causing visible stutter.

---

**Q: How does the duplicate-key crash happen and how was it fixed?**

A: `MarkdownParser.parse()` processes the full `_displayed` string on every call.
Consider this scenario: the active block is block #8. Parser returns
`completedBlocks: [0..7]` and `activeBlock: 8`. Next tick adds 2 chars — parser
returns `completedBlocks: [0..8]` (the previous active block is now complete).

The old code used `_lastCompletedCount` (= 8) as the loop start. But if the next
parse returns 7 `completedBlocks` (parser re-classifies due to edge case),
`_lastCompletedCount` stays at 8, loop doesn't run. Then it returns 9 — loop runs
from 8, tries to add blocks 8 and 9 with keys `ValueKey(8)` and `ValueKey(9)`.
But `ValueKey(8)` already exists from before — Flutter throws "Duplicate keys found".

Fix: use `_cachedWidgets.length` as the loop start. `_cachedWidgets` is append-only —
its length reflects the actual count of widgets added. Even if the parser fluctuates,
the loop only adds truly new blocks.

---

### Senior-level architecture questions

**Q: The `MarkdownParser.parse()` is called on every Ticker tick with the full string. This is O(n) per frame. How would you optimise this for a 50,000-character response?**

A: Three approaches, in increasing complexity:

1. **Incremental parsing**: Track the last parsed position. On each tick, only parse
   the new characters since `_prevDisplayed.length`. This requires the parser to be
   stateful (holding its current `inCodeBlock`, `active`, etc.) between calls.
   Implemented as `MarkdownParser.advance(previousState, newChars)`.

2. **Parse on block boundaries only**: The parser only needs to update when a block
   completes or a new one starts. Track the last character of `_displayed` that caused
   a state change. Only re-run the state machine from that point when `_displayed`
   crosses a block boundary (blank line, ` ``` `, type switch).

3. **Worker isolate**: Offload `MarkdownParser.parse()` to a separate Dart isolate.
   Results are sent back via `Isolate.run()` or a `ReceivePort`. The UI thread only
   applies the diff. At 60fps with 50k chars, this adds one `Isolate.run` call per
   frame — the cost of isolate message passing (~0.1ms) may exceed the parse cost.

In practice, the current O(n) approach handles typical API responses (2,000–8,000 chars)
at 60fps on mid-range hardware. Incremental parsing would be the first production optimisation.

---

**Q: Why is `FamilyNotifier` used for `chatProvider` instead of a single notifier with a `currentConversationId` field?**

A: With a single notifier:
- Opening conversation A, switching to B, then back to A: you must reload A's messages,
  losing any in-memory state
- If two chats are loaded simultaneously (e.g., pre-fetching adjacent conversations),
  there's no clean way to hold both
- State contamination: if an error occurs in B's stream, it might overwrite A's state

With `FamilyNotifier`, each `(notifier, conversationId)` pair is an independent instance
with its own `_cancelToken`, `_streamSub`, `messages`, `streamingContent`. The instances
are lazily created and automatically disposed when no widget watches them. This is the
correct model for "one stateful object per entity" patterns.

Follow-up: *When is the old notifier disposed?* — When all widgets watching
`chatProvider(oldId)` are removed from the tree (e.g., navigating away from chat screen),
Riverpod calls `ref.onDispose` → `_cleanup()` which cancels the subscription and token.

---

**Q: Walk through what happens when the user taps "Stop" mid-stream.**

A:
1. `_ChatScreenState._stopStream()` calls `ref.read(chatProvider(id).notifier).stopStream()`
2. `ChatNotifier.stopStream()` calls `_cancelToken?.cancel('User stopped')`
3. Dio's HTTP layer aborts the TCP connection — the byte stream in `_parseSSE` terminates
4. The `byteStream` emits an error: `DioException` with `type = cancel`
5. `StreamSubscription.onError` fires in `ChatNotifier.sendMessage`'s stream listen
6. `CancelToken.isCancel(e)` returns true → `_finalizeStream(msgId, accumulated, stopped: true)`
7. `_finalizeStream` updates `messages`: assistant message gets `MessageStatus.stopped`, content = accumulated
8. `state = state.copyWith(status: ChatStatus.ready, streamingContent: null)`
9. `_StreamingBubble`'s status listener fires: `status != streaming` → `setState(() => _displayed = _source)`
   (flush remaining buffer)
10. `_StreamingBubble` is removed from the tree (its message's status is no longer `streaming`)
11. `StaticMarkdownView` renders the final (stopped) message
12. `_AssistantMessage.isStopped` is true → "Stopped" badge renders

The whole flow takes <100ms on device because step 2 is synchronous and steps 6-12
happen in the same microtask/frame cycle.

---

**Q: `ThemeNotifier` uses `Hive.box(...).get(_key)` directly — why not go through the repository layer?**

A: Two reasons:

1. **Simplicity**: The theme is a single scalar value (`ThemeMode`) stored in a
   `settings` box. A full repository layer with `Either<Failure, ThemeMode>` adds
   complexity that provides no benefit — theme read failure defaults to system mode.

2. **Timing**: `ThemeNotifier.build()` is synchronous (returns `ThemeMode` directly,
   not a `Future`). Hive's synchronous `box.get()` is the only option for a sync
   `Notifier.build()`. A repository that returns `Either<Failure, ThemeMode>` would
   require `AsyncNotifier` — but then `MaterialApp.themeMode` would briefly be
   `ThemeMode.system` (default) before the async build completes, causing a theme flash.

Follow-up: *Why is `Hive.box()` called directly instead of injecting via Riverpod?*
— Because `ThemeNotifier.build()` is a synchronous `Notifier.build`. By the time
`build()` runs, `HiveService.init()` has already completed in `main()` (via `await`
before `runApp`), so the box is definitely open. The global `Hive.box()` accessor is
safe here. Injecting a `HiveService` provider would require an additional provider
dependency and would not change the timing.

---

### Deep Flutter rendering questions

**Q: Explain exactly what `RepaintBoundary` does for `_CachedBlockWidget` and why it matters.**

A: Flutter's rendering pipeline has four phases:
1. **Build**: Widget tree → Element tree → `RenderObject` tree
2. **Layout**: Measure and position every `RenderObject`
3. **Paint**: Execute `paint()` on every `RenderObject` into a `Canvas` → `Picture`
4. **Composite**: Send layers to the GPU

`RepaintBoundary` creates a new `Layer` in the compositing tree. When a widget marks
itself dirty (`markNeedsPaint`), Flutter only re-runs Paint for the layer containing
that widget — not for sibling layers. The GPU caches `Layer.picture` and re-composites
without repainting.

For `_CachedBlockWidget`:
- Without `RepaintBoundary`: When `_ActiveBlockWidget` (below it in the tree) calls
  `setState`, Flutter marks the entire `Column` as needing repaint, repainting every
  `_CachedBlockWidget`'s text on every tick. With 10 blocks, that's 10× the paint cost.
- With `RepaintBoundary`: Each block has its own layer. Only `_ActiveBlockWidget`'s
  layer repaints. GPU composites all layers together — the 9 completed blocks are
  composited from cache, zero repaint cost.

This is the GPU-level equivalent of `_CachedBlockWidget.initState`'s build-once pattern.

---

**Q: `flutter_animate` is used for suggestion chips and message entrance animations. Why not for the streaming bubble's character reveal?**

A: `flutter_animate` works by wrapping widgets with `_AnimateWidget` which drives
`AnimationController`s in `initState`. On each animation tick, `_AnimateWidget`
rebuilds its subtree. This is fine for one-shot animations (entrance) but not for
an ongoing data-driven reveal where we need:

1. Variable speed (adaptive 72–216 chars/sec)
2. Coordination with external data (`_source` string from Riverpod)
3. The ability to "jump" the entire buffer when streaming ends

`flutter_animate` has no mechanism for these requirements. The Ticker approach gives
full control: arbitrary speed per tick, direct string manipulation, flush-on-done
capability. `flutter_animate` is the right tool for declarative "animate in on mount"
scenarios, not for data-driven incremental reveal.

---

### Performance-related questions

**Q: How would you profile this app to find jank during streaming?**

A:
1. **Flutter DevTools Performance overlay**: Run in profile mode (`flutter run --profile`).
   The overlay shows frame budget per build/raster frame. Look for frames >16ms
   in the raster thread during streaming — this would indicate GPU overdraw from
   excessive repainting.

2. **Timeline view in DevTools**: `dart:developer`'s `Timeline.startSync` / `endSync`
   around `MarkdownParser.parse()` to measure parse cost per tick.

3. **Widget rebuilds counter**: DevTools' "Rebuild stats" shows how many times each
   widget rebuilds. Expected: `_StreamingBubbleState` ~60/sec, `ChatScreen` ~0 during streaming.

4. **Raster thread spikes**: If `RepaintBoundary` is working, raster time should be
   nearly flat. A spike indicates a completed block is being repainted — check if
   something is calling `setState` on its ancestor.

5. **Memory profiler**: After a long conversation, check for retained `ChatNotifier`
   instances (should be only 1 per currently-visible conversation).

---

**Q: The `_pendingScrollJump` flag prevents duplicate scroll commands. But `addPostFrameCallback` already executes after the frame — can there really be duplicate calls?**

A: Yes. Consider this scenario:
- Ticker fires at frame N: `setState` → rebuilds → `addPostFrameCallback(scroll_1)` queued
- Layout completes for frame N
- `scroll_1` fires: `animateTo(maxScrollExtent_N)` — 120ms animation starts
- Ticker fires at frame N+1 (16ms later): `setState` → rebuilds → `addPostFrameCallback(scroll_2)` queued
- `scroll_2` fires: `animateTo(maxScrollExtent_{N+1})` — interrupts `scroll_1`

`animateTo` interrupts any in-progress animation when called again. At 60fps, that's
60 `animateTo` calls per second interrupting each other. The `_pendingScrollJump` flag
ensures only one is queued at a time:
- Frame N queues scroll_1, sets `_pendingScrollJump = true`
- Frame N+1: `_pendingScrollJump` is true → `_jumpToBottom` returns immediately
- scroll_1 fires (N+1's post-frame), sets `_pendingScrollJump = false`
- Frame N+2 queues scroll_2 (120ms animation is nearly done by now)

This effectively batches scroll commands to at most one per 120ms window — smooth
and non-stutter.

---

### Streaming-related questions

**Q: What happens if the API returns a malformed SSE chunk?**

A: In `_extractToken`:
```dart
try {
  final json = jsonDecode(jsonStr) as Map<String, dynamic>;
  ...
  return (parts.first as Map<String, dynamic>)['text'] as String?;
} catch (e) {
  _talker.warning('SSE parse warning: $e | raw: $jsonStr');
  return null;
}
```
The malformed chunk is logged as a warning and `null` is returned. In the caller:
```dart
if (token != null && token.isNotEmpty) yield token;
```
Null tokens are silently skipped. The stream continues — one garbled chunk does not
abort the entire response. This is robust for real-world API behaviour where
occasional malformed events occur.

Follow-up: *What about incomplete JSON at the end of a network packet?*
The `buffer.write(lines.removeLast())` in `_parseSSE` handles this. An incomplete
JSON line stays in `buffer` until the next chunk completes it.

---

**Q: How would you implement "regenerate last response"?**

A: `ChatNotifier.retryLast()` already exists:
```dart
Future<void> retryLast() async {
  final lastUserIdx = msgs.lastIndexWhere((m) => m.role == MessageRole.user);
  if (lastUserIdx == -1) return;
  await editAndResend(lastUserIdx, msgs[lastUserIdx].content);
}
```
`editAndResend`:
1. `stopStream()` — cancels any in-progress stream
2. `deleteMessagesFrom(conversationId, messageIndex)` — removes messages from index onward in Hive
3. `state = state.copyWith(messages: state.messages.sublist(0, messageIndex))` — removes from in-memory state
4. `sendMessage(newText)` — re-sends the user prompt

The UI needs a "Regenerate" button that calls `ref.read(chatProvider(id).notifier).retryLast()`.
This is a known gap: the notifier method is implemented, the UI trigger is not.

---

### State management questions

**Q: ConversationsNotifier has a `refreshConversation(id)` method that calls `loadConversations()` — this reloads ALL conversations just to refresh one. How would you improve this?**

A: The current implementation:
```dart
Future<void> refreshConversation(String id) async {
  await loadConversations();  // full reload
}
```

Production improvement:
```dart
Future<void> refreshConversation(String id) async {
  final result = await ref.read(conversationRepositoryProvider).getConversation(id);
  result.fold(
    (_) {},
    (updated) => state = state.copyWith(
      conversations: state.conversations.map(
        (c) => c.id == id ? updated : c
      ).toList(),
    ),
  );
}
```
This requires `ConversationRepository` to expose a `getConversation(id)` method
(currently only `getAllConversations` is available). The full reload is acceptable
at the current scale (< 100 conversations) but would be noticeable with thousands.

---

**Q: `ChatNotifier._buildHistory()` filters messages to `MessageStatus.complete` only. Why?**

A: The Gemini API's multi-turn conversation format (`contents` array) requires each
message to have a complete, finalized content string. Messages with status `stopped`,
`error`, or `streaming` are partial — their content may be truncated or empty.

Sending a stopped/error message to Gemini would confuse the model (the context
would contain a truncated assistant response followed by the new user prompt).
Only `complete` messages form a coherent conversation context.

This also means stopped responses are effectively "forgotten" by the AI context —
production would offer a "include stopped response in context" option.

---

### Real-world production questions

**Q: The app uses `Navigator.of(context).pop(mode)` in the mode picker sheet. This appears to violate the GoRouter rule. Is it actually wrong?**

A: This is a common point of confusion. GoRouter prohibits `Navigator.push` for route
navigation because it bypasses the router's URL state. However, `Navigator.of(context).pop()`
to dismiss a modal sheet is not a route navigation — it is closing the modal. This is
acceptable because modal sheets are not routes in GoRouter; they are pushed imperatively
via `showModalBottomSheet`. The return value (the selected `ChatMode`) is passed via
`Navigator.pop`'s `result` argument and received by `showModalBottomSheet`'s `Future<T>`.

The rule is: never use `Navigator.push` for screen navigation. Using `Navigator.pop`
to close a modal with a result is the correct Flutter pattern.

---

**Q: What would break if you removed the `.select()` from `ChatScreen`'s `ref.watch` call?**

A: Without `.select()`:
```dart
final s = ref.watch(chatProvider(widget.conversationId));
// s is the full ChatState — rebuilds on ANY state change
```
On every streaming token, `streamingContent` changes → `chatProvider` emits a new
`ChatState` → `ChatScreen.build()` runs → `_buildMessageList()` runs → `ListView.builder`
evaluates all visible items → each `_MessageItem` builds → each `_AssistantMessage`
creates `StaticMarkdownView` and parses its full content.

With 10 messages visible and 10 tokens/second: 100 `StaticMarkdownView` parses/sec.
Each parse is O(n) in message length. For a chat with 5 large messages, this would
cause severe jank.

With `.select()`, `ChatScreen` only rebuilds when `status`, `messages`, `conversation`,
or `error` changes — none of which change per-token.

---

## 12. Weak Points / Improvement Areas

### Current limitations

1. **No real authentication**: Login/email screens are mock. Navigation goes to
   conversations directly without actual OAuth or JWT.

2. **Attachment tray is UI-only**: `MockAttachmentItem` does not attach real files
   to the Gemini API call. The send method sends `'📎 [Attachment]'` as text.

3. **No retry UI**: `ChatNotifier.retryLast()` exists but no button triggers it in
   the chat screen.

4. **App lifecycle not handled**: Backgrounding mid-stream on iOS may kill the stream
   (OS resource management). `WidgetsBindingObserver` is not implemented.

5. **No text selection preservation during streaming**: `SelectableText` in
   `_ActiveBlockWidget` loses selection when rebuilt on every Ticker tick.

6. **Conversations list context menu uses `Navigator.of(context).pop`**: The
   long-press context menu in `conversations_screen.dart` uses a `showModalBottomSheet`
   with `Navigator.of(context).pop()` in `onTap` — consistent with the drawer's
   pattern, but worth noting.

7. **`ConversationsScreen._buildSearchBar` uses raw `TextField`**: Despite the spec
   warning that evaluators grep for raw `TextField`, the search bar in the conversations
   screen uses `TextField` directly instead of `AppTextField`. The chat drawer correctly
   uses `AppTextField`.

8. **No infinite scroll in conversations**: The list loads all conversations at once.
   With thousands of conversations, this would be slow.

9. **No `Semantics` wrappers**: Accessibility labels are missing on interactive elements.

10. **Theme flash on cold start**: There is a brief 200ms where `ThemeMode.system`
    is applied before `ThemeNotifier.build()` reads Hive — potential flash if user
    prefers light and system is dark.

### Technical debt

- `lib/data/data_sources/local/product_local_data_source.dart` and
  `lib/data/repositories/product_repository_impl.dart` are boilerplate leftovers
  from the initial template. Not used by any feature.
- `lib/presentation/home/` (product feature) is unused — dead code from the boilerplate.
- `ConversationsNotifier.refreshConversation()` does a full reload instead of targeted update.
- `_SuggestionChipItem` has a typo: `'Automatße a workflow with code'` in `suggestion_chips.dart`
  line 15 — the `ß` character should be a plain `e`.

### Scalability concerns

- Hive loads the entire `conversations` box into memory. With 10,000 conversations,
  this would consume significant memory and slow down cold start.
- `MarkdownParser.parse()` is O(n) in string length. Responses >50,000 chars would
  cause frame drops.
- `ChatNotifier._buildHistory()` sends all `complete` messages to Gemini on every
  send. Long conversations exceed Gemini's context window — would need truncation.

### Production-grade improvements

1. **Backend proxy for API key** — never embed keys in the binary
2. **Incremental `MarkdownParser`** — O(delta) instead of O(n) per tick
3. **`WidgetsBindingObserver` for lifecycle** — handle backgrounding
4. **Isar for conversations** — indexed queries, better performance at scale
5. **Targeted `refreshConversation`** — single-conversation fetch
6. **`Semantics` wrappers** — accessibility for VoiceOver/TalkBack
7. **Context window management** — truncate `_buildHistory()` to last N messages
8. **Retry button in UI** — surface `retryLast()` and `retryFromError()`

---

## 13. Final Revision Notes

### Quick revision cheat sheet

| Concept | Key file | Key insight |
|---------|----------|-------------|
| Streaming state | `chat_state.dart` | `streamingContent` outside `messages` |
| Token rate decoupling | `chat_screen.dart:_StreamingBubbleState` | Ticker, not listener |
| Prevent full screen rebuild | `chat_screen.dart:ChatScreen.build` | `.select()` record |
| Markdown parse | `markdown_parser.dart` | Line-by-line state machine |
| Completed blocks | `streaming_markdown_view.dart:_CachedBlockWidget` | `initState` build once, no `didUpdateWidget` |
| Duplicate key fix | `streaming_markdown_view.dart:_cachedWidgets.length` | Append-only, length as start |
| Auto-scroll timing | `chat_screen.dart:_jumpToBottom` | `addPostFrameCallback` after layout |
| Stream cancel | `chat_notifier.dart:stopStream` | `CancelToken.cancel()` — real HTTP abort |
| iOS font | `app_fonts.dart:AppFonts.textTheme` | `null` fontFamily = SF Pro |
| Theme persist | `theme_notifier.dart:setTheme` | Hive `settings` box, sync `Notifier.build` |
| API key security | `gemini_service.dart:_apiKey` | `String.fromEnvironment` via `--dart-define-from-file` |
| SSE partial lines | `gemini_service.dart:_parseSSE` | `buffer.write(lines.removeLast())` |

### Important concepts

**ref.watch vs ref.listen vs ref.read:**
- `ref.watch`: rebuild widget when value changes (use in `build()`)
- `ref.listen`: callback without rebuild (use for side effects in `build()`, navigation)
- `ref.read`: one-time read without subscription (use in callbacks/methods)

**Ticker vs AnimationController:**
- `Ticker` fires at vsync with elapsed time since start
- `AnimationController` is a `Ticker` + `Animation<double>` (0.0 → 1.0 over a duration)
- For data-driven animation (character reveal), use `Ticker` directly
- For time-based animation (fade, scale), use `AnimationController`

**addPostFrameCallback timing:**
```
Frame N:
  ↓ build phase (widget.setState fires)
  ↓ layout phase (maxScrollExtent updated)
  ↓ paint phase
  ↓ composite
  ↓ addPostFrameCallback fires ← HERE: maxScrollExtent is final
```

**RepaintBoundary effect:**
- Creates a new compositing layer
- Only repaints when the subtree marks itself dirty
- GPU caches the layer bitmap between frames
- Critical for completed markdown blocks — O(1) GPU cost per block per frame

### Key architectural talking points for senior interviews

1. **"Why is the active streaming content stored outside the message list?"**
   → Because `messages` is watched by `ChatScreen` via `.select()`. If `streamingContent`
   were inside `messages`, every token would replace the list reference, causing
   `ChatScreen` to rebuild on every token despite the `.select()`.

2. **"Describe the complete data flow from user tapping send to text appearing on screen."**
   → Tap → `sendMessage()` → optimistic state update → stream starts → tokens update
   `streamingContent` → `ref.listen` in bubble updates `_source` silently → Ticker
   grows `_displayed` at 72chars/sec → `MarkdownParser` produces blocks → completed
   blocks render once, active block re-renders per tick.

3. **"What would happen to performance if you had 200 messages in a conversation?"**
   → Fine. `ListView.builder` only builds visible items. Completed messages are
   `StaticMarkdownView` with `_CachedBlockWidget`s that never rebuild. Only the
   actively-streaming bubble rebuilds 60×/sec. Scroll performance is O(visible_items).

4. **"How does theme switching work without any custom cross-fade code?"**
   → `MaterialApp` internally wraps theme changes in `AnimatedTheme` with
   `kThemeAnimationDuration` (200ms). Changing `themeMode` in the `ThemeNotifier`
   triggers `MaterialApp` to rebuild, which animates the transition automatically.
   All widgets that read `Theme.of(context).colorScheme` automatically participate.

5. **"The spec says stop must return to idle in <100ms. How is that achieved?"**
   → `CancelToken.cancel()` is synchronous (no await). The stream listener's `onError`
   fires synchronously when Dio detects the cancellation. `_finalizeStream` updates
   state synchronously (no await before the state assignment). The entire path from
   tap → state update is one synchronous call chain — well under 100ms.

---

*End of study.md — 5,000+ lines of codebase distilled into interview-ready answers.*


///


Great question. It doesn't detect "broken JSON". It uses a much simpler trick.

The rule it follows
Every complete SSE event ends with a newline \n

That's the SSE standard. Gemini always sends:


data: {"text":"Roses"}\n
data: {"text":" are"}\n
So the rule is simple:

Has a \n at the end → complete, safe to parse
No \n at the end → incomplete, wait for more
The actual trick in the code

final lines = raw.split('\n');
buffer.write(lines.removeLast()); // save last line back
Split everything on \n. Whatever the last piece is — it either has a \n after it or it doesn't. After splitting, the last element never has a newline (because split removes them).

So the code just assumes: last element = might be incomplete, save it.

Example — normal case (nothing broken)
Packet arrives:


data: {"text":"Roses"}\ndata: {"text":" are"}\n
After split('\n'):


lines = [
  "data: {\"text\":\"Roses\"}",   ← index 0
  "data: {\"text\":\" are\"}",    ← index 1
  ""                              ← index 2 (empty, after the last \n)
]
removeLast() saves "" (empty) back to buffer. Both real lines get processed. No problem.

Example — broken case
Packet 1 arrives:


data: {"text":"Roses"}\ndata: {"text":" ar
After split('\n'):


lines = [
  "data: {\"text\":\"Roses\"}",   ← index 0, complete ✓
  "data: {\"text\":\" ar"         ← index 1, INCOMPLETE (no \n after it)
]
removeLast() saves data: {"text":" ar back to buffer.

Only the complete line gets parsed → yields "Roses".

Packet 2 arrives:


e"}}\n
Buffer already has data: {"text":" ar, so combined:


data: {"text":" ar  +  e"}}\n
=
data: {"text":" are"}}\n
After split('\n'):


lines = [
  "data: {\"text\":\" are\"}}",   ← complete now ✓
  ""
]
Now it parses successfully → yields " are".

One line summary
It doesn't detect broken JSON. It just saves the last line every time (because it might be cut off), and prepends it to the next packet. If it was complete, the prepend is just an empty string — no harm done.

chat_screen.dart
now tell me why we have created entites instead of using model directly ?
Great architecture question. Let me explain with your exact code.

First, look at what you have
Entity — lib/domain/entities/chat_message.dart


class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;
}
Model — lib/data/model/chat_message_model.dart


class ChatMessageModel extends ChatMessage {  // ← extends the entity
  
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() => { ... }
}
The model is the entity plus JSON reading/writing.

Why not just use the Model everywhere?
Imagine you skip entities and only have ChatMessageModel everywhere — in your notifier, in your screen, in your repository interface.

Now your backend changes. Gemini switches their API. The JSON field "content" becomes "message_text". Or you switch from Gemini to OpenAI which has a completely different JSON structure.

You now have to change ChatMessageModel — and hunt down every single file that uses it across your entire app because your UI, business logic, and data fetching all depend on the same class.

What the split actually gives you

ChatMessage (entity)          ChatMessageModel (model)
─────────────────────         ──────────────────────────
Pure Dart. No JSON.           Knows about JSON.
No Hive. No Dio.              Knows about Hive format.
Used by: everything           Used by: data layer only
  - ChatNotifier                - ChatMessageLocalDataSource
  - ChatScreen                  - ChatMessageRepositoryImpl
  - ChatDrawer
  - ConversationsScreen
The entity is a stable contract. The model is a detail that can change.

Concrete example in your app
Your ChatNotifier works with ChatMessage (entity):


// chat_notifier.dart
final messages = msgsResult.fold((_) => <ChatMessage>[], (m) => m);
state = state.copyWith(messages: messages);
Your ChatScreen displays ChatMessage (entity):


// chat_screen.dart
final msg = messages[i];   // ChatMessage
msg.role == MessageRole.user
msg.content
msg.isStopped
Neither of these files know or care that JSON even exists.

Now if Hive storage format changes — maybe you switch from JSON maps to a different structure — you only change ChatMessageModel.fromJson() and toJson().

ChatNotifier, ChatScreen, ChatDrawer — zero changes needed. They never touched JSON.

Simple analogy
Think of a passport vs a visa sticker.

Passport = Entity — your identity. Works everywhere. Doesn't care which country you're in.
Visa sticker = Model — country-specific detail stuck onto the passport for a specific border crossing.
You don't redesign your entire identity every time you visit a new country. You just get a new sticker.

One line summary
Entity = what the data is (your app's language). Model = how to store and retrieve it (the outside world's language). Keeping them separate means changing storage never breaks your UI, and changing your UI never breaks storage.

now the main bit how we are rendering the chat buble and doing auto scoll down when bubble goews the ui teach me all the details which is implemnt in the ui code don't leave single thing
Let me re-read the exact current code before explaining anything.

Read chat_screen.dart (lines 32-131)
Read chat_screen.dart (lines 161-330)
Read chat_screen.dart (lines 608-827)
Good. Now I have the exact current code. Let me explain every single piece.

The complete picture — what happens when you send "write about roses"
I'll go layer by layer.

Layer 1 — The message list (_buildMessageList)

return ListView.builder(
  controller: _scrollController,
  itemCount: messages.length + 1,   // +1 for the extras at bottom
  itemBuilder: (_, i) {
    if (i < messages.length) {
      final msg = messages[i];

      if (msg.status == MessageStatus.streaming) {
        return _StreamingBubbleEntry(...);  // ← special widget while AI is typing
      }
      return _MessageItem(...);            // ← normal finished message
    }
    // last slot: rating card after AI finishes
  },
);
When you send a message, ChatNotifier immediately adds two messages to state:

User message → MessageStatus.complete
Assistant message → MessageStatus.streaming
The list sees the assistant message has status == streaming, so it renders _StreamingBubbleEntry instead of a normal bubble.

Once streaming ends, that same message gets status == complete → list rebuilds → now renders _MessageItem → shows StaticMarkdownView.

Layer 2 — The entrance animation (_StreamingBubbleEntry)

class _StreamingBubbleEntry extends StatefulWidget { ... }

class _StreamingBubbleEntryState extends State<_StreamingBubbleEntry>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    _ctrl = AnimationController(duration: 220ms);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: Offset(0, 0.06), end: Offset.zero).animate(...);
    _ctrl.forward();   // ← play once, immediately
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,         // fades in 0→1
      child: SlideTransition(
        position: _slide,        // slides up slightly
        child: RepaintBoundary(
          child: _StreamingBubble(...),   // the actual content
        ),
      ),
    );
  }
}
Why this wrapper exists: The bubble rebuilds on every token (every word). If you put the fade-in animation directly on _StreamingBubble, it would restart the animation on every rebuild — the bubble would flicker constantly.

By putting the animation in a separate StatefulWidget above it, the animation plays once in initState and never restarts. The content inside can rebuild freely without touching the animation.

RepaintBoundary — tells Flutter: give this widget its own GPU layer. So when the bubble grows, only the bubble's layer is redrawn — not the entire screen.

Layer 3 — The live bubble (_StreamingBubble)

class _StreamingBubble extends ConsumerWidget {

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // watches ONLY streamingContent — rebuilds on every new word
    final content = ref.watch(
      chatProvider(conversationId).select((s) => s.streamingContent ?? ''),
    );

    return Padding(
      child: Column(
        children: [
          _ManusHeader(),    // "🤌 manus  Lite" — never changes
          SizedBox(height: 8.h),
          AnimatedSwitcher(
            duration: 300ms,
            child: content.isEmpty
                ? _ThinkingIndicator(key: ValueKey('thinking'))  // pulsing dot
                : _StreamingContent(key: ValueKey('content'), content: content),
          ),
        ],
      ),
    );
  }
}
ref.watch(...select...) is the key line. It subscribes only to streamingContent. Every time a new word arrives and streamingContent grows, only this widget rebuilds. The rest of ChatScreen doesn't rebuild at all.

AnimatedSwitcher handles the transition:

When content is empty → shows _ThinkingIndicator (pulsing blue dot + "Thinking" text)
When first word arrives → smoothly fades out thinking indicator, fades in the text
The key: ValueKey('thinking') and key: ValueKey('content') tell AnimatedSwitcher these are different widgets so it knows to animate between them
Layer 4 — The thinking indicator

class _ThinkingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: blue, shape: circle))
        .animate(onPlay: (c) => c.repeat(reverse: true))   // ← loops forever
        .scaleXY(begin: 0.55, end: 1.0, duration: 850ms)  // grows and shrinks
        .fadeIn(begin: 0.4, duration: 850ms),              // pulses opacity

      Text('Thinking'),
    ]);
  }
}
onPlay: (c) => c.repeat(reverse: true) — when animation finishes, play it backwards, then forwards, then backwards... forever. That's the pulsing effect.

Layer 5 — The actual content and blinking cursor

class _StreamingContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      StreamingMarkdownView(streamingContent: content),  // renders the text
      SizedBox(height: 2.h),
      _BlinkingCursor(),   // the | character
    ]);
  }
}

class _BlinkingCursor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('|')
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .fadeOut(duration: 500ms);   // fades out then in forever
  }
}
StreamingMarkdownView handles the block-segmented markdown rendering (we covered this before — completed blocks never rebuild, only the active last block rebuilds).

The cursor is just the | character that fades in and out on a loop using the same repeat(reverse: true) trick.

Layer 6 — Auto scroll
This has two separate parts.

Part A — Watching for new tokens (in ChatScreen.build)

ref.listen(
  chatProvider(widget.conversationId).select((st) => st.streamingContent),
  (_, _) {
    if (_isNearBottom) _jumpToBottom();
  },
);
ref.listen fires a callback every time streamingContent changes (every new word) but does not rebuild ChatScreen. Inside the callback: if you're near the bottom, scroll down.

Part B — The _isNearBottom check

bool get _isNearBottom {
  if (!_scrollController.hasClients) return true;
  final pos = _scrollController.position;
  return pos.maxScrollExtent - pos.pixels < 40;
}
maxScrollExtent = total scrollable height (bottom of all content)
pixels = where you currently are
Difference < 40px = you're basically at the bottom
If the user scrolled up to read old messages, _isNearBottom is false → auto-scroll stops. As soon as they scroll back within 40px of the bottom → auto-scroll resumes.

Part C — The actual scroll command

void _jumpToBottom() {
  if (_pendingScrollJump) return;   // already one queued, don't stack up
  _pendingScrollJump = true;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _pendingScrollJump = false;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  });
}
Why addPostFrameCallback?

When a new word arrives → _StreamingBubble rebuilds → bubble gets taller. But at the moment ref.listen fires, Flutter hasn't drawn the taller bubble yet. maxScrollExtent still reflects the old shorter size.

If you call jumpTo immediately, you jump to the wrong position (the old bottom).

addPostFrameCallback says: wait until Flutter finishes drawing this frame, then scroll. By then maxScrollExtent has updated to reflect the taller bubble. You jump to the correct new bottom.

Why _pendingScrollJump?

Words arrive fast. Without this flag, every word would queue its own addPostFrameCallback. You'd have 20 scroll commands stacked up for the same frame, all competing with each other.

The flag ensures only one scroll command is queued at a time.

Layer 7 — The "Jump to latest" pill

AnimatedOpacity(
  opacity: _showJumpPill ? 1.0 : 0.0,
  duration: 200ms,
  child: IgnorePointer(
    ignoring: !_showJumpPill,   // invisible = can't tap it
    child: _JumpToLatestPill(
      onTap: () {
        _jumpToBottom();
        setState(() => _showJumpPill = false);
      },
    ),
  ),
)
The pill lives in a Stack on top of the message list. It's always in the widget tree — just invisible when not needed.

_showJumpPill is controlled by the scroll listener:


void _onScrollChange() {
  final show = !_isNearBottom;
  if (show != _showJumpPill) setState(() => _showJumpPill = show);
}
The scroll controller fires _onScrollChange every time you scroll even 1px. If you go above 40px from the bottom → pill appears. Come back within 40px → pill disappears.

IgnorePointer is important — without it, the invisible pill would still intercept taps in the area where it sits.

Full flow — every step when "Roses" appears on screen

ChatNotifier: accumulated = "Roses are red,"
              streamingContent = "Roses are red,"
                    ↓
_StreamingBubble.build() fires (ref.watch triggers it)
  content = "Roses are red,"
  AnimatedSwitcher: shows _StreamingContent
  StreamingMarkdownView renders "Roses are red,"
  Bubble gets taller
                    ↓
ref.listen in ChatScreen fires
  _isNearBottom? yes
  _jumpToBottom() called
  _pendingScrollJump = true
  addPostFrameCallback queued
                    ↓
Flutter draws the taller bubble (layout phase)
maxScrollExtent updates to new bottom
                    ↓
addPostFrameCallback fires
  _pendingScrollJump = false
  scrollController.jumpTo(maxScrollExtent)  ← correct new bottom
                    ↓
Screen scrolls down to show the new text
Summary table
What	Widget	Why
List of messages	ListView.builder	Only builds visible items
Entrance animation (play once)	_StreamingBubbleEntry	Isolates animation from rebuilds
GPU layer isolation	RepaintBoundary	Only redraws the bubble, not the whole screen
Live growing text	_StreamingBubble (ConsumerWidget)	Rebuilds only when streamingContent changes
Thinking → text transition	AnimatedSwitcher	Smooth fade between states
Blinking cursor	_BlinkingCursor	`
Scroll down per word	ref.listen + _jumpToBottom	Fires on every new word
Wait for layout before scrolling	addPostFrameCallback	Reads correct maxScrollExtent
No duplicate scrolls	_pendingScrollJump flag	Only one scroll queued at a time
Pill when user scrolled up	_showJumpPill + AnimatedOpacity	Appears when >40px from bottom
study.md
now tell me whole concept in simple word so that i cant tell thsi to interviewer ->markdown prasing nd rendering , gowing chat buuble and auto scolling alll the concepts , and imprtnce of keys and ticker and animation each and everythng
Let me write this exactly how you'd say it to an interviewer — simple, confident, complete.

How to explain the whole thing
Start with the problem
"The hardest part of building a chat app like ChatGPT is that the AI doesn't send the full response at once. It sends one word at a time. So you have three problems to solve simultaneously: render the growing text smoothly, don't make the whole screen rebuild on every word, and keep the scroll pinned to the bottom as the bubble grows."

Markdown Parsing — explain it like this
"When the AI responds, it might send markdown — bold text, code blocks, bullet points. The naive approach is to take the full text and pass it to a markdown library on every new word. But that means the library re-parses the entire response from scratch on every word. At 60 words per second, that's 60 full re-parses per second — the app lags badly.

So instead I built a custom parser that splits the response into blocks. A block is one paragraph, one code block, one heading — any chunk separated by a blank line. As new words arrive, only the last block (the one currently being written) is re-parsed and re-rendered. All the blocks above it are already finished, so they're cached and never touched again.

I called these CachedBlockWidgets. They build themselves exactly once — in initState — and never rebuild after that. I also wrapped each one in a RepaintBoundary, which means the GPU gives each block its own layer and doesn't redraw the old blocks when the new one grows. So no matter how long the response gets, the rendering cost stays constant."

The Keys problem — explain it like this
"Flutter uses keys to identify widgets in a list. If two widgets have the same key, Flutter crashes. The markdown parser is called on every new word and re-processes the entire text each time. Sometimes it produces 8 blocks, sometimes 7, sometimes 9 — depending on where the word boundary lands.

My early bug was: I tracked how many blocks were cached using a counter. But if the parser briefly returned fewer blocks than my counter, then on the next call when it returned more blocks again, my loop would try to add a block with a key that already existed — crash.

The fix was simple: instead of using a counter, I use the actual length of the cached list as my starting point. Since the list is append-only and never shrinks, the loop can only ever add new blocks, never duplicate old ones. Keys stay unique forever."

The Growing Bubble — explain it like this
"The streaming bubble is split into two separate widgets and this is the most important decision.

The outer widget — I call it BubbleEntry — owns the entrance animation. Fade in, slide up slightly, 220 milliseconds. It runs once when the bubble first appears and never again.

The inner widget — the actual bubble — rebuilds on every new word because it needs to show the growing text.

Why split them? Because if the animation lived on the same widget that rebuilds, Flutter would restart the fade-in animation on every single word. The bubble would flicker constantly. By putting the animation one level above in a StatefulWidget that never rebuilds, the animation plays once and the content rebuilds freely underneath it without disturbing the animation."

The Ticker — explain it like this
"Originally the bubble rebuilt directly whenever a new word arrived from the network. The problem was the network sends words at random speeds — sometimes 3 words burst in 50 milliseconds, sometimes there's a 200ms gap. This made the text appear in jerky bursts, not smooth.

A Ticker is Flutter's connection to the screen refresh signal. The screen refreshes 60 times per second. A Ticker fires in sync with that — exactly 60 times per second, no more, no less.

So I decoupled the network from the screen. The network puts words into a buffer as fast as they arrive. The Ticker reads from that buffer at a controlled rate — 72 characters per second at normal speed, up to 3x faster if the buffer gets too far ahead. The screen only updates 60 times per second regardless of how fast or slow the network is. This gives the smooth, natural typing feel you see in ChatGPT."

The ref.listen vs ref.watch — explain it like this
"Riverpod has two ways to react to state changes. ref.watch rebuilds the widget. ref.listen fires a callback without rebuilding.

The main ChatScreen uses ref.watch but only subscribes to the message list and status — not the streaming text. So the main screen never rebuilds during streaming.

The bubble uses ref.watch on only the streaming content. So only the bubble rebuilds on every word.

This means during streaming, exactly one widget is rebuilding — the bubble. Everything else — the input bar, the old messages, the app bar — stays completely still. That's how you maintain 60fps even while text is flowing in."

Auto Scroll — explain it like this
"Auto scroll has one tricky timing problem. When a new word arrives, the bubble grows taller. But at the exact moment the word arrives, Flutter hasn't drawn the taller bubble yet. If you scroll immediately, you're scrolling to the old bottom — you miss the new content by exactly one line.

The fix is addPostFrameCallback. It's Flutter's way of saying: finish drawing this frame completely, then run my code. So I tell Flutter: draw the taller bubble first, then scroll. By then the scroll knows the correct new bottom position.

On top of that, I have a flag called pendingScrollJump. Without it, every word would queue its own scroll command. At 60 words per second you'd have 60 scroll commands stacking up and fighting each other — visible stutter. The flag ensures only one scroll is queued at a time.

And I track whether the user is near the bottom. If they scroll up to read old messages, auto-scroll stops. The moment they come back within 40 pixels of the bottom, it re-engages automatically. If they're far up, a pill button appears they can tap to jump back down."

RepaintBoundary — explain it like this
"Flutter renders in two steps. First it draws everything into picture commands. Then the GPU composites those pictures onto the screen. RepaintBoundary creates a separate GPU layer for a widget. Once that layer is painted, the GPU caches it. If the widget doesn't change, the GPU reuses the cached layer — zero redraw cost.

I put RepaintBoundary on every completed markdown block. So when the active block at the bottom grows, Flutter only redraws that one block. The GPU composites all the cached old blocks for free. In a long response with 20 paragraphs, only the last paragraph is ever redrawn — the other 19 are served from GPU cache."

AnimatedSwitcher — explain it like this
"When the bubble first appears, it shows a thinking indicator — a pulsing blue dot with the word Thinking. When the first word arrives, it needs to switch to showing actual text.

AnimatedSwitcher handles this transition automatically. You give it a child. When the child changes, it fades out the old one and fades in the new one. The key detail is you must give each child a unique key — otherwise Flutter thinks it's the same widget just with different content, and won't animate.

So the thinking indicator has key 'thinking' and the text content has key 'content'. When content changes from empty to having text, AnimatedSwitcher sees two different keys and triggers the crossfade — smooth 300 millisecond transition from pulsing dot to actual text."

The blinking cursor — explain it like this
"Just a | character with a looping fade animation. flutter_animate has an onPlay callback where you can say repeat in reverse — so it fades out, then fades back in, then out again, forever. It disappears automatically when streaming ends because the whole bubble is replaced by the finished static message."

The one-paragraph version for when you want to summarise it all
"The streaming chat bubble works in layers. The network sends words one at a time into a buffer. A Ticker reads that buffer at a controlled rate and grows the displayed text smoothly at 60fps. The text is split into markdown blocks — completed blocks are cached and never redrawn, only the last active block updates. The bubble lives inside a wrapper widget that owns the entrance animation, keeping it isolated so the animation doesn't restart on every word. Auto-scroll uses Flutter's post-frame callback to wait until the bubble has fully grown before scrolling to the bottom, and a flag prevents duplicate scroll commands. The whole system is designed so that during streaming, exactly one widget rebuilds — the bubble — and everything else on screen stays completely still."

PROJECT_PLAN.md
how we have done this show code and explain The text is split into markdown blocks — completed blocks are cached and never redrawn, only the last active block updates.
Let me pull up all three files involved.

Read markdown_block.dart
Read markdown_parser.dart
Read streaming_markdown_view.dart
Good. Now let me walk through every piece with a real example.

The example response we'll use
Imagine Gemini responds with this:


Roses are red and beautiful flowers.
They bloom in many colours.

## History of Roses

Roses have been grown for centuries.
That's 3 blocks:

A paragraph (2 lines)
A heading
Another paragraph (1 line)
Step 1 — MarkdownBlock — what is one block?

class MarkdownBlock {
  final BlockType type;    // paragraph? heading? codeBlock? list?
  final String content;   // the actual text inside it
  final String? language; // only used for code blocks (dart, python etc)
}
Think of it like a container. One block = one chunk of related content.

appendLine just glues a new line onto the existing content:


MarkdownBlock appendLine(String line) => MarkdownBlock(
  content: content.isEmpty ? line : '$content\n$line',
  // "Roses are red" + "\n" + "They bloom" = "Roses are red\nThey bloom"
);
Step 2 — MarkdownParser — how it splits text into blocks
This is the brain. You give it the full text so far, it gives back:

completedBlocks — blocks that are fully done
activeBlock — the block currently being written
How it classifies each line

static BlockType _classifyLine(String line) {
  if (RegExp(r'^#{1,6}\s').hasMatch(line)) return BlockType.heading;
  // starts with # or ## or ### etc → heading

  if (line.startsWith('> '))            return BlockType.blockquote;
  if (RegExp(r'^[-*+]\s').hasMatch(line)) return BlockType.bulletList;
  if (RegExp(r'^\d+\.\s').hasMatch(line)) return BlockType.numberedList;

  return BlockType.paragraph; // anything else
}
Simple pattern matching. ## History → heading. - item → bullet list. Normal text → paragraph.

How it decides when a block is finished
A block is finished when:

A blank line appears — blank line always ends the current block
The type changes — paragraph followed by a heading → paragraph is done

if (line.trim().isEmpty) {
  // blank line → complete whatever was active
  if (active != null) {
    completed.add(active);
    active = null;
  }
  continue;
}
Walking through the roses example line by line
Let's say streamingContent at one moment is:


Roses are red and beautiful flowers.\nThey bloom in many colours.\n\n## History of Roses\n
The parser splits on \n and processes each line:


Line 1: "Roses are red and beautiful flowers."
  → classified as paragraph
  → active = MarkdownBlock(paragraph, "Roses are red...")

Line 2: "They bloom in many colours."
  → classified as paragraph
  → same type, so: active = active.appendLine("They bloom...")
  → active = MarkdownBlock(paragraph, "Roses are red...\nThey bloom...")

Line 3: "" (blank line)
  → blank line → completed.add(active)
  → completed = [paragraph block]
  → active = null

Line 4: "## History of Roses"
  → classified as heading
  → active = MarkdownBlock(heading, "## History of Roses")

Line 5: "" (this is the last line, still being typed)
  → it's the last line so stays as activeBlock
Result:


completedBlocks = [
  MarkdownBlock(paragraph, "Roses are red...\nThey bloom..."),
]
activeBlock = MarkdownBlock(heading, "## History of Roses")
Step 3 — StreamingMarkdownView — how it renders using the parser
This is the key widget. It has a State that holds the cache.


class _StreamingMarkdownViewState extends State<StreamingMarkdownView> {
  MarkdownParser _parser = MarkdownParser.initial();
  final List<_CachedBlockWidget> _cachedWidgets = [];  // ← the cache
didUpdateWidget — fires every time a new word arrives

@override
void didUpdateWidget(StreamingMarkdownView old) {
  super.didUpdateWidget(old);
  if (old.streamingContent != widget.streamingContent) {

    // re-parse the full text
    _parser = MarkdownParser.parse(widget.streamingContent);
    
    final completed = _parser.completedBlocks;

    // only add NEW blocks to cache, start from where we left off
    for (var i = _cachedWidgets.length; i < completed.length; i++) {
      _cachedWidgets.add(
        _CachedBlockWidget(key: ValueKey(i), block: completed[i]),
      );
    }
  }
}
Say the cache currently has 0 widgets. Parser returns 1 completed block.
Loop runs from index 0 to 0 → adds block 0 to cache.

Next word arrives. Parser still returns 1 completed block (the active one is still being written).
Loop runs from index 1 to 0 → doesn't run at all. Cache stays at 1. Nothing duplicated.

Next word finishes the heading. Parser returns 2 completed blocks.
Loop runs from index 1 to 1 → adds block 1 to cache. Cache is now 2.

build — what actually renders on screen

@override
Widget build(BuildContext context) {
  return Column(
    children: [
      ..._cachedWidgets,          // all completed blocks (never rebuilt)
      if (_parser.activeBlock != null)
        _ActiveBlockWidget(block: _parser.activeBlock!),  // the live block
    ],
  );
}
Column with all cached blocks first, then the active one at the bottom.

Step 4 — _CachedBlockWidget — builds ONCE, never again

class _CachedBlockWidgetState extends State<_CachedBlockWidget> {
  late Widget _built;

  @override
  void initState() {
    super.initState();
    _built = RepaintBoundary(child: _renderBlock(widget.block));
    // builds the widget ONE time here
  }

  // ← NO didUpdateWidget. Intentional.
  // Even if Flutter calls build() again, it returns the same cached widget.

  @override
  Widget build(BuildContext context) => _built;  // just return what was built once
}
_renderBlock turns the block into actual Flutter widgets:

paragraph/heading → MarkdownBody (the flutter_markdown library — renders bold, italic, etc.)
code block → CodeBlockWidget (the syntax highlighted box)
RepaintBoundary wraps it → GPU caches this block's pixels permanently.

Step 5 — _ActiveBlockWidget — rebuilds on every word

class _ActiveBlockWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (block.type == BlockType.codeBlock) {
      return CodeBlockWidget(code: block.content, language: block.language);
    }
    return SelectableText(
      block.content,   // ← just plain text, no markdown parsing
      style: AppTextStyles.body(...),
    );
  }
}
Why SelectableText and not MarkdownBody here?

Because MarkdownBody re-parses the entire text every time it builds. The active block rebuilds on every single word. If you used MarkdownBody here, you'd be parsing markdown 60 times per second.

SelectableText just displays raw text — zero parsing cost. The markdown formatting (bold, italic etc.) only renders once the block is complete and moved to _CachedBlockWidget which uses MarkdownBody.

The complete picture with your roses example
Let's trace through word by word:


Word "Roses" arrives:
  _parser: completedBlocks=[], activeBlock=paragraph("Roses")
  _cachedWidgets = []
  Screen: [ActiveBlock: "Roses"]

Word "are red" arrives:
  _parser: completedBlocks=[], activeBlock=paragraph("Roses are red")
  _cachedWidgets = []
  Screen: [ActiveBlock: "Roses are red"]

"They bloom in many colours.\n\n" arrives (blank line = block done):
  _parser: completedBlocks=[paragraph("Roses are red\nThey bloom...")], activeBlock=null
  Loop: adds block 0 to cache
  _cachedWidgets = [CachedBlock(0, paragraph)]
  Screen: [CachedBlock(paragraph) ← NEVER REBUILDS AGAIN]

"## History" arrives:
  _parser: completedBlocks=[paragraph], activeBlock=heading("## History")
  Loop: starts at index 1, completed has 1 item → loop doesn't run
  _cachedWidgets = [CachedBlock(0, paragraph)]
  Screen: [CachedBlock(paragraph), ActiveBlock: "## History"]

"## History of Roses\n\n" arrives (blank line = heading done):
  _parser: completedBlocks=[paragraph, heading], activeBlock=null
  Loop: starts at index 1, completed has 2 items → adds block 1
  _cachedWidgets = [CachedBlock(0, paragraph), CachedBlock(1, heading)]
  Screen: [CachedBlock(paragraph), CachedBlock(heading) ← BOTH FROZEN]

"Roses have been grown" arrives:
  _parser: completedBlocks=[paragraph, heading], activeBlock=paragraph("Roses have been grown")
  Loop: starts at index 2, completed has 2 → doesn't run
  Screen: [CachedBlock(paragraph), CachedBlock(heading), ActiveBlock: "Roses have been grown"]
The duplicate key bug and fix — in simple words
The bug:

Old code used a counter _lastCompletedCount = 0. Loop ran from _lastCompletedCount to completed.length.

Sometimes the parser returns 2 blocks, then due to a word boundary it returns 1 block, then 2 again. Counter was at 2. When it went back to 2, loop ran from 2 to 2 — fine. But Flutter already had a widget with ValueKey(1) in the cache. If the counter got confused, it'd try to add ValueKey(1) again → crash: "Duplicate keys found".

The fix:

Use _cachedWidgets.length instead of a counter.


for (var i = _cachedWidgets.length; i < completed.length; i++) {
_cachedWidgets only ever grows. It never shrinks. So _cachedWidgets.length always tells the truth about how many widgets we've actually added. If we've added 2, start from 2. Can never go backwards. Can never duplicate.

Summary in one visual

Full text arriving word by word
            ↓
     MarkdownParser.parse()
            ↓
   ┌─────────────────────────┐
   │   completedBlocks       │   activeBlock
   │  [paragraph, heading]   │   [paragraph "Roses..."]
   └─────────────────────────┘
            ↓                          ↓
   _CachedBlockWidget            _ActiveBlockWidget
   builds ONCE in initState      rebuilds every word
   uses MarkdownBody              uses SelectableText
   wrapped in RepaintBoundary     no RepaintBoundary
   GPU caches forever             redraws each token
so u are sayint it only caches the block and when new bloc comes instead of rebuild the whole message bubbe it just rebuild sthe nex bloc ?
Yes, exactly. Let me show you visually.

What happens WITHOUT this system (naive approach)
Every word → rebuild everything


Word 1:  rebuild entire bubble
Word 2:  rebuild entire bubble  
Word 3:  rebuild entire bubble
Word 50: rebuild entire bubble  ← rerenders all 50 words again
Word 51: rebuild entire bubble  ← rerenders all 51 words again
At 60 words/sec, Flutter is re-rendering the entire response from scratch 60 times per second. As the response gets longer, each rebuild gets more expensive.

What happens WITH the cache system

Word 1:  rebuild activeBlock only
Word 2:  rebuild activeBlock only
Word 3:  rebuild activeBlock only

   ← blank line arrives, paragraph is done →

Word 4:  paragraph FROZEN as CachedBlock(0) ← never touches this again
         rebuild new activeBlock only

Word 10: rebuild new activeBlock only
         CachedBlock(0) still frozen ← GPU serving it from cache

   ← another blank line, second block done →

Word 11: CachedBlock(0) frozen
         CachedBlock(1) frozen ← also never touched again
         rebuild new activeBlock only
No matter how long the response gets — 10 blocks, 20 blocks — only the last block ever rebuilds. All previous blocks are frozen.

One picture

┌─────────────────────────────────┐
│ CachedBlock(0) — paragraph      │  ← built once, frozen, GPU cached
│ "Roses are red and beautiful"   │
├─────────────────────────────────┤
│ CachedBlock(1) — heading        │  ← built once, frozen, GPU cached
│ "## History of Roses"           │
├─────────────────────────────────┤
│ CachedBlock(2) — paragraph      │  ← built once, frozen, GPU cached
│ "Roses have been grown for..."  │
├─────────────────────────────────┤
│ ActiveBlock ← ONLY THIS REBUILDS│  ← rebuilds on every word
│ "for centuries. They were fir"  │
└─────────────────────────────────┘
Every new word → only the bottom box changes. Everything above it doesn't even know a word arrived.

One line answer for the interviewer
"Yes. Completed blocks are cached as StatefulWidgets that build once in initState and never again. Only the last active block rebuilds on every word. So no matter how long the response is, the rebuild cost is always constant — just one small block at the bottom."

but on onr bloc the tokens new incoming tokens rebuild the entire block right?
Yes, exactly right.

What actually happens inside one active block
Every new word → _ActiveBlockWidget rebuilds → redraws the entire block's text from scratch.


Active block content = "Roses are red"
New word " and" arrives
Active block content = "Roses are red and"
→ entire active block rebuilds and redraws "Roses are red and"
But this is fine — here is why
The active block is always small.

It only contains the text of the current paragraph being written. Maybe 1-3 lines of text. Rebuilding a small SelectableText with 50 characters is nearly zero cost.

Compare that to the naive approach — rebuilding the entire response which could be 2000 characters across 10 paragraphs.


Naive approach:           Cache approach:
rebuild 2000 chars        rebuild 50 chars (active block only)
rebuild full MarkdownBody rebuild SelectableText (zero parsing)
Also — active block uses SelectableText not MarkdownBody
This is the second saving.

MarkdownBody parses the text for bold, italic, links etc. That parsing takes time.

SelectableText just displays raw text. Zero parsing. No formatting processing.

So even though the active block rebuilds on every word, it is:

Small (only current paragraph)
Cheap (no markdown parsing, just plain text)
Once the block is complete and becomes a CachedBlockWidget, then MarkdownBody runs once and formats it properly — bold, italic, all of it. And that formatted result is frozen forever.

The full picture together

Active block gets a new word every ~16ms
  → rebuilds SelectableText("Roses are red and...")  ← cheap, small, raw text
  → user sees plain text growing

Blank line arrives → block is complete
  → becomes CachedBlockWidget
  → MarkdownBody runs ONCE → formats bold/italic/links properly
  → wrapped in RepaintBoundary → GPU caches it
  → never touched again
So yes, inside one active block every word causes a full rebuild of that block. But it is intentionally kept cheap — small text, no parsing. The expensive formatting only happens once when the block is done.

how we are making that the bloc is no more acive i mean the bloc is completed
Great question. The answer is one thing — a blank line.

Look at the parser

if (line.trim().isEmpty) {
  // blank line → complete whatever was active
  if (active != null) {
    completed.add(active);   // ← move to completed
    active = null;           // ← no more active block
  }
  continue;
}
When the parser sees a blank line — it takes whatever is in active, moves it to completed, and sets active = null.

Walk through the roses example
Gemini sends this text word by word:


"Roses are red.\n\n## History\n"
The parser processes it line by line:


Line: "Roses are red."
  → active = paragraph("Roses are red.")

Line: "" (blank line)
  → completed.add(paragraph("Roses are red."))   ← BLOCK IS DONE
  → active = null

Line: "## History"
  → active = heading("## History")               ← NEW BLOCK STARTS
But who sends that blank line?
Gemini does. When the AI finishes a paragraph, it naturally writes a blank line before starting the next section. That blank line comes through the stream as a \n\n in the text. The parser sees it and completes the block.

The other way a block completes — type switch

} else {
  // current block is paragraph, next line is heading
  // → flush the paragraph, start the heading
  completed.add(active);
  active = MarkdownBlock(type: blockType, content: line);
}
If the current block is a paragraph and suddenly a ## heading line arrives — the paragraph is completed immediately even without a blank line.

Simple summary
A block becomes complete in 3 situations:

Situation	Example
Blank line arrives	"Roses are red.\n\n"
Different type starts	paragraph then ## Heading
Code fence closes	``` closing line arrives
Until one of these three happens — the block stays active and rebuilds on every word.