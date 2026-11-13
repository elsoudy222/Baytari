# home

The Home feed (Figma's "Home - community member") — built 2026-11-13.

The owner Home is a community feed, not a dashboard: report posts
with photos, status chips, Help, comments + replies + likes, a
create-report form, and a bottom-nav shell (Home built;
Map/Community/Vets/Shelters are placeholders for now).

Structure (Clean Architecture, feature-first):

- `data/` — Supabase data source, models, repository implementation.
- `domain/` — entities, repository contract, use cases. No Flutter/Dio/Supabase imports here.
- `presentation/` — 3 Cubits (feed / comments / create-report) + states, screens, feature-only widgets.

Flow: UI → Cubit → UseCase → Repository Contract → Repository Implementation → DataSource.

Tables (migration `20261107000003_home_feed.sql`): `reports`,
`report_photos`, `report_comments`, `report_helpers`,
`report_statuses`, `comment_likes` + the `report-photos` bucket.

See `HOME_FEED_EXPLANATION_AR.md` (project root) for the full
Arabic explanation.
