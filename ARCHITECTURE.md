# Baytari (بيطري) — Architecture

**Status:** current architecture, as built. Last updated 2026-11-13
(added: centralized `ApiService` interceptors + `core/dialogs/`).

This document is the single source of truth for how the app is
structured. Any code that contradicts it should be fixed, not the
other way around — unless the user explicitly approves a change.

## 1. Overview

| Area | Choice |
|---|---|
| Framework / language | Flutter 3.47.9 / Dart 3.13.7 |
| Architecture | Clean Architecture, feature-first |
| State management | Cubit (`flutter_bloc`) — one Cubit per feature |
| Dependency injection | GetIt (`get_it`), in dependency order |
| Networking | Dio (`dio`) — central `ApiClient` in `core/network` |
| Backend | Supabase (Auth, Postgres, Storage) via `supabase_flutter`, data layer only |
| Local storage | `shared_preferences` for theme + language + onboarding flag |
| Localization | ARB files, `flutter_localizations` + `intl`, generated `AppLocalizations`. Arabic (ar) + English (en), Arabic default, RTL/LTR automatic, runtime switch, persisted |
| Theming | Material 3, Light + Dark, centralized `AppColors` / `AppTextStyles` / `AppTheme` |
| Routing | `go_router` in `core/routing` |
| Error handling | `Result<T>` sealed class in `core/errors/result.dart` (no dartz) |
| State equality | `equatable` for Cubit states (no Freezed in v1) |

## 2. Folder structure

```text
lib/
├── app/                  # Root widget (BaytariApp), AppCubit, AppState
├── core/                 # Infrastructure, independent of features
│   ├── constants/        # AppConstants, ApiConstants, SupabaseConstants
│   ├── dialogs/          # Toast + dialogs (app_toast.dart, app_dialogs.dart)
│   ├── di/               # GetIt setup (register_core.dart)
│   ├── errors/           # AppException, Failure, Result<T>
│   ├── extensions/       # context.l10n / colors / textTheme / isDark
│   ├── localization/     # ARB files (l10n/) + generated AppLocalizations
│   ├── network/          # ApiClient (central Dio), ApiInterceptors
│   ├── routing/          # GoRouter configuration (app_router.dart)
│   ├── services/         # AppSettingsService, SupabaseService
│   ├── theme/            # AppColors, AppTextStyles, AppTheme
│   ├── utils/            # Validators, date/time helpers
│   └── widgets/          # Reusable UI (buttons, states, logo)
├── features/<feature>/   # auth, onboarding, pets, vets, ...
│   ├── data/
│   │   ├── datasources/  # Supabase / API data sources
│   │   ├── models/       # Manual fromJson / toJson (no codegen)
│   │   └── repositories/ # Repository implementations
│   ├── domain/
│   │   ├── entities/     # Plain Dart classes, no Flutter imports
│   │   ├── repositories/ # Repository contracts (abstract)
│   │   └── usecases/     # One class per operation
│   ├── presentation/
│   │   ├── cubit/        # Cubit + states (Loading / Success / Failure)
│   │   ├── screens/      # Screens (Scaffold + BlocProvider/Consumer)
│   │   └── widgets/      # Screen-specific widgets
│   └── di/               # register_<feature>.dart
├── injection_container.dart   # sl + configureDependencies()
└── main.dart                    # Entry point
```

## 3. Layer flow

```text
UI (screen/widget)
  → Cubit (presentation: holds UI state, Loading / Success / Failure)
  → UseCase (domain: one operation, e.g. SignInUseCase)
  → Repository contract (domain: abstract, no Flutter imports)
  → Repository implementation (data: maps exceptions to Failures)
  → DataSource (data: Supabase client / ApiClient calls)
  → Supabase / REST API
```

Rules:

- **Never** put API calls or business logic in widgets.
- **Never** access a repository implementation from a Cubit — only
  the domain contract, through a UseCase.
- **Never** create dependencies manually — everything comes from
  GetIt (`sl<T>()`), registered in dependency order.
- **Never** put feature code in `core/`, and `core/` never imports
  anything from `features/`.
