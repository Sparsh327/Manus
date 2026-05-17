# Manus — Flutter Trial Assignment

A pixel-faithful Flutter clone of the [Manus AI](https://manus.im) mobile app, built as a trial assignment. Implements the full chat UI with live Gemini streaming, clean architecture, and Riverpod state management.

---

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.38.0 (stable) |
| Dart | 3.10.0 |
| Xcode | 15+ (iOS) |
| Android Studio / SDK | API 23+ (Android) |

Verify your setup:

```bash
flutter doctor
```

---

## 1 · Clone & install dependencies

```bash
git clone <repo-url>
cd manus
flutter pub get
```

---

## 2 · Set up the API key

The app calls the **Gemini API** for AI responses. The key is never hardcoded — it is injected at build time via `--dart-define-from-file`.

Create a `.env` file in the project root (it is gitignored):

```
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
```

> Get a free key at [aistudio.google.com/apikey](https://aistudio.google.com/apikey).

**Important:** every `flutter run` / `flutter build` command must include `--dart-define-from-file=.env`. Without it the app will throw at runtime when the first message is sent.

---

## 3 · Run the app

### Any connected device / simulator

```bash
flutter run --dart-define-from-file=.env
```

### Specific platform

```bash
# iOS simulator or device
flutter run -d ios --dart-define-from-file=.env

# Android emulator or device
flutter run -d android --dart-define-from-file=.env
```

### List available devices first

```bash
flutter devices
flutter run -d <device-id> --dart-define-from-file=.env
```

### Release mode (no debug banner, AOT compiled)

```bash
flutter run --release --dart-define-from-file=.env
```

---

## 4 · Hot reload & hot restart

Once the app is running, inside the terminal:

| Key | Action |
|-----|--------|
| `r` | Hot reload (preserves state) |
| `R` | Hot restart (resets state) |
| `q` | Quit |

---

## 5 · Build an installable binary

```bash
# iOS .ipa (requires signing)
flutter build ios --dart-define-from-file=.env

# Android APK
flutter build apk --dart-define-from-file=.env

# Android App Bundle
flutter build appbundle --dart-define-from-file=.env
```

---

## 6 · Run tests

```bash
flutter test
```

---

## Project structure

```
lib/
├── core/              # DI, providers, base classes
├── data/
│   ├── data_sources/
│   │   ├── local/     # Hive persistence
│   │   └── remote/    # Gemini streaming service
│   └── repositories/
├── domain/
│   ├── entities/      # ChatMessage, Conversation …
│   └── repositories/  # Abstract contracts
├── presentation/
│   ├── auth/          # Login, email login screens
│   ├── chat/          # Chat screen + streaming markdown
│   ├── conversations/ # Conversations list
│   ├── profile/       # Profile + theme switcher
│   ├── splash/        # Splash screen
│   ├── subscription/  # Subscription screen
│   └── theme/         # ThemeNotifier (light/dark/system)
├── router/            # GoRouter configuration
└── theme/             # AppTheme, AppColors, AppFonts
```

---

## Architecture

- **Pattern**: Clean Architecture — Domain → Data → Presentation
- **State management**: `flutter_riverpod` (`Notifier` / `FamilyNotifier`, no codegen)
- **Navigation**: `go_router`
- **Local storage**: Hive (JSON maps, no TypeAdapters)
- **AI backend**: Gemini 2.0 Flash via streaming REST (`dio`)
- **Typography**: SF Pro on iOS (system font), Inter on Android

---

## Key design decisions

| Decision | Reason |
|----------|--------|
| `String.fromEnvironment('GEMINI_API_KEY')` | Key never touches source control |
| `ref.watch(...).select(...)` with Dart 3 records | Prevents full `ChatScreen` rebuild on every streaming token |
| `_CachedBlockWidget` (StatefulWidget, builds once) | Completed markdown blocks are never re-rendered |
| `_StreamingBubbleEntry` StatefulWidget wrapping `AnimationController` | Prevents `flutter_animate` entrance animation from restarting on every token |
| `_cachedWidgets.length` as loop start index | Prevents duplicate `ValueKey` crash when parser block count fluctuates |

---

## Screens implemented

- Splash
- Login (Facebook / Google / Microsoft / Apple / Email)
- Email login
- Conversations list
- Chat (streaming markdown, thinking indicator, attachment tray, mode picker)
- Profile (account, appearance / theme switcher, settings)
- Subscription

---

## Notes for reviewers

- The `.env` file is **gitignored** — you must create it yourself (step 2 above).
- The app defaults to `ThemeMode.system`. Toggle light/dark from **Profile → Appearance**.
- Attachment tray and mode picker are UI-only mocks (no file upload backend).
- Firebase is a declared dependency but not initialised — push notifications are stubbed.
