# Baytari (بيطري)

A veterinary app connecting pet owners with vets and clinics.
Built with Flutter, Clean Architecture (feature-first), Cubit, GetIt, Dio
and Supabase.

> **M0 scaffold only.** No feature code yet — auth, pets, vets,
> appointments, schedule and dashboard land one at a time (M1–M5).
> The full plan is in `../IMPLEMENTATION_PLAN.md`.
>
> **شرح M0 بالعربي:** `./M0_EXPLANATION_AR.md` — step-by-step Arabic
> explanation of the startup flow, Clean Architecture, theme, language,
> DI, Dio, Supabase demo mode, routing, and tests. Every Dart file in
> `lib/` and `test/` also carries explanatory comments in English.
>
> **شرح M1 بالعربي:** `./M1_EXPLANATION_AR.md` — Auth + Profiles:
> the auth flow, the `profiles` table + RLS, session persistence,
> how to apply the SQL migration, and how to run with `--dart-define`.

## Run

```bash
flutter pub get
flutter gen-l10n        # regenerates lib/core/localization/generated/
flutter run
```

With a Supabase project configured (project: https://jzvwytisqravbqzzznfk.supabase.co — M0 runs in demo
mode without these values):

```bash
flutter run \
  --dart-define SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Without those `--dart-define` values the app still runs and the home
screen says "Supabase is not configured yet" — it does not crash.

## Architecture

```
UI → Cubit → UseCase → Repository Contract (domain)
   → Repository Implementation (data) → DataSource → Supabase / API
```

- `lib/core/` — constants, errors, network (Dio), services, DI,
  localization (ARB, ar + en), theme (Material 3, light + dark),
  utils, extensions, shared widgets, routing.
- `lib/features/<name>/` — each feature is independent and split into
  `data / domain / presentation`. The domain layer never imports
  Flutter, Dio or Supabase.
- `lib/app/` — `BaytariApp` (theme + locale + routing) and `AppCubit`
  (theme mode + locale, persisted with SharedPreferences).
- `lib/injection_container.dart` — GetIt registration, in dependency
  order. Nothing creates its own dependencies.

Rules (mandatory, from the user's spec):

- No hardcoded user-facing text — all strings are in
  `lib/core/localization/l10n/app_{en,ar}.arb`.
- No hardcoded colors in widgets — use `Theme.of(context).colorScheme`
  and `core/theme`.
- No API calls or business logic in widgets.
- No repository implementations accessed from Cubits.
- Arabic is the default language on first run; English is also
  supported, with RTL/LTR handled automatically.

## Verify

```bash
flutter analyze   # must be "No issues found"
flutter test      # widget + unit tests for the home shell and AppCubit
```

## Project status

- M0: scaffold, theme, localization, routing, DI, Dio, Supabase
  service (not configured), home shell + settings — **done**.
- M1: Auth + Profiles (Supabase Auth, role selection, profile
  creation, session persistence, logout) — **done** on branch
  `feature/auth`. Apply `supabase/migrations/20261107000001_auth_profiles.sql`
  in the Supabase dashboard, then run with `--dart-define` (see above).
- M2: Pets — next.
