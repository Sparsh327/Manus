# PROJECT_PLAN.md — Manus AI Clone: Engineering Reference

> **For AI sessions:** Read the "Quick Context" section first (2 min). Then navigate to the specific section relevant to your current task. Cross-reference TASK_TRACKER.md for current status and AGENTS.md for coding rules.

---

## Quick Context (read first — 2 minutes)

**What we are building:** A pixel-perfect Flutter clone of the Manus AI Agent app (chat-first agentic interface). Trial assignment. 5-day deadline. Evaluators hold it next to the real Manus app on a real device.

**The bar:** CRED / Linear / Arc level UI quality. Partial but polished > complete but janky.

**Backend:** Google Gemini API (gemini-2.5-flash, free tier). Streaming via raw Dio + SSE. No mock data for chat.

**Evaluation weight (approximate):**
- Chat screen (streaming, markdown, scroll, bubbles): ~40%
- Home empty state suggestion chip animation: ~15%
- Drawer + history (spring physics): ~10%
- Auth + Onboarding + Splash: ~10%
- Everything else: ~25%

**State management:** `flutter_riverpod` — `Notifier` / `AsyncNotifier` only. No `StateNotifier`. No `riverpod_generator`. No `@riverpod` codegen.

**No Figma.** The live Manus app IS the design spec. Screenshots are reverse-engineered before each screen is built.

---

## Evaluation Priority Map

| Priority | Feature | Why It Weighs So Much |
|---|---|---|
| P0 | Streaming markdown renderer | Explicitly called "the hardest engineering problem". Tested frame-by-frame. |
| P0 | Suggestion chip → input field animation | Evaluator quote: *"This single animation says more about you than any test suite."* |
| P1 | Chat screen overall | Most evaluation weight of any single screen |
| P1 | Smart auto-scroll (release/re-engage) | Explicitly listed as "will be tested" |
| P1 | Stream cancellation (Dio CancelToken) | Tested: must actually cancel the HTTP request, not just ignore tokens |
| P1 | iOS typography (SF Pro, not Inter) | Quote: *"Inter on iOS = immediate fail"* |
| P2 | Drawer spring physics | "Must feel like iOS sheet physics even on Android" |
| P2 | Send button morph (plane→spinner→stop) | Must morph, not crossfade |
| P3 | Onboarding spring page indicator | Spring physics, not linear |
| P3 | Code block copy checkmark morph | 1.5s revert, haptic, morph not crossfade |
| P4 | Settings, Paywall | UI only, lower weight |

---

## Architecture Decisions

### State Management: Riverpod (Notifier/AsyncNotifier)

**Decision:** Use `flutter_riverpod` with `Notifier<S>` for most features and `AsyncNotifier<S>` only when the initial build itself is async.

**Why not BLoC (original boilerplate):** `CONTEXT.md` explicitly requires Riverpod. Migrated in Phase 0.

**Why not StateNotifier:** Deprecated by the Riverpod team. Signals poor knowledge of the current API in an interview context.

**Why not riverpod_generator:** Forbidden by `CONTEXT.md` spec. Also — evaluators may grep for `@riverpod`.

**Provider organization:**
- Infrastructure providers → `core/providers/core_providers.dart`
- Feature data providers (data sources + repository) → `data/providers/<feature>_data_providers.dart`
- Feature notifier + NotifierProvider → `presentation/<feature>/notifier/<feature>_notifier.dart`
- Feature state class → `presentation/<feature>/notifier/<feature>_state.dart`

### Navigation: GoRouter

**Decision:** All navigation via `context.go()` / `context.push()`. No `Navigator.push` anywhere.

**Route constants** in `router/app_routes.dart`. Route definitions in `router/app_router.dart`.

**Navigation from Notifier:** Notifiers do not hold a `BuildContext`. Navigation intent is signalled via an `action` enum field in state. Screens use `ref.listen` to react and call `context.go(...)`.

