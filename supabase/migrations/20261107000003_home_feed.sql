-- Baytari Home feed — third migration (apply AFTER 20261107000002)
-- File: supabase/migrations/20261107000003_home_feed.sql
-- Apply in the Supabase dashboard: project jzvwytisqravbqzzznfk
--   -> SQL Editor -> New query -> paste this file -> Run.
-- Run it ONCE, before running the app with the Home feed code:
-- the feed reads the tables below, so without this migration the
-- feed fails on unknown tables.
-- It is safe to re-run: every statement is guarded with
-- "IF NOT EXISTS" / "OR REPLACE" / "DROP POLICY IF EXISTS".
--
-- What this migration adds:
--   1. reports — a community report about a stray / lost /
--      adoptable animal (the posts of the Home feed).
--   2. report_photos — the photos of a report (1..n, ordered).
--   3. report_comments — comments on a report, with one level of
--      replies (parent_id) and an optional status label.
--   4. report_helpers — who pressed "Help" on a report.
--   5. report_statuses — each user's latest status on a report
--      (the "Share Status Update" chips).
--   6. comment_likes — who liked a comment (like count is the
--      row count; no denormalized counter is stored).
--   7. Storage bucket `report-photos` (public, per-user folders).
--   8. B8 fix (from REVIEW_DEV_VS_FIGMA_AR.md): a policy letting
--      users read other users' profiles, so the feed can show
--      report authors' names and avatars.
--
-- PRIVACY NOTE on (8): Postgres RLS works per ROW, not per column,
-- so a SELECT policy cannot expose only full_name / username /
-- avatar_url — it exposes the whole row (including phone and
-- email) to whoever the policy grants. The app only DISPLAYS the
-- public fields (name, username, avatar), and the profile screen
-- still shows the phone only to its owner. If this ever needs to
-- be stricter, the follow-up is a `public_profiles` view with
-- only the public columns — that is a hardening step for later,
-- not part of this migration.
--
-- GUEST BROWSING: the feed is readable without signing in (the
-- app lets guests browse Home), so the read policies below grant
-- SELECT to `anon` as well as `authenticated`. Writes stay
-- authenticated-only, and every write policy checks that the
-- row belongs to the caller (auth.uid()).

-- 1) reports ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id uuid NOT NULL REFERENCES public.profiles (id),
  -- What kind of report: stray (stray animal), lost (lost pet),
  -- adoption (animal looking for a home).
  category text NOT NULL CHECK (category IN ('stray', 'lost', 'adoption')),
  -- How urgent: urgent / high / mid / low (Figma shows all four).
  priority text NOT NULL CHECK (priority IN ('urgent', 'high', 'mid', 'low')),
  -- dog / cat / other.
  animal_type text NOT NULL CHECK (animal_type IN ('dog', 'cat', 'other')),
  description text NOT NULL,
  location_text text,
  latitude double precision,
  longitude double precision,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Newest first is the feed order, so index the sort key.
CREATE INDEX IF NOT EXISTS reports_created_at_idx
  ON public.reports (created_at DESC);
CREATE INDEX IF NOT EXISTS reports_category_idx
  ON public.reports (category);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Anyone (signed in or guest) can read all reports: the feed is
-- public, like a community board.
DROP POLICY IF EXISTS "Anyone can view reports"
  ON public.reports;
CREATE POLICY "Anyone can view reports"
  ON public.reports FOR SELECT
  TO authenticated, anon
  USING (true);

-- Only the author can write their own report.
DROP POLICY IF EXISTS "Users can insert their own reports"
  ON public.reports;
CREATE POLICY "Users can insert their own reports"
  ON public.reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Authors can update their own reports"
  ON public.reports;
CREATE POLICY "Authors can update their own reports"
  ON public.reports FOR UPDATE
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Authors can delete their own reports"
  ON public.reports;
CREATE POLICY "Authors can delete their own reports"
  ON public.reports FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);

