# pets

M0 placeholder — no feature logic yet.

Planned stage: M2 — Pets: my pets list / add / edit, pet details, photo upload to Supabase Storage.

Structure (Clean Architecture, feature-first):

- `data/` — data sources, models, repository implementations.
- `domain/` — entities, repository contracts, use cases. No Flutter/Dio/Supabase imports here.
- `presentation/` — Cubit + state, screens, feature-only widgets.

Flow: UI → Cubit → UseCase → Repository Contract → Repository Implementation → DataSource.
