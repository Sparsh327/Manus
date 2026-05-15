# AI Agent Instructions: prod_ready_boilerplate

This is a production-ready Flutter boilerplate project using Clean Architecture. The codebase emphasizes clean separation of concerns, explicit error handling, and maintainable patterns.

## Project Overview

- _Type_: Flutter mobile app (iOS/Android)
- _Language_: Dart 3.9.2+
- _Package Manager_: Pub (pubspec.yaml)
- _Architecture_: Practical Hybrid Clean Architecture (Domain → Data → Presentation)
  - Features use Notifier → Repository pattern for speed
  - UseCase layer optional; skip for faster delivery
  - Presentation screens are 100% reactive; no direct business logic
- _State Management_: **flutter_riverpod** (Notifier / AsyncNotifier API only)
- _Dependency Injection_: **Riverpod Providers** (no GetIt)
- _Navigation_: GoRouter
- _Error Handling_: Either<Failure, Output> (dartz package)
- _Local Storage_: Hive
- _HTTP Client_: Dio
- _Analytics/Logging_: Talker + Firebase

## Build and Run

bash

# Install dependencies

flutter pub get

# Run on device

flutter run

# Debug with verbose output

flutter run -v

# Run with specific flavor/variant (if configured)

flutter run --release

# Analyze code

flutter analyze

# Format code

dart format lib/

## Codebase Structure

lib/
├── main.dart # App entry point, ProviderScope root
├── core/ # Shared utilities & cross-cutting concerns
│ ├── providers/ # Core infrastructure providers (Dio, Connectivity, ApiClient, NetworkInfo)
│ ├── error/ # Failure classes (failure.dart, exception.dart)
│ ├── usecase/ # Abstract UseCase<Output, Params> base class
│ ├── network/ # Network info, connectivity checks
│ ├── presentation/ # Shared UI state (screen_state.dart with ScreenStatus enum)
│ └── component/ # Reusable UI components (error_state_widget.dart, common_screen.dart)
├── domain/ # Business logic layer (pure Dart, no frameworks)
│ ├── entities/ # Core data models (Product.dart)
│ ├── repositories/ # Abstract repository interfaces
│ └── usecases/ # Business logic (GetProducts, etc.)
├── data/ # Data access layer
│ ├── data_sources/ # Concrete data fetching (remote API, local Hive)
│ │ ├── remote/ # HTTP clients (ApiClient, RemoteDataSources)
│ │ └── local/ # Hive service, local data sources
│ ├── model/ # Data models extending domain entities (ProductModel.dart)
│ ├── providers/ # Riverpod providers for data sources & repositories
│ └── repositories/ # Repository implementations
├── presentation/ # UI layer
│ ├── home/ # Feature-based folders
│ │ ├── notifier/ # ProductNotifier + ProductState + productProvider
│ │ └── home_screen.dart # ConsumerWidget screen
│ └── ...other features # Follow same pattern
├── router/ # GoRouter configuration
├── theme/ # Design tokens (colors, fonts, dimensions, text styles)
├── utility/ # Helper functions (extensions.dart, UI helpers)
└── values/ # Constants (assets, strings, dimensions)

## Architecture Patterns & Conventions

### 1. Clean Architecture Layers

_Domain Layer_ (Business Logic)

- Pure Dart, no framework dependencies
- Defines interfaces and entities
- Repository interfaces only (UseCases optional)

_Data Layer_ (Data Access)

- Implements repository interfaces
- Manages data sources (local Hive, remote API)
- Converts models ↔️ entities
- Handles network state and caching
- Exposes Riverpod `Provider<Repository>` for each feature

_Presentation Layer_ (UI)

- **Notifiers only**: Handle all business logic/API calls
- **Screens are ConsumerWidget**: React to provider state changes via `ref.watch`
- **No direct repository calls** in UI screens — always go through the Notifier
- **No provider definitions in screens**: All providers live in `notifier/` or `data/providers/`

### 2. State Management Pattern

Use **Notifier** for state that involves direct method calls and simple state transitions (loading data, form submissions). Use **AsyncNotifier** when the initial data load is async and you want Riverpod to manage the loading/error lifecycle automatically.