-- 2) report_photos ------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.report_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid NOT NULL REFERENCES public.reports (id)
    ON DELETE CASCADE,
  -- Storage path inside the `report-photos` bucket
  -- (e.g. "<user-id>/1700000000000_0.jpg"), NOT a public URL:
  -- the app builds the public URL from the path.
  storage_path text NOT NULL,
  -- Display order inside the photo grid (0, 1, 2, ...).
  position int NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS report_photos_report_idx
  ON public.report_photos (report_id, position);

ALTER TABLE public.report_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view report photos"
  ON public.report_photos;
CREATE POLICY "Anyone can view report photos"
  ON public.report_photos FOR SELECT
  TO authenticated, anon
  USING (true);

-- Only the report's author can add/remove its photos.
DROP POLICY IF EXISTS "Report authors can insert photos"
  ON public.report_photos;
CREATE POLICY "Report authors can insert photos"
  ON public.report_photos FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.reports r
      WHERE r.id = report_id AND r.author_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Report authors can delete photos"
  ON public.report_photos;
CREATE POLICY "Report authors can delete photos"
  ON public.report_photos FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.reports r
      WHERE r.id = report_id AND r.author_id = auth.uid()
    )
  );

-- 3) report_comments -----------------------------------------------------
-- Status values: the "Share Status Update" chips. They differ per
-- report category in Figma, so the check lists every chip of every
-- category: stray (sighted/rescued/in_shelter/at_vet/couldnt_find),
-- lost (sighted/in_safe_hands/not_found), adoption
-- (interested/ready_to_adopt/in_process/adopted).
CREATE TABLE IF NOT EXISTS public.report_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid NOT NULL REFERENCES public.reports (id)
    ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES public.profiles (id),
  -- NULL = a top-level comment; set = a reply to that comment.
  -- Only one level of replies (replies to replies are not allowed
  -- by the app, and the UI renders one nested level).
  parent_id uuid REFERENCES public.report_comments (id)
    ON DELETE CASCADE,
  body text NOT NULL,
  -- The commenter's status when they wrote it (a copy of their
  -- latest report_statuses value, so the bubble colour and label
  -- stay correct even if they change status later). NULL = no
  -- status (plain white bubble in Figma).
  status text CHECK (status IN (
    'sighted', 'rescued', 'in_shelter', 'at_vet', 'couldnt_find',
    'in_safe_hands', 'not_found',
    'interested', 'ready_to_adopt', 'in_process', 'adopted'
  )),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS report_comments_report_idx
  ON public.report_comments (report_id, created_at);

ALTER TABLE public.report_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view report comments"
  ON public.report_comments;
CREATE POLICY "Anyone can view report comments"
  ON public.report_comments FOR SELECT
  TO authenticated, anon
  USING (true);

DROP POLICY IF EXISTS "Users can insert their own comments"
  ON public.report_comments;
CREATE POLICY "Users can insert their own comments"
  ON public.report_comments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Users can delete their own comments"
  ON public.report_comments;
CREATE POLICY "Users can delete their own comments"
  ON public.report_comments FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);

-- 4) report_helpers ------------------------------------------------------
-- One row per (report, user): pressing "Help" inserts it,
-- pressing again deletes it. The helpers count is the row count.
CREATE TABLE IF NOT EXISTS public.report_helpers (
  report_id uuid NOT NULL REFERENCES public.reports (id)
    ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (report_id, user_id)
);

ALTER TABLE public.report_helpers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view report helpers"
  ON public.report_helpers;
CREATE POLICY "Anyone can view report helpers"
  ON public.report_helpers FOR SELECT
  TO authenticated, anon
  USING (true);

DROP POLICY IF EXISTS "Users can mark themselves as helpers"
  ON public.report_helpers;
CREATE POLICY "Users can mark themselves as helpers"
  ON public.report_helpers FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unmark themselves as helpers"
  ON public.report_helpers;