```dart
// Pattern: Notifier sets action, screen listens and navigates
ref.listen<AuthState>(authProvider, (_, next) {
  if (next.action == AuthAction.navigateToHome) context.go(AppRoutes.home);
});
```

### Local Persistence: Hive

**Decision:** Hive for conversation and message persistence. Conversations survive app restart.

**Box strategy:**
- `conversations` box → `ConversationModel` list (metadata only: id, title, createdAt, updatedAt, pinned, archived)
- `messages_<conversationId>` box → `ChatMessageModel` list per conversation

**Why not Isar:** Hive is already in the boilerplate and configured. Both meet the spec. Switching to Isar adds setup time with no evaluation benefit.

### Dependency Injection: Riverpod Providers only

**Decision:** No GetIt. All DI through Riverpod `Provider<T>`. Providers are lazy by default — only instantiated when first watched.

GetIt was removed in Phase 0 migration.

### Error Handling: Either<Failure, Output>

**Decision:** Repository layer returns `Either<Failure, Output>` (dartz). Notifiers call `.fold()` and update state with error message. Screens render inline error UI — never dialogs, never snackbars for API errors.

**Failure types:**
- `ServerFailure` — API/HTTP errors
- `CacheFailure` — Hive read/write errors
- `ConnectionFailure` — no internet
- `StreamCancelledFailure` — user cancelled stream (not an error, special case)

### No Code Generation

**Decision:** No `@freezed`, no `build_runner`, no `riverpod_generator`.

All state classes are plain Dart immutable classes with manual `copyWith`. This adds ~10 lines per state class but eliminates all code-gen complexity, `part` file juggling, and build_runner timeouts.

---

## Package Decisions

| Package | Version | Decision & Reasoning |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | Required by spec. Notifier/AsyncNotifier API only. |
| `go_router` | ^17.0.0 | Required by spec. Typed routes. |
| `dio` | ^5.9.0 | Required for Gemini SSE streaming with CancelToken. |
| `hive` | ^2.2.3 | Local persistence. Already configured. |
| `dartz` | ^0.10.1 | Either<L,R> for functional error handling. |
| `equatable` | ^2.0.8 | Value equality for domain entities. |
| `flutter_screenutil` | ^5.9.3 | All dimensions go through `.w`, `.h`, `.sp`, `.r`. |
| `flutter_animate` | TBD | Primary animation layer. Spring physics + stagger. |
| `cached_network_image` | TBD | Required by spec. Always pass `cacheWidth`/`cacheHeight`. |
| `flutter_svg` | TBD | Custom illustrations for empty/error states. |
| `talker` | TBD | General-purpose logger. `print()`/`debugPrint()` are forbidden. |
| `connectivity_plus` | ^7.0.0 | Network state detection. Already configured. |

**NOT using:**
- `google_generative_ai` SDK — cannot expose Dio `CancelToken` for true HTTP cancellation. Use raw Dio + SSE instead.
- `flutter_markdown` for streaming — causes full tree rebuild on every token. Use custom block-segmented renderer.
- `riverpod_generator` — forbidden by spec.
- `StateNotifier` — deprecated.
- `freezed` — removed. Plain immutable classes instead.

---

## Critical Engineering Decisions

*Only difficult/high-impact decisions are documented here. Simple CRUD features are not.*

---

### CE-1: Streaming Markdown Renderer

**Problem:** Naive `Markdown(data: fullText)` rebuilds the entire widget tree on every token. At ~10 tokens/second over a 500-token response, this is ~500 full rebuilds. Fails 60fps target on mid-range Android.

**Chosen approach: Custom block-segmented renderer**

**Architecture:**
```
StreamingMarkdownView
  └── Column
       ├── MarkdownBlockWidget(block: blocks[0], key: ValueKey(0))  // NEVER rebuilds
       ├── MarkdownBlockWidget(block: blocks[1], key: ValueKey(1))  // NEVER rebuilds
       ├── ...
       └── MarkdownBlockWidget(block: blocks[n], key: ValueKey(n))  // rebuilds per token
```

