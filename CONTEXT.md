# CONTEXT.md — Manus AI Clone: Flutter Developer Trial Assignment

> **Purpose:** This file converts all 7 pages of the trial assignment PDF into a complete, structured development reference for Claude. Every screen, interaction, edge case, technical requirement, and design rule is captured here. Use this as the single source of truth when generating code.

---

## 1. PROJECT OVERVIEW

### Mission Statement

Build a **pixel-perfect clone of the Manus AI Agent app** — a chat-first agentic interface — in 5 days. The bar is:

- Animation polish indistinguishable from the original
- Edge-case mastery
- Frontend craftsmanship where a non-technical person cannot tell which app is the clone

### Evaluation Philosophy

- **Polish > coverage**: A perfectly polished UI with basic working chat beats a feature-complete janky app
- Evaluators measure: what you finish well, what you skip, how you communicate trade-offs
- The bar is CRED / Linear / Arc level UI quality
- Ship something that can hold up next to Manus on a real device

### Reference Apps (Source of Truth — NO Figma)

- **iOS:** Manus AI App Store link (install and use daily)
- **Android:** Manus Play Store link (install and use daily)
- The live app IS the design spec. Take screen recordings. Step through animations frame by frame. Measure spacing with screenshots and a ruler tool.

### Backend

- Use **Google Gemini API** (gemini-2.5-flash, free tier)
- Can use your own free key or request one
- Functionality = working text chat with streaming
- 95% of evaluation is **frontend craft**

---

## 2. REQUIRED SCREENS — FULL BREAKDOWN

### 2.1 Splash / Launch Screen

**Purpose:** Animated logo intro matching Manus' launch sequence.

**Requirements:**

- Animate the Manus-style logo intro
- Match gradient and timing exactly
- Match every easing curve from the live app
- No static logo — must be animated sequence

**Key Details:**

- This is the first impression — get the timing perfect
- Reference the live app's launch by recording it and stepping frame by frame

---

### 2.2 Onboarding (3 Slides)

**Purpose:** First-run walkthrough for new users.

**Requirements:**

- 3 slides total
- Page transitions: match exactly from live app
- Animated illustrations on each slide
- Swipeable page indicators (dots or similar)
- "Get Started" CTA button
- Match every easing curve

**Key Details:**

- Illustrations must animate in, not just appear
- The swipe gesture between slides must feel exactly like Manus
- The indicator dots must animate between states with spring physics

---

### 2.3 Auth Screen (Sign In / Sign Up)

**Purpose:** User authentication.

**Requirements:**

- **Email** sign-in/up field
- **Google** sign-in button
- **Apple** sign-in button
- Keyboard avoidance: no overlap, no gap — perfect behavior on all devices
- **Error shake animation**: when login fails, the form shakes
- **Success transition**: smooth animated transition to home after successful auth

**Key Details:**

- Keyboard avoidance is tested on iOS notched devices, Android gesture-nav devices, and Android software nav bar devices
- The shake animation must feel snappy, not linear
- Error states must be inline, not dialog-based

---

### 2.4 Home / New Chat Screen

**Purpose:** Empty state — starting point for a new conversation.

**Requirements:**

- Empty state design with animated suggestion chips
- Prompt example text/UI
- **Model picker pill** — a pill-shaped selector to choose the AI model
- **Attachment tray** — revealed from the input bar
- The suggestion chips animate in with stagger (60 ms between chips, easeOutCubic, slight Y translation)
- Tapping a chip animates it into the input field — do not just dump text, animate it

**Key Details:**

- The home screen's suggestion chips are the most important animation on this screen
- The model picker pill has icon morphs
- This screen transitions into active chat seamlessly

---

### 2.5 Chat Screen (Active Conversation) — THE CENTERPIECE

**Purpose:** The primary interaction surface. This is where most evaluation weight lives.

**Requirements:**

#### Message Bubbles

- User messages: right-aligned bubble
- Assistant messages: left-aligned, no bubble background (or distinct style matching Manus)
- **Bubble entrance:** spring scale + fade; stagger if multiple appear at once
- **Streaming caret/pulse** on the active assistant bubble while streaming