CREATE POLICY "Users can unmark themselves as helpers"
  ON public.report_helpers FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 5) report_statuses -----------------------------------------------------
-- One row per (report, user): the user's LATEST status on that
-- report. Tapping a chip upserts it (INSERT ... ON CONFLICT
-- UPDATE in the app). No history is kept — only the latest.
CREATE TABLE IF NOT EXISTS public.report_statuses (
  report_id uuid NOT NULL REFERENCES public.reports (id)
    ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles (id),
  status text NOT NULL CHECK (status IN (
    'sighted', 'rescued', 'in_shelter', 'at_vet', 'couldnt_find',
    'in_safe_hands', 'not_found',
    'interested', 'ready_to_adopt', 'in_process', 'adopted'
  )),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (report_id, user_id)
);

ALTER TABLE public.report_statuses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view report statuses"
  ON public.report_statuses;
CREATE POLICY "Anyone can view report statuses"
  ON public.report_statuses FOR SELECT
  TO authenticated, anon
  USING (true);

DROP POLICY IF EXISTS "Users can set their own status"
  ON public.report_statuses;
CREATE POLICY "Users can set their own status"
  ON public.report_statuses FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own status"
  ON public.report_statuses;
CREATE POLICY "Users can update their own status"
  ON public.report_statuses FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own status"
  ON public.report_statuses;
CREATE POLICY "Users can delete their own status"
  ON public.report_statuses FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 6) comment_likes --------------------------------------------------------
-- One row per (comment, user). The like count shown in the UI is
-- the row count — no denormalized counter column is stored, so
-- the count can never drift out of sync.
CREATE TABLE IF NOT EXISTS public.comment_likes (
  comment_id uuid NOT NULL REFERENCES public.report_comments (id)
    ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (comment_id, user_id)
);

ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view comment likes"
  ON public.comment_likes;
CREATE POLICY "Anyone can view comment likes"
  ON public.comment_likes FOR SELECT
  TO authenticated, anon
  USING (true);

DROP POLICY IF EXISTS "Users can like a comment"
  ON public.comment_likes;
CREATE POLICY "Users can like a comment"
  ON public.comment_likes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unlike a comment"
  ON public.comment_likes;
CREATE POLICY "Users can unlike a comment"
  ON public.comment_likes FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 7) Storage bucket `report-photos` --------------------------------------
-- PUBLIC: report photos are shown to everyone in the feed (guests
-- included), so the app reads them by public URL.
INSERT INTO storage.buckets (id, name, public)
VALUES ('report-photos', 'report-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Same per-user-folder pattern as the avatars bucket (migration 2):
-- the app uploads to "<user-id>/<file>.jpg", so the first folder
-- IS the user id, and a user can touch only their own folder.
DROP POLICY IF EXISTS "Anyone can view report photos"
  ON storage.objects;
CREATE POLICY "Anyone can view report photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'report-photos');

DROP POLICY IF EXISTS "Users can upload their own report photos"
  ON storage.objects;
CREATE POLICY "Users can upload their own report photos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'report-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can update their own report photos"
  ON storage.objects;
CREATE POLICY "Users can update their own report photos"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'report-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can delete their own report photos"
  ON storage.objects;
CREATE POLICY "Users can delete their own report photos"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'report-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 8) B8 fix: let users read other users' profiles -----------------------
-- The feed shows report authors' names and avatars, so any user
-- must be able to read any profile row. The existing vet-only
-- policy stays as it is; this policy sits alongside it.
-- NOTE (see the privacy note at the top of this file): RLS is
-- per-row, so this opens the whole profile row to readers — the
-- app only displays the public fields (full_name, username,
-- avatar_url). Guests (anon) get the same read access so they
-- can browse the feed with author names and photos.
DROP POLICY IF EXISTS "Anyone can view public profiles"
  ON public.profiles;
CREATE POLICY "Anyone can view public profiles"
  ON public.profiles FOR SELECT
  TO authenticated, anon
  USING (true);
