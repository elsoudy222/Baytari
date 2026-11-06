# auth

M0 placeholder — no feature logic yet.

Planned stage: M1 — Auth + Profiles: Supabase Auth, role selection, profile creation, session persistence.

Structure (Clean Architecture, feature-first):

- `data/` — data sources, models, repository implementations.
- `domain/` — entities, repository contracts, use cases. No Flutter/Dio/Supabase imports here.
- `presentation/` — Cubit + state, screens, feature-only widgets.

Flow: UI → Cubit → UseCase → Repository Contract → Repository Implementation → DataSource.