#### Streaming Markdown (Critical — See Difficult Scenarios)

- Render markdown token-by-token without rebuild jank
- Supported: bold, italics, lists, inline code, fenced code blocks, tables, blockquotes, links
- Must NOT reflow the entire bubble on every token
- Must use **block-level segmentation** and **per-block memoization**
- The bubble must grow smoothly, scroll position stays pinned to bottom

#### Code Blocks

- Language label: top-left
- Copy button: top-right with **success state animation** (checkmark morph + subtle haptic + 1.5s revert)
- Horizontal scroll for long lines (no wrapping)
- Syntax-aware monospace font
- Dark background, distinct from bubble
- Must render correctly while surrounding message is still streaming

#### Tool-Call / Reasoning Collapsibles

- Expandable "thinking..." sections inline with messages
- While in-progress: animated indicator
- When complete: collapses to one-line summary the user can re-expand
- Expand/collapse animation: **spring-based, not linear**
- Must NOT shift scroll position unexpectedly

#### Message Actions

- Long-press to start text selection (even on streaming messages)
- Copy any message to clipboard
- Copy must work for selected portion only

#### Inline Images

- Images render inline within the message stream

---

### 2.6 Chat Drawer / History

**Purpose:** Side-drawer showing all past conversations.

**Requirements:**

- Opens from left side (or hamburger) — spring physics matching iOS sheet
- Grouped history sections:
  - Today
  - Yesterday
  - Previous 7 days
  - Older
- **Search bar** with debounce (300 ms)
- **Swipe-to-delete** with undo snackbar
- **Long-press context menu** on a chat row reveals:
  - Rename
  - Pin
  - Archive
  - Delete (with confirmation)
- Infinite scroll support
- Pull-to-refresh: refetches local + remote sync
- Section headers that **stick while scrolling**
- The underlying chat behind the drawer remains **pixel-stable** (no flicker, no rebuild)

**Spring Physics:**

- Drawer open/close must use spring physics matching iOS sheet — damped reveals over snap appearances
- Even on Android, this must feel like iOS sheet physics

**Long-press Context Menu:**

- iOS-style scale + blur background
- The menu must feel like a native context menu, not a bottom sheet

---

### 2.7 Tool / Mode Picker Sheet

**Purpose:** Bottom sheet for picking between modes.

**Requirements:**

- Modes available: Chat / Agent / Browse / Image / etc.
- **Icon morphs** between modes (not crossfade — actual morph)
- **Chip animations** when selecting
- Slides up as a bottom sheet
- The pill/icon in the input bar morphs when mode changes

---

### 2.8 Attachment Tray

**Purpose:** Allows attaching media/files to messages.

**Requirements:**

- Buttons: Camera, Photo library, File picker, Screen capture
- **Animated reveal** from the input bar (not a sudden appearance)
- Selected images show as **thumbnails with remove buttons**
- PDFs/files show with filename + size
- Drag to reorder attachments
- Send button shows **badge count** of attachments
- Tapping paperclip animates open the attachment row above the input

---

### 2.9 Settings Screen

**Requirements:**

- Profile section
- Model selection
- Appearance: Light / Dark / System toggle
- Language setting
- Data controls
- **iOS-style grouped list layout** (even on Android, replicate this layout)

---

### 2.10 Subscription / Paywall Screen

**Requirements:**

- Plans display
- Price toggle: Monthly / Yearly
- Feature comparison table
- Restore purchases button
- **UI only — do NOT wire up real payments**

---

### 2.11 Empty / Error / Offline States

**Requirements:**

- Custom illustrations (not generic Material icons) for:
  - No history
  - No internet / offline
  - Server error
  - Rate limited
  - Generation failed
- Microcopy for each state
- Each state has a distinct illustration

---

## 3. CHAT FUNCTIONALITY — MINIMUM BAR

These are the functional requirements (not just UI):