**Block types to handle:** `paragraph`, `codeFence`, `bulletList`, `numberedList`, `heading`, `blockquote`, `table`, `horizontalRule`

**Parser state machine:**
- Processes the stream character-by-character / line-by-line
- Maintains `currentBlock` + `isCurrentBlockComplete`
- A block is "complete" when its closing delimiter is received (blank line for paragraph, ` ``` ` for code fence, etc.)
- Completed blocks are immutable — keyed widgets never change

**Why not flutter_markdown:** Even with `RepaintBoundary`, `flutter_markdown` re-parses the entire string on every build call. The parse cost alone (not just render) causes jank. No block-level API is exposed.

**Why not flutter_markdown + AutomaticKeepAliveClientMixin:** KeepAlive prevents disposal but not rebuilds. The widget still rebuilds on every `setState`. Doesn't help.

**Code block within stream:** A code fence that hasn't received its closing ` ``` ` is rendered as an "in-progress" code block with a different visual state (pulsing border or faded). When the closing delimiter arrives, it transitions to the complete code block UI.

**Performance target:** 60fps on Pixel 4a and iPhone 12 mini throughout a 500-token stream.

---

### CE-2: Chat Stream State Architecture (Riverpod)

**Problem:** A Gemini stream is a continuous async event sequence. Must support: cancellation (with partial preservation), fork-on-edit, app lifecycle interruption, error recovery inline.

**Chosen approach: `Notifier<ChatState>` with explicit `StreamSubscription` + `CancelToken`**

```dart
class ChatNotifier extends Notifier<ChatState> {
  CancelToken? _cancelToken;
  StreamSubscription<String>? _streamSubscription;

  Future<void> sendMessage(String prompt) async {
    _cancelToken = CancelToken();
    // Add user message, set streaming = true
    state = state.withUserMessage(prompt).copyWith(isStreaming: true);

    _streamSubscription = ref
        .read(geminiServiceProvider)
        .streamResponse(prompt, cancelToken: _cancelToken)
        .listen(
          (token) => state = state.appendTokenToLastMessage(token),
          onError: (e) => state = state.withStreamError(e),
          onDone: () => state = state.copyWith(isStreaming: false),
        );
  }

  void stopStream() {
    _cancelToken?.cancel('User cancelled');  // actual HTTP cancel
    _streamSubscription?.cancel();
    _cancelToken = null;
    _streamSubscription = null;
    state = state.markLastMessageStopped(); // preserves partial + badge
  }

  @override
  ChatState build() {
    ref.onDispose(() {
      _cancelToken?.cancel('Notifier disposed');
      _streamSubscription?.cancel();
    });
    return ChatState.initial();
  }
}
```

**Why not StreamProvider:** Cannot cancel and preserve partial content. State resets on cancel.

**Why not AsyncNotifier:** Designed for a single Future lifecycle, not continuous stream management. `state` setter semantics fight the streaming model.

**Fork-on-edit:** `editMessageAndResend(index, newText)` → calls `stopStream()` → removes all messages after `index` from state → calls `sendMessage(newText)`.

---

### CE-3: Smart Auto-Scroll

**Problem:** While streaming, scroll must pin to bottom. User scrolling up releases auto-scroll. Returning within 40px re-engages. "Jump to latest" pill fades in/out.

**Chosen approach: `ScrollController` with pixel tracking + `jumpTo`**

```dart
bool _autoScrollEnabled = true;

void _onScroll() {
  final pos = _scrollController.position;
  final atBottom = pos.pixels >= pos.maxScrollExtent - 40;
  
  if (!atBottom && _autoScrollEnabled) {
    setState(() { _autoScrollEnabled = false; _showJumpPill = true; });
  } else if (atBottom && !_autoScrollEnabled) {
    setState(() { _autoScrollEnabled = true; _showJumpPill = false; });
  }
}

// Called after every state rebuild that appends a token
void _pinToBottom() {
  if (!_autoScrollEnabled) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  });
}
```

**Why `jumpTo` not `animateTo`:** `animateTo` creates a competing animation on every token. At 10 tokens/second, 10 animations fight each other — visible stutter. `jumpTo` is instant and idempotent.

**Why `addPostFrameCallback`:** The new token causes a layout change (bubble grows). `maxScrollExtent` is only updated after the frame renders. Calling `jumpTo` before the frame gives the wrong value.

**"Jump to latest" pill:** `AnimatedOpacity` wrapping a `GestureDetector`. Fades in when `_showJumpPill = true`. Tapping calls `jumpTo(maxScrollExtent)` + sets `_autoScrollEnabled = true`.

---

### CE-4: Gemini API — Raw Dio SSE

**Problem:** Must support true HTTP-level stream cancellation (Dio CancelToken). The `google_generative_ai` SDK wraps its own HTTP client — CancelToken cannot reach it.

**Chosen approach: Raw Dio with SSE parsing**

**Gemini SSE endpoint:**
```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse&key={API_KEY}
```

**Response format:** Server-Sent Events. Each event is:
```
data: {"candidates":[{"content":{"parts":[{"text":"token"}]}}]}

data: {"candidates":[{"content":{"parts":[{"text":" here"}]}}]}
```

**SSE parser logic:**
```dart
Stream<String> _parseSSE(Stream<Uint8List> byteStream) async* {
  final buffer = StringBuffer();
  await for (final chunk in byteStream.transform(utf8.decoder)) {
    buffer.write(chunk);
    final lines = buffer.toString().split('\n');
    buffer.clear();
    // Last line may be incomplete — keep it in buffer
    buffer.write(lines.removeLast());
    for (final line in lines) {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6).trim();
        if (jsonStr == '[DONE]') return;
        final token = _extractToken(jsonStr);
        if (token != null) yield token;
      }
    }
  }
}
```

**API key security:** Never hardcoded. Always via `--dart-define=GEMINI_API_KEY=...` and read with `const String.fromEnvironment('GEMINI_API_KEY')`. Never committed to git.

---

### CE-5: Platform Typography

**Problem:** iOS must use SF Pro (system font), Android must use Inter. Using Inter on iOS is the most common clone failure and results in immediate rejection.

**Chosen approach: `ThemeData.fontFamily` set per platform**

```dart
ThemeData(
  fontFamily: Platform.isIOS ? null : 'Inter',
  // null on iOS → Flutter inherits system font → SF Pro automatically
  textTheme: Platform.isIOS ? _cupertinoTextTheme() : _materialTextTheme(),
)
```

**Monospace for code blocks:** `fontFamily: Platform.isIOS ? null : 'JetBrainsMono'`

**Font assets (Android only):** Inter Regular/Medium/SemiBold/Bold + JetBrains Mono Regular declared in `pubspec.yaml`. NOT loaded on iOS — iOS never references them.

**Note:** Test on a real iPhone. The simulator shows incorrect font metrics.

---

### CE-6: Suggestion Chip → Input Field Animation

**Problem:** Tapping a suggestion chip must animate the chip flying/morphing into the text input field — not just paste text. This is the single most heavily evaluated animation.

**Chosen approach: Hero animation with custom flight path**

```dart
// Chip has a Hero tag matching its content
Hero(
  tag: 'chip_${chip.text}',
  child: SuggestionChip(text: chip.text),
)

// InputField reveals the Hero destination
Hero(
  tag: 'chip_${activeChipText}',
  child: InputField(),
)
```

On chip tap:
1. Set `activeChipText` in state
2. Trigger the Hero transition — Flutter animates the chip rect → input rect
3. On animation complete, clear `activeChipText`, populate `inputController.text`
4. Use a custom `HeroFlightShuttleBuilder` for the morph (pill shape → rectangle)

**Why Hero over AnimatedPositioned:** Hero handles the coordinate system transformation between two different widget subtrees automatically. AnimatedPositioned requires manual coordinate calculation (fragile, breaks on different screen sizes).

---

## Implementation Phases

### Phase 0 — Foundation ✅ Partially Complete
- [x] Riverpod migration (remove BLoC, Freezed, GetIt)
- [x] Update AGENTS.md
- [ ] Add missing packages (flutter_animate, cached_network_image, flutter_svg, talker)
- [ ] Set up full AppTheme (light + dark token sets)
- [ ] Platform-aware typography in ThemeData
- [ ] Asset directory structure + font declarations
- [ ] Gemini service (raw Dio SSE)
- [ ] Logger (Talker) wired up globally

### Phase 1 — Chat Domain + Core Engine
- [ ] Conversation + ChatMessage entities
- [ ] Hive models + adapters
- [ ] ConversationRepository + ChatMessageRepository
- [ ] GeminiService (SSE streaming, CancelToken)
- [ ] ChatNotifier (stream management, cancel, fork-on-edit)
- [ ] Custom streaming markdown renderer (block-segmented)

### Phase 2 — Chat Screen UI
- [ ] Message list (ListView.builder, stable keys)
- [ ] User message bubble (right-aligned, spring entrance)
- [ ] Assistant message (left-aligned, spring entrance)
- [ ] Streaming caret pulse on active bubble
- [ ] Input bar (multiline height animation, max 6 lines)
- [ ] Send/Stop button morph (plane→spinner→stop→plane)
- [ ] Smart auto-scroll + "Jump to latest" pill
- [ ] Code block widget (horizontal scroll, copy morph, language label)
- [ ] Tool-call collapsible (spring expand/collapse)
- [ ] Inline image rendering
- [ ] App lifecycle stream handling

### Phase 3 — Home / Empty State
- [ ] Suggestion chips (stagger animate in, 60ms, easeOutCubic)
- [ ] Chip → input field hero animation
- [ ] Model picker pill
- [ ] Home → Chat transition

### Phase 4 — Auth + Onboarding + Splash
- [ ] Splash animated logo sequence
- [ ] Onboarding 3 slides (animated illustrations, spring page indicator)
- [ ] Auth screen (email/Google/Apple buttons)
- [ ] Error shake animation
- [ ] Success transition to Home

### Phase 5 — Chat Drawer + History
- [ ] Drawer spring physics (damped, matches iOS sheet feel)
- [ ] Grouped sections from Hive (Today/Yesterday/7 days/Older)
- [ ] Sticky section headers
- [ ] Search with 300ms debounce
- [ ] Swipe-to-delete with undo snackbar
- [ ] Long-press context menu (iOS-style scale + blur)
- [ ] Pull-to-refresh (local + remote sync)
- [ ] Infinite scroll

### Phase 6 — Remaining Screens
- [ ] Mode Picker bottom sheet (icon morphs between modes)
- [ ] Attachment tray (animated reveal, thumbnails, drag-to-reorder)
- [ ] Settings screen (iOS-style grouped list, theme toggle)
- [ ] Paywall/Subscription screen (UI only, no real payments)

### Phase 7 — Polish + Performance
- [ ] Haptics (all interaction points per spec)
- [ ] Accessibility (Semantics labels on all interactive elements)
- [ ] Font scale 200% layout testing
- [ ] Theme switch 200ms cross-fade (animated theme transition)
- [ ] Network reconnection + retry inline UI
- [ ] Long conversation performance profiling (200-msg, 60fps target)
- [ ] Memory profiling (<250MB RSS target)
- [ ] Cold start profiling (<2.5s Pixel 6, <2.0s iPhone 13)
- [ ] Release APK build + size check (<35MB)

---

## Screenshot Reverse-Engineering Process

Before building each screen, screenshots are taken from the live Manus app and shared for analysis. The analysis extracts:

1. **Spacing values** — padding, margin, gaps between elements (estimate in dp)
2. **Corner radius** — bubble, chips, cards, buttons
3. **Color values** — background, text, surface, border (use color picker tool)
4. **Icon details** — glyph shape, stroke weight, size
5. **Shadow** — offset, blur, spread, color, opacity
6. **Animation timing** — record at 240fps, step frame-by-frame to estimate duration + easing

**Screenshot priority order:**
1. Chat screen (active stream, code block visible)
2. Home empty state (chips visible)
3. Auth screen (default + error state)
4. Drawer open (history visible)
5. Splash sequence
6. Onboarding slides
7. Settings + Paywall

---

## Performance Budget

| Metric | Target |
|---|---|
| Frame rate (streaming) | 60fps minimum — no frames >16ms (99% of time) |
| Cold start | <2.5s Pixel 6 / <2.0s iPhone 13 (release build) |
| Time to first token | <800ms after send tap |
| 200-message scroll | Zero dropped frames |
| Memory (200 msgs + 5 images) | <250MB RSS |
| Release APK size | <35MB universal |

---

## Coding Standards (Quick Reference)

*Full version in AGENTS.md*

- All dimensions via `flutter_screenutil`: `.w`, `.h`, `.sp`, `.r`
- All navigation via `context.go()` — never `Navigator.push`
- All logging via `Talker` — never `print()` or `debugPrint()`
- All API errors shown inline — never dialogs or alert snackbars
- Screens are `ConsumerWidget` — zero business logic, zero direct repository calls
- Notifiers own all logic — API calls, error handling, navigation intent
- Files < 300 lines, functions < 50 lines
- `flutter analyze` must pass zero warnings before every commit
- `dart format lib/ test/` must pass

---

## Anti-Patterns — What NOT To Do

| Anti-Pattern | Why | What To Do Instead |
|---|---|---|
| `Markdown(data: fullText)` during streaming | Full tree rebuild per token → jank | Custom block-segmented renderer |
| `animateTo()` for auto-scroll | Competing animations → stutter | `jumpTo()` via `addPostFrameCallback` |
| `google_generative_ai` SDK | Cannot expose CancelToken | Raw Dio + SSE parsing |
| Inter font on iOS | #1 clone detection tell → immediate fail | `fontFamily: Platform.isIOS ? null : 'Inter'` |
| `StreamProvider` for chat | Cannot cancel + preserve partial | `Notifier` with explicit `StreamSubscription` |
| Dialogs/alerts for API errors | Spec explicitly forbids it | Inline error bubble with retry |
| `Navigator.push` | Forbidden by spec | `context.go()` / `context.push()` |
| `StateNotifier` | Deprecated | `Notifier` / `AsyncNotifier` |
| `@riverpod` codegen | Forbidden by spec | Manual `NotifierProvider<N, S>(N.new)` |
| `@freezed` | Removed from project | Plain immutable class with manual `copyWith` |
| `ElevatedButton` / `TextField` raw | Evaluators grep for these | Wrap in project-level components |
| Empty catch blocks | Forbidden | Always log the error via Talker |
| Snackbars for API errors | Reserved for ephemeral confirms only | Inline error UI on the message |

---

## Pending Decisions

| # | Decision | Options | Status |
|---|---|---|---|
| PD-1 | Hive TypeAdapters vs JSON map storage | TypeAdapters (type-safe, fast) vs raw Map (simple, already done in boilerplate) | Pending — decide when building chat domain |
| PD-2 | flutter_animate vs Rive for specific animations | flutter_animate for most; Rive only if an animation needs a proper timeline (e.g., logo) | Pending — decide at Phase 4 (Splash) |
| PD-3 | custom markdown renderer: line-by-line vs token buffer | Line-by-line is simpler; token buffer handles partial lines | Pending — decide at Phase 1 |

---

*Last updated: Phase 0 (Foundation — partially complete)*