- **Never** hardcode user-facing text (ARB files, `context.l10n`)
  or UI colors (theme / `AppColors` only).
- **Never** ignore RTL; **never** assume one screen size.

## 4. Error handling — `Result<T>`

Repositories return `Result<T>` (sealed class, `Success` /
`Failure`), never throw to the Cubit. Data sources throw
`AppException`s (`NetworkException`, `AuthException`,
`ServerException`, ...); `ApiClient.mapError` maps a
`DioException` to the matching exception by cause (timeout,
401/403, server error, cancelled). The repository maps the
exception to a `Failure`; the Cubit emits the Failure state and
the UI shows it (toast / error state).

## 5. Networking — centralized `ApiClient` + interceptors

`core/network/api_client.dart` is the single Dio client. All Dio
traffic goes through it (from data sources only). Supabase Auth /
Postgres / Storage go through the Supabase client
(`supabase_flutter`), never through Dio.

Every Dio request passes through three interceptors, in order
(`core/network/api_interceptors.dart`):

1. **AuthInterceptor** — attaches
   `Authorization: Bearer <access token>` when a Supabase session
   exists. The token is read from `SupabaseService` at request
   time (`currentSession?.accessToken`), never stored in a file
   or a variable, never logged. No session / demo mode → the
   request goes out without the header.
2. **LanguageInterceptor** — sends `Accept-Language` with the
   saved locale (`ar` / `en`) from `AppSettingsService`, so a
   server that localizes responses answers in the language the
   user picked, effective on the next request after a switch.
3. **LogInterceptor** (Dio's built-in) — pretty request/response
   logging, **debug builds only** (`kDebugMode`); it prints
   bodies, so it never ships in a release build.

Interceptors read their values at request time, not once at
startup, because the token and the locale can both change while
the app is running. `ApiClient` is registered in GetIt after
both services it depends on (`register_core.dart`).

## 6. Dialogs — `core/dialogs/`

Screens never build their own `AlertDialog` or `SnackBar`.
`core/dialogs/` is the one place for modal feedback:

- `app_toast.dart` — `showAppToast(context, message,
  {isError})`: the only toast in the app (dark teal, red for
  errors; `fluttertoast` plugin, guarded so it can never crash a
  screen or a test). Replaced `SnackBar` everywhere.
- `app_dialogs.dart` — `showAppLoadingDialog` (non-dismissible
  themed spinner + localized "Loading…", closed with
  `hideAppLoadingDialog`) and `showAppConfirmationDialog`
  (returns `Future<bool>`, labels default to the localized
  "Confirm" / "Cancel" from the ARB files).

Both are theme-aware (colors from the current `Theme`) and
localized (no hardcoded text or colors).

## 7. What was evaluated and NOT adopted (2026-11-13)

The user sent a second architecture spec (Feature-First +
Repository + Cubit, `dartz` `Either<Failure, T>`,
`easy_localization`, `flutter_screenutil`, Cubit calling the
repository directly with **no UseCase layer**, and a different
`core/` layout: `api / di / dialogs / error / managers / routes /
theme / utils / widgets`).

It was evaluated and **not adopted** as a whole, for these
reasons:

- **No UseCase / domain layer** — the Cubit would call the
  repository directly, so business rules would live in Cubits
  and could not be reused or unit-tested without the UI. The
  domain + UseCase separation is what keeps the app testable and
  is what senior-level interviews expect.
- **`dartz` `Either`** — does the same job as the existing
  `Result<T>` sealed class, but adds a dependency for no new
  capability.
- **`easy_localization`** — string keys fail at runtime on a
  typo; the ARB + generated `AppLocalizations` approach fails
  at compile time, which is strictly safer.
- **`flutter_screenutil`** — `.w` / `.h` / `.sp` everywhere adds
  a wrapper dependency for sizing the app does not need yet.

Adopted from that spec instead (the parts that are genuine
improvements with no downside):

- **Centralized ApiService with interceptors** — auth token +
  language headers + debug-only pretty logging (§5).
- **`core/dialogs/` folder** — toast moved there, plus the
  loading / confirmation dialog helpers (§6).