| Feature                         | Details                                                                                                                                  |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Send prompt → streamed response | Gemini API, streaming via Dio with CancelToken                                                                                           |
| Stop / Cancel stream            | Mid-response cancellation — network request actually cancelled (Dio CancelToken), partial message preserved with "stopped" badge         |
| Regenerate last message         | Re-run the last assistant response                                                                                                       |
| Edit user message               | Edit a previous user message and re-run from that point (fork from edit point)                                                           |
| Copy any message                | Clipboard copy with haptic feedback                                                                                                      |
| Persist conversations           | Hive or Isar — conversations survive app restart                                                                                         |
| Drawer history list             | **Reflects local storage** with grouped sections (Today / Yesterday / Previous 7 / Older) — grouped from local DB, not a remote API call |
| Long-press chat row             | Context menu: Rename, Pin, Archive, Delete (with confirmation)                                                                           |

---

## 4. DIFFICULT SCENARIOS — DETAILED ENGINEERING REQUIREMENTS

These are the hard problems. Every one of these will be tested.

---

### 4.1 Streaming Markdown Without Rebuild Jank

**Problem:** Naive `Markdown(body: fullText)` rebuilds the entire widget tree on every token. On a 200-token stream this causes jank.

**Solution Required:**

- **Block-level segmentation**: parse the markdown into blocks (paragraph, code fence, list, etc.) as tokens arrive
- **Per-block memoization**: each block is a separate widget that only rebuilds when its own content changes
- Completed blocks above the current streaming block must NEVER rebuild
- The bubble must grow smoothly downward
- Scroll position must stay pinned to bottom during growth
- Target: 60 fps on Pixel 4a and iPhone 12 mini throughout streaming

---

### 4.2 Sticky-Bottom Auto-Scroll (Smart Scroll)

**Rules:**

- While stream is active AND user is at bottom → auto-scroll on every new token
- User scrolls up even 1px → auto-scroll RELEASES
- User scrolls back within ~40px of bottom → auto-scroll RE-ENGAGES seamlessly
- **"Jump to latest" pill** appears (fades in) when not at bottom and animates out when re-engaged
- The pill must fade in/out with animation, not snap

---

### 4.3 Code Blocks — Horizontal Scroll, Copy, Language Label

**Requirements:**

- Language label: top-left of code block
- Copy button: top-right
  - On copy success: checkmark morph animation
  - Subtle haptic feedback
  - Reverts after 1.5 seconds
- Horizontal scroll for long lines (no text wrapping inside code block)
- Syntax-aware monospace font
- Dark background visually distinct from message bubble
- Must work correctly while the message around it is still streaming

---

### 4.4 Tool-Call / Reasoning Collapsibles

**Requirements:**

- Inline with message stream (not after)
- While tool-call is in progress: animated loading indicator inside the collapsible
- When complete: auto-collapses to one-line summary
- User can re-expand
- Expand/collapse: **spring-based animation** (not linear, not simple AnimatedSize)
- **Must not shift scroll position** when expanding/collapsing

---

### 4.5 Keyboard, Safe Area, and Input Bar

This is tested on multiple device classes. Requirements:

**(a) Keyboard raises perfectly:**

- No gap between keyboard and input bar
- No overlap of keyboard over input bar
- Tested on:
  - iOS notched devices (iPhone 13/14/15)
  - Android gesture-nav devices (Pixel 7/8)
  - Android software nav bar devices (Pixel 4a, Samsung A series)

**(b) Input bar height:**

- Animates height when user types multiline (max 6 lines, then inside scroll)

**(c) Send button:**

- Enabled/disabled state syncs with input content AND streaming state
- While streaming: button shows stop icon (paper plane → spinner → stop icon → paper plane morph)
- **Send button morph**: paper plane → spinner → stop icon and back — morphed, NOT crossfaded

**(d) Focus:**

- Must NOT lose focus when model picker sheet opens

---

### 4.6 iOS vs Android Font Rendering

| Platform | Body                                              | Headings       | Monospace                     |
| -------- | ------------------------------------------------- | -------------- | ----------------------------- |
| iOS      | SF Pro (CupertinoSystemText / SystemFontOverride) | SF Pro Display | SF Mono                       |
| Android  | Inter                                             | Inter          | JetBrains Mono or Roboto Mono |

