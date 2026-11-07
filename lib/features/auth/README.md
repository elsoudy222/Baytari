# auth

M1 — Auth + Profiles: Supabase Auth (email + password), role selection
(owner / vet), profile creation, session persistence, logout.

Structure (Clean Architecture, feature-first):

- `data/datasources/` — `AuthRemoteDataSource` (contract) +
  `SupabaseAuthRemoteDataSource` (Supabase Auth + `profiles` table).
  The only files in the feature that import Supabase.
- `data/models/` — `ProfileModel` (JSON <-> `Profile`, manual
  `fromJson` / `toJson`, no codegen).
- `data/repositories/` — `AuthRepositoryImpl` (maps data-source
  exceptions to domain `Failure`s, wrapped in `Result`).
- `domain/entities/` — `Profile`, `UserRole` (no Flutter imports).
- `domain/repositories/` — `AuthRepository` (the contract).
- `domain/usecases/` — one use case per action: sign up, sign in,
  sign out, get current profile, update profile.
- `presentation/cubit/` — `AuthCubit` + `AuthState` (app-wide, one
  instance owned by `BaytariApp`).
- `presentation/screens/` — login, register (with role picker),
  profile (view / edit / logout).
- `presentation/widgets/` — `RoleSelector` (owner / vet).
- `di/register_auth.dart` — GetIt registration, dependency order.

Flow: UI → Cubit → UseCase → Repository Contract → Repository
Implementation → DataSource → Supabase.

Profile rows are created by the app (`_ensureProfile` in the data
source), from the auth user's metadata saved at sign-up — NOT by a
database trigger. See the M1 SQL migration
(`supabase/migrations/20261107000001_auth_profiles.sql`) and
`M1_EXPLANATION_AR.md` for why.