**Never use StateNotifier** — it is deprecated. Never use `riverpod_generator` / `@riverpod` codegen.

All screens use plain immutable `ScreenState<T>` with `ScreenStatus` enum:
dart
class ScreenState<T> {
final ScreenStatus status; // initial, loading, loaded, error
final T? data; // Typed payload
final String? error; // Error message
final bool isLoadingMore; // Pagination support
}

_Provider and Notifier definition (same file):_
dart
final productProvider = NotifierProvider<ProductNotifier, ProductState>(
  ProductNotifier.new,
);

class ProductNotifier extends Notifier<ProductState> {
  @override
  ProductState build() {
    Future.microtask(loadProducts); // auto-load on first watch
    return const ProductState();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(screenState: ScreenState.loading());
    final result = await ref.read(productRepositoryProvider).getProducts();
    result.fold(
      (failure) => state = state.copyWith(screenState: ScreenState.error(failure.message)),
      (data) => state = state.copyWith(screenState: ScreenState.loaded(data)),
    );
  }
}

_Screen watches and reads the provider:_
dart
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider);
    // react to state.screenState.status
  }
}

_For side effects (navigation, snackbars), use ref.listen:_
dart
ref.listen<ProductState>(productProvider, (previous, next) {
  if (next.action == ProductAction.navigateToDetail) {
    context.go(AppRoutes.detail);
  }
});

### 3. Error Handling

All repository calls return Either<Failure, Output>:

- _Left (Failure)_: ServerFailure, CacheFailure, ConnectionFailure
- _Right (Output)_: Success result

_Error handling happens in Notifier_ (not screens):
dart
result.fold(
  (failure) => state = state.copyWith(screenState: ScreenState.error(failure.message)),
  (data) => state = state.copyWith(screenState: ScreenState.loaded(data)),
);

_Screens react to error status and show inline messages_, no error handling logic.

### 4. Dependency Injection

Use **Riverpod Providers** for all dependency injection — no GetIt.

dart
// core/providers/core_providers.dart
final dioProvider = Provider<Dio>((ref) => Dio());
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(dio: ref.watch(dioProvider)));
final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfoImpl(ref.watch(connectivityProvider)));

// data/providers/product_data_providers.dart
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    localDataSource: ref.watch(productLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  ),
);

Rules:
- Infrastructure providers (`Dio`, `Connectivity`, `ApiClient`, `NetworkInfo`) → `core/providers/core_providers.dart`
- Feature data providers (data sources, repository) → `data/providers/<feature>_data_providers.dart`
- Feature notifier + notifier provider → `presentation/<feature>/notifier/<feature>_notifier.dart`
- State class → `presentation/<feature>/notifier/<feature>_state.dart`

### 5. No Code Generation

There is **no code generation** in this project:

- ❌ No `freezed` / `@freezed` — write plain immutable classes with manual `copyWith`
- ❌ No `build_runner`
- ❌ No `riverpod_generator` / `@riverpod`

State classes are plain Dart:
dart
class ProductState {
  final ScreenState<List<Product>> screenState;

  const ProductState({
    this.screenState = const ScreenState(status: ScreenStatus.initial),
  });

  ProductState copyWith({ScreenState<List<Product>>? screenState}) {
    return ProductState(screenState: screenState ?? this.screenState);
  }
}

## Key Dependencies & Features

| Dependency         | Purpose                | Key Classes                         |
| ------------------ | ---------------------- | ----------------------------------- |
| flutter_riverpod   | State management + DI  | Notifier, AsyncNotifier, Provider   |
| go_router          | Navigation             | GoRoute, GoRouter                   |
| dio                | HTTP client            | Dio, CancelToken                    |
| hive               | Local DB               | HiveBox, HiveService                |
| dartz              | Functional programming | Either<L, R>                        |
| equatable          | Value comparison       | Equatable mixin                     |
| firebase_core      | Firebase setup         | FirebaseOptions                     |
| firebase_messaging | Push notifications     | FCM                                 |
| flutter_screenutil | Responsive design      | ScreenUtil, responsiveSizing        |
| connectivity_plus  | Network detection      | Connectivity.checkConnectivity      |

## Common Tasks

### Adding a New Feature (Fast Path — Current Standard)