> **WARNING:** "Inter on iOS is the most common shortcut and the most obvious tell that an app is a poor clone." Using Inter on iOS = immediate fail.

**Critical:** Headings, monospace, AND **numerics** must all hit the right typeface per platform. Test on a real iPhone. The simulator lies about font metrics.

---

### 4.7 Stream Cancellation That Actually Cancels

When user taps Stop:

- (a) **Network request is cancelled** — Dio CancelToken is actually invoked
- (b) **Partial assistant message is preserved** with a "stopped" badge
- (c) **UI returns to idle state in under 100 ms**
- (d) **No further tokens are appended** after cancellation
- (e) **Stop button morphs back to send** with smooth icon transition

---

### 4.8 App Lifecycle During a Stream

**Scenario:** User backgrounds the app mid-stream.

**Requirements:**

- On iOS: stream may be killed by OS → detect this → show "stream interrupted, tap to retry" inline action
- If user returns within a few seconds AND stream is still alive → resume rendering without duplicating tokens
- Test: airplane-mode toggle, incoming call, **screen lock**

---

### 4.9 Long Conversation Performance

**Target:** 200-message conversation must scroll at 60 fps.

**Requirements:**

- Use `ListView.builder` with stable keys
- Cache rendered markdown for stable messages
- Never rebuild messages above the visible window when a new token arrives at the bottom
- Memory target: < 250 MB RSS after 200-message conversation with 5 images

---

### 4.10 Drawer Animation and Chat History List

**Drawer:**

- Spring physics matching Manus (damped, not snap)
- History list must support:
  - Pull-to-refresh
  - Infinite scroll
  - Search with debounce (300 ms)
  - Swipe-to-delete with undo snackbar
  - Long-press context menu
  - Section headers that stick while scrolling
- Underlying chat stays pixel-stable (no flicker behind drawer)

---

### 4.11 Theme Switching Mid-Conversation

- User can toggle Light / Dark / System mid-chat
- Every widget must transition: message bubble, code block, drawer, animations
- Transition: **200 ms cross-fade** — NO hard cuts
- No flash of unstyled content
- No scroll position loss

---

### 4.12 Haptics (Critical for Android Go-class Devices)

| Action                                        | Haptic               |
| --------------------------------------------- | -------------------- |
| Send message                                  | Light impact         |
| Selection feedback on chip taps               | Selection feedback   |
| Copy success                                  | Success notification |
| Send while empty (tapping send with no input) | **Warning haptic**   |
| System haptics disabled                       | Fall back gracefully |

**iOS:** Must use `UIImpactFeedbackGenerator`-style prepare() pattern — first hap must not be delayed.

**Android:** Fall back gracefully when haptics are disabled system-wide.

---

### 4.13 Image & File Attachment Preview

- Paperclip animates open an attachment row above input
- Selected images: thumbnails with remove buttons
- PDFs/files: filename + size display
- Drag to reorder
- Send button shows badge count

---

### 4.14 Network Reconnection and Retry

- If request fails mid-stream due to network drop:
  - Show inline "Network lost — Retry" on the partial message
  - Retry resumes cleanly
  - **Never auto-retry POST requests** — user must explicitly retry
- Show thin connectivity indicator at top when offline

---

### 4.15 Selection and Copy Across Streaming Text

- User can long-press to start text selection on a message that is STILL streaming
- Selection must not be lost when new tokens arrive
- Copy works for selected portion only
- Note: Flutter's default `SelectableText` fights rebuilds — custom implementation likely needed

---

### 4.16 Suggestion Chips on Empty State

- 3–4 chips, stagger animate in (60 ms between chips, easeOutCubic, slight Y translation)
- Tapping a chip: **animates it into the input field** — the chip flies/morphs into the input — do not just paste text

> **Evaluator Weight Signal:** _"This single animation says more about you than any test suite."_ — The chip-tap-to-input animation is weighted extremely heavily. It is the single most revealing animation in the assignment.

---

### 4.17 Pull-to-Refresh That Doesn't Break Streaming

- In drawer history list: pull-to-refresh refetches local + remote
- In chat itself: pull-to-refresh is **disabled** (users would break their own streams)
- On iOS: elastic overscroll must still work — just don't trigger refresh in chat

---

### 4.18 Error States Inline, Not in Dialogs

- API error → inline small bubble with error message + retry button
- Rate limit → inline
- Network error → inline
- Policy violation → inline
- **No alerts, no stacking snackbars**
- Snackbars are reserved for ephemeral confirmations only (e.g., swipe-to-delete undo)

---

### 4.19 Accessibility (Non-Negotiable)

- Every interactive element has a `Semantics` label
- Chat list announces new messages to TalkBack / VoiceOver
- Font scaling up to 200% must not break any layout
- Tap targets minimum 48×48 dp
- Color contrast passes WCAG AA on both themes

---

## 5. DESIGN GUIDELINES

### 5.1 Source of Truth

There is NO Figma file. The Manus app on the App Store and Play Store IS the source of truth. Install it, run it on the same device class, reference it constantly. Take screen recordings. Step through animations frame by frame. Measure spacing with screenshots and a ruler tool.

---

### 5.2 Typography

| Platform | Body                                              | Headings       | Monospace                     |
| -------- | ------------------------------------------------- | -------------- | ----------------------------- |
| iOS      | SF Pro (CupertinoSystemText / SystemFontOverride) | SF Pro Display | SF Mono                       |
| Android  | Inter                                             | Inter          | JetBrains Mono or Roboto Mono |

> **Critical:** Inter on iOS = immediate rejection. Test on real iPhone.

---

### 5.3 Color & Theme

- Both **light and dark themes** — match Manus exactly for both
- Theme follows **system** by default
- User can override in settings
- Mid-app theme switch must **cross-fade in 200 ms** — never hard cut

---

### 5.4 Iconography

- Match every icon glyph and stroke weight exactly
- If Manus uses a custom icon, recreate it as SVG — do NOT approximate with Material Icons
- Icon transitions on state change (mode picker, send/stop, copy/copied) must **morph**, not crossfade

---

### 5.5 Responsiveness

| Device Class     | Must Look Correct On                                             |
| ---------------- | ---------------------------------------------------------------- |
| Small Android    | Pixel 4a / 5a, Samsung A series — 360 dp width, software nav bar |
| Standard Android | Pixel 7 / 8, Samsung S23 — 412 dp width, gesture nav             |
| Large Android    | Pixel 8 Pro / Fold outer screen — 412 dp tall                    |
| Standard iPhone  | iPhone 13 / 14 / 15 — 390 dp width, notch / Dynamic Island       |
| Large iPhone     | iPhone 15 Pro Max — 430 dp width                                 |
| Small iPhone     | iPhone 13 mini / SE — 375 dp / 320 dp — **DO NOT skip this**     |

---

## 6. ANIMATION REQUIREMENTS

### Philosophy

Animation separates a good Flutter app from a Manus-class one. We are looking for CRED-level / Linear-level / Arc-level polish. Every transition must feel intentional.

- **Spring physics over linear curves**
- **Damped reveals** over snap appearances
- **Small overshoots** where playful
- **easeOutCubic** where utilitarian
- If an animation feels generic, it is wrong

---

### Required Animations (Non-Exhaustive)

| Animation                 | Spec                                                                                              |
| ------------------------- | ------------------------------------------------------------------------------------------------- |
| Bubble entrance           | Spring scale + fade; stagger if multiple appear at once                                           |
| Streaming caret           | Pulse on active assistant bubble while streaming                                                  |
| Send button morph         | Paper plane → spinner → stop icon → paper plane; all morphed, never crossfaded                    |
| Drawer open/close         | Spring physics matching iOS sheet; damped reveals over snap; works on Android too                 |
| Mode picker icon morph    | Input pill icon morphs on mode change — not a crossfade                                           |
| Suggestion chips stagger  | 60 ms between chips, easeOutCubic, Y translation; **animate INTO input field on tap** (not paste) |
| Code-block copy success   | Checkmark morph + subtle haptic + 1.5 s revert                                                    |
| Tool-call expand/collapse | Size + opacity spring; never hard reveal; must not shift scroll                                   |
| Long-press context menu   | **iOS-style scale + blur background, even on Android**                                            |
| Theme switch              | **200 ms cross-fade across ALL themed widgets** — never hard cut                                  |
| Page transitions          | **Cupertino on iOS, custom shared-axis on Android**                                               |
| Pull-to-refresh indicator | **Custom indicator matching app personality — NOT the default spinner**                           |
| "Jump to latest" pill     | Fade in/out with animation — never snaps                                                          |
| Error shake               | Auth form shakes on login failure — snappy, not linear                                            |
| Attachment tray reveal    | Animated reveal upward from input bar — not sudden appearance                                     |
| Onboarding illustrations  | Animate in per slide — not static appear                                                          |
| Onboarding page indicator | Dots animate between states with spring physics                                                   |
| Success transition        | Smooth animated transition from auth to home                                                      |