1. _Create domain layer_:
   - Add entity in `domain/entities/`
   - Add repository interface in `domain/repositories/`

2. _Create data layer_:
   - Add model in `data/model/` (extends entity, has `fromJson`/`toJson`)
   - Add data sources in `data/data_sources/` (remote + local)
   - Implement repository in `data/repositories/`
   - Add Riverpod providers in `data/providers/<feature>_data_providers.dart`

3. _Create presentation layer_:
   - Create `presentation/<feature>/notifier/<feature>_state.dart` (plain immutable class)
   - Create `presentation/<feature>/notifier/<feature>_notifier.dart` (Notifier + NotifierProvider)
   - Create `presentation/<feature>/<feature>_screen.dart` (ConsumerWidget — zero business logic)

4. _Wire up_:
   - Add route in `router/app_router.dart` and constant in `router/app_routes.dart`
   - No `main.dart` changes needed — Riverpod providers are lazy by default

### Adding a New Route

In `router/app_router.dart`:
dart
GoRoute(
  path: AppRoutes.myRoute,
  builder: (context, state) => const MyScreen(),
),

In `router/app_routes.dart`, add route constant.

### Local Caching with Hive

- Initialize boxes in `main.dart` before `runApp`
- Create a feature-scoped `Provider<HiveService>` in the feature's data providers file
- Access via `ref.watch(featureHiveServiceProvider)` inside data source providers

### Error Messages

- Keep error messages in `lib/values/app_strings.dart`
- Map failure types to user-friendly messages in the Notifier
- Never expose raw exceptions to UI

## Code Style & Linting

- _Linter_: flutter_lints (enabled in analysis_options.yaml)
- _Format_: Run `dart format lib/` before committing
- _Import Style_: Always use `package:` imports
- _Naming_: camelCase for variables/methods, PascalCase for classes
- _Constants_: Define in `lib/values/` (colors, strings, dimensions)
- _Unused params_: Use Dart 3 wildcard `_` for all ignored callback params (e.g., `(_, _) =>`)

## Testing

- Create tests in `test/` matching `lib/` structure
- Test domain layer extensively (pure Dart, fastest)
- Mock data sources in repository tests
- Use `flutter test` to run

## Important Notes

1. _Presentation screens must be ConsumerWidget_: Use `ref.watch` for state, `ref.read` for actions
2. _Notifiers contain all business logic_: API calls, error handling, navigation intent (via action field in state)
3. _No provider definitions in screens_: All providers are in `notifier/` or `data/providers/`
4. _Never call repository directly from UI_: All repository calls go through Notifier
5. _Side effects via ref.listen_: Navigation, snackbars, dialogs only inside `ref.listen` callbacks
6. _State updates_: Always via `state = state.copyWith(...)` — never mutate state
7. _Error handling in Notifier_: Map failures to user-friendly messages before updating state
8. _Responsive sizing_: Use flutter_screenutil for all dimensions (`.h`, `.w`, `.sp`, `.r`)
9. _Pagination_: Use `isLoadingMore` flag in `ScreenState` to prevent duplicate requests
10. _No StateNotifier_: Use `Notifier` or `AsyncNotifier` only
11. _No codegen_: No `@freezed`, no `@riverpod`, no `build_runner`
12. _No print/debugPrint_: Use a logger package (Talker or similar)

## Forbidden Patterns

- ❌ `StateNotifier` — deprecated, use `Notifier` / `AsyncNotifier`
- ❌ `riverpod_generator` / `@riverpod` codegen
- ❌ `Navigator.push` — use `go_router` (`context.go`, `context.push`)
- ❌ `print()` / `debugPrint()` — use Talker or a logger package
- ❌ Raw `ElevatedButton`, `AlertDialog`, `TextField` — wrap in project-level components
- ❌ Empty catch blocks — every catch must log the error
- ❌ `@freezed` / `freezed_annotation` / `build_runner` — write plain immutable classes
- ❌ `GetIt` — use Riverpod providers for all dependency injection

## Resources

- [Flutter Docs](https://docs.flutter.dev)
- [GoRouter](https://pub.dev/packages/go_router)
- [Riverpod](https://riverpod.dev)
- [Clean Architecture Guide](https://resocoder.com/flutter-clean-architecture-tdd)