---

## 7. PERFORMANCE TARGETS

| Metric                     | Target                                                    | How Measured                                               |
| -------------------------- | --------------------------------------------------------- | ---------------------------------------------------------- |
| Frame rate (steady)        | 60 fps minimum                                            | Flutter DevTools Performance overlay during 200-msg stream |
| Frame rate (worst case)    | No frames > 16 ms — 99% of the time                       | Performance overlay + raster timeline                      |
| Cold start (release build) | < 2.5 s on Pixel 6, < 2.0 s on iPhone 13                  | Stopwatch from icon tap to interactive home                |
| Time to first token        | < 800 ms after send tap                                   | In-app logged metric                                       |
| Scroll jank                | Zero dropped frames scrolling 200-message conversation    | DevTools                                                   |
| Memory                     | < 250 MB RSS after 200-message conversation with 5 images | Xcode Instruments / Android Studio Profiler                |
| APK size                   | < 35 MB universal release APK                             | `flutter build apk --release`                              |

---

## 8. TECHNICAL REQUIREMENTS

### 8.1 Required Stack

| Category         | Required                                         | Notes                                                        |
| ---------------- | ------------------------------------------------ | ------------------------------------------------------------ |
| Flutter          | 3.35+                                            | Latest stable. Dart 3.4+                                     |
| State management | flutter_riverpod (Notifier / AsyncNotifier API)  | No StateNotifier in new code. No riverpod_generator codegen. |
| Routing          | go_router                                        | Typed routes. No Navigator.push.                             |
| Networking       | dio with CancelToken                             | For Gemini streaming. Cancellation must work.                |
| Local storage    | hive OR isar                                     | Your choice. Conversations persist across restarts.          |
| Image caching    | cached_network_image with cacheWidth/cacheHeight | Always pass cache dims to network images.                    |
| Markdown         | flutter_markdown OR markdown + custom renderer   | Custom renderer strongly preferred for streaming perf.       |
| Animations       | flutter_animate / rive / custom                  | Use what fits each animation. Document choices.              |
| LLM API          | Google Gemini (free tier — gemini-2.5-flash)     | Use your own free key or request one.                        |

---

### 8.2 Forbidden

- ❌ No `riverpod_generator` / `@riverpod` codegen
- ❌ No `StateNotifier` in new code (use `Notifier` / `AsyncNotifier`)
- ❌ No `Navigator.push` — use `go_router`
- ❌ No `print()` / `debugPrint()` — use a logger
- ❌ No raw Material widgets where a "Common" / project widget is more appropriate — **Evaluators will actively grep your codebase for `ElevatedButton`, `AlertDialog`, `TextField`** — wrap all of these in project-level components
- ❌ No empty catch blocks — every catch must log

---

### 8.3 Code Quality Non-Negotiables

- `flutter analyze` must pass with zero warnings
- `dart format --set-exit-if-changed` must pass (pre-commit); full form: `dart format --set-exit-if-changed lib/ test/`
- Files under 300 lines
- Functions under 50 lines
- Clean architecture: presentation → data → core. Never import upward.
- Every Riverpod provider explicitly typed and manually defined

---

## 9. SUBMISSION REQUIREMENTS

### Deliverables

| Deliverable                           | Required |
| ------------------------------------- | -------- |
| GitHub repo (private, access granted) | ✅ Yes   |
| Release-signed Android APK            | ✅ Yes   |
| iOS build via TestFlight or .ipa      | Bonus    |
| Demo video (5–7 minutes)              | ✅ Yes   |

---

### Demo Video Must Cover

1. Splash and onboarding animations
2. Sign-in flow with error state
3. New chat empty state with suggestion chip stagger
4. Send a prompt and stream a markdown-heavy response (force a code block + a table)
5. Stop a stream mid-response and inspect the partial preserved message
6. Open the drawer and demonstrate grouped history, search, swipe-to-delete, long-press menu
7. Switch theme mid-conversation — show smooth cross-fade
8. Background the app mid-stream, return — show recovery behavior
9. Trigger a network error inline, retry
10. Mode picker icon morph
11. Long-press copy on a streaming message
12. Side-by-side with Manus app for at least 30 seconds

---

## 10. PRE-SUBMISSION CHECKLIST

- [ ] Builds without errors on a clean clone (`flutter pub get` + `flutter run`)
- [ ] `flutter analyze` passes with zero warnings
- [ ] `dart format --set-exit-if-changed lib/ test/` passes
- [ ] Tested on a real Android device (preferably small / mid-range)
- [ ] Cold start under 2.5 s on Pixel 6 / iPhone 13
- [ ] 60 fps on a 200-message scripted conversation
- [ ] Stream stop / cancel works without leftover state
- [ ] Background-foreground during stream handled
- [ ] Theme switch cross-fades, no flash
- [ ] Drawer open animation matches reference recording
- [ ] Code block copy works mid-stream
- [ ] iOS body font is SF Pro, not Inter
- [ ] No hardcoded API keys committed
- [ ] README + design audit docs + demo video + side-by-side recording all attached

---

## 11. USER FLOWS

### 11.1 First Launch Flow

```
App launch
  → Splash Screen (animated logo, gradient, spring timing)
  → Onboarding Slide 1 (animated illustration, page indicator)
  → Onboarding Slide 2 (swipe or CTA)
  → Onboarding Slide 3
  → "Get Started" CTA
  → Auth Screen
  → Home / New Chat
```

### 11.2 Auth Flow

```
Auth Screen
  → Enter email / tap Google / tap Apple
  → [Error] → Shake animation → inline error message → retry
  → [Success] → success transition animation → Home
```

### 11.3 New Chat Flow

```
Home / New Chat (empty state)
  → Suggestion chips stagger in (60ms, easeOutCubic, Y translate)
  → User taps chip → chip animates into input field
  → OR user types in input bar → send button enables
  → Tap send → paper plane → spinner morph
  → First token arrives → assistant bubble springs in
  → Stream active → auto-scroll pinned to bottom
  → Stream completes → send button morphs back to paper plane
```

### 11.4 Stop Stream Flow

```
Stream active
  → User taps Stop (stop icon in send button position)
  → Dio CancelToken.cancel() called
  → Partial message preserved with "stopped" badge
  → UI returns to idle in < 100 ms
  → No further tokens appended
  → Send button morphs back to paper plane
```

### 11.5 Edit Message Flow

```
Active conversation
  → User taps/long-presses a previous user message
  → Message enters edit mode
  → User edits text
  → Tap send → re-run from that point (fork)
  → Messages after the edited message are replaced
```

### 11.6 Drawer Flow

```
Home / Chat → tap hamburger or swipe from left edge
  → Drawer slides in with spring physics (damped)
  → Grouped history: Today / Yesterday / Previous 7 / Older
  → Sticky section headers
  → Search bar (debounce 300ms)
  → Swipe chat row left → delete with undo snackbar
  → Long-press chat row → context menu (Rename, Pin, Archive, Delete)
  → Tap chat → drawer closes (spring) → chat loads
```

### 11.7 Theme Switch Flow

```
Any screen → Settings → Appearance
  → Toggle Light / Dark / System
  → 200ms cross-fade across ALL widgets
  → No flash, no scroll position loss
```

### 11.8 Network Error / Retry Flow

```
Stream active
  → Network drops
  → Inline error bubble appears on partial message: "Network lost — Retry"
  → Thin connectivity indicator appears at top
  → User taps Retry
  → Stream resumes from where it left off (cleanly)
  → Never auto-retry
```

### 11.9 Attachment Flow

```
Input bar → tap paperclip
  → Attachment row animates open above input bar
  → Options: Camera / Photo library / File picker / Screen capture
  → Select image → thumbnail with remove button appears
  → Select file → filename + size appears
  → Drag thumbnails to reorder
  → Send button shows badge count
  → Tap send → attachments included in message
```

---

## 12. EDGE CASES & IMPORTANT NOTES

### Streaming

- If app is backgrounded mid-stream on iOS, the stream may be OS-killed → detect and show "stream interrupted, tap to retry"
- If user returns quickly and stream is still alive → resume without duplicating tokens
- Cancellation must be verified — Dio CancelToken must actually cancel the HTTP request

### Markdown

- The hardest engineering problem in the assignment
- Block-level segmentation is mandatory — per-block memoization is mandatory
- Tables, code blocks, and lists must all stream correctly without jank

### Scroll

- The "sticky-bottom auto-scroll with release" behavior is explicitly tested
- The "Jump to latest" pill fade-in/fade-out is explicitly tested

### Fonts

- The single most common clone failure is Inter on iOS
- Must use CupertinoSystemText or SystemFontOverride for SF Pro on iOS
- Test on real iPhone — simulator lies

### Selection During Streaming

- Genuinely hard — Flutter's SelectableText fights rebuilds
- Must not lose selection when new tokens arrive
- Long-press must work on a currently-streaming message

### Pull-to-Refresh

- In drawer: enabled
- In chat view: DISABLED (prevents breaking active streams)
- iOS elastic overscroll: still works in chat, just doesn't trigger refresh

### Error States

- Never use dialogs or alerts for API/network errors
- Always inline, always with retry
- Snackbars only for ephemeral confirms (undo delete)

### Accessibility

- All interactive elements must have Semantics labels
- 200% font scale must not break layout
- 48×48 dp minimum tap targets

### Haptics

- Prepare haptics before they're needed (iOS pattern)
- First haptic must not be delayed
- Graceful degradation when haptics disabled on Android

### Keyboard

- Test on 3 device types: iOS notched, Android gesture-nav, Android software nav bar
- No gap, no overlap between keyboard and input bar

### Conversation Persistence

- Conversations must survive app restart
- Use Hive or Isar — your choice
- Drawer must reflect persisted conversations on relaunch

---

## 13. ASSUMPTIONS & NOTES FOR DEVELOPMENT

1. **No real payment integration** — Paywall/Subscription screen is UI-only
2. **No real OAuth** — Auth screen buttons can be wired to a mock auth flow or Gemini API key flow; Google/Apple sign-in buttons must exist visually
3. **Gemini API key** — can be hardcoded in a `.env` or `--dart-define`; never commit to git
4. **Custom markdown renderer** is strongly preferred over `flutter_markdown` for streaming performance
5. **Rive vs flutter_animate** — use whatever fits the animation; document your choice
6. **No riverpod_generator** — all providers are manually defined with explicit types
7. **go_router** — typed routes, no Navigator.push anywhere
8. **Logger** — use a logging package (e.g., `logger`), never `print()`/`debugPrint()`
9. **The side-by-side video** is a key deliverable — budget time for it
10. **Source of truth is the live app** — if anything in this doc conflicts with the live Manus app, the live app wins

---

## 14. EVALUATOR'S CLOSING STATEMENT (Verbatim Weight Signal)

> _"We know this is a lot for five days. We are measuring what you finish well, what you choose to skip, how honestly you communicate trade-offs, and whether the parts you do ship feel like they belong in a shipping app on a real user's phone. Build something that makes us say 'wow.' Good luck."_

**What this means for development priorities:**

- Communicate trade-offs honestly in your README — if you skipped something, say why
- Partial but polished > complete but janky
- Every screen you ship must feel production-ready, not prototype-quality
- The side-by-side 30-second video comparison is the ultimate test

---

_End of CONTEXT.md_
