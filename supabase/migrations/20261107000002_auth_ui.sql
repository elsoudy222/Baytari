-- Baytari auth UI — second migration (apply AFTER 20261107000001)
-- File: supabase/migrations/20261107000002_auth_ui.sql
-- Apply in the Supabase dashboard: project jzvwytisqravbqzzznfk
--   -> SQL Editor -> New query -> paste this file -> Run.
-- Run it ONCE, before running the app with the new auth UI code:
-- the new code inserts/updates the columns below, so without this
-- migration the profile insert fails on unknown columns.
-- It is safe to re-run: every statement is guarded with
-- "IF NOT EXISTS" / "OR REPLACE" / "DROP POLICY IF EXISTS".
--
-- What this migration adds:
--   1. Two shelter roles to the user_role enum.
--   2. username (UNIQUE), license_url, workplace_note on profiles.
--   3. Storage buckets `avatars` (public) and `licenses` (private)
--      with RLS policies so a user can upload/read their own files.
--
-- SUPABASE SETTINGS the app needs (dashboard, NOT in this file):
--   Authentication -> Providers -> Email -> "Confirm email" ON
--   (default): sign-up sends a confirmation email. For the 6-digit
--   OTP screens the email template must use the {{ .Token }}
--   variable (Authentication -> Email Templates -> "Confirm
--   signup" / "Reset password" templates): if the template sends
--   only a link, the user gets a link instead of a code and the
--   OTP boxes have nothing to verify. See AUTH_UI_EXPLANATION_AR.md.

-- 1) Shelter roles ------------------------------------------------------
-- `ADD VALUE IF NOT EXISTS` is a standalone statement on purpose:
-- adding an enum value cannot run inside a transaction block, and
-- the Supabase SQL editor runs each statement on its own.
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'shelter_owner';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'shelter_worker';

-- 2) New profile columns ------------------------------------------------
-- username: picked on the "Welcome To Baytari!" step. UNIQUE so
-- two users cannot share one name; existing rows get NULL (no
-- backfill — old accounts pick a username from the profile screen).
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username text UNIQUE;

-- license_url: storage path of the licence photo in the private
-- `licenses` bucket (a path, not a public URL — see the doc).
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS license_url text;

-- workplace_note: free text for staff vets / shelter workers
-- ("works at clinic/shelter X"). There are no clinics / shelters
-- tables yet, so this is text for now, not a foreign key.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS workplace_note text;

-- 3) Storage buckets ----------------------------------------------------
-- avatars: PUBLIC — profile photos are shown to other users
-- (vet profiles, community), so the app reads them by public URL.
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- licenses: PRIVATE — licence photos are sensitive documents;
-- only the owner (and admins in the dashboard) can open them.
INSERT INTO storage.buckets (id, name, public)
VALUES ('licenses', 'licenses', false)
ON CONFLICT (id) DO NOTHING;

-- 4) Storage RLS policies -----------------------------------------------
-- Policies live on storage.objects. `storage.foldername(name)[1]`
-- is the first folder of the object path — the app uploads to
-- `<user-id>/avatar.jpg`, so the first folder IS the user id, and
-- the policy below lets a user touch only their own folder.
--
-- NOTE (fixed 2026-11-07): there is NO "ALTER TABLE storage.objects
-- ENABLE ROW LEVEL SECURITY" here on purpose. RLS is already enabled
-- on storage.objects in every Supabase project, and the dashboard
-- SQL editor role does not own that table, so that statement fails
-- with "ERROR 42501: must be owner of table objects" and stops the
-- whole migration. Creating/dropping policies below works fine
-- from the SQL editor.

-- Avatars: anyone can READ (public profiles), the owner can
-- INSERT / UPDATE their own, and DELETE their own.
DROP POLICY IF EXISTS "Anyone can view avatars"
  ON storage.objects;
CREATE POLICY "Anyone can view avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload their own avatar"
  ON storage.objects;
CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can update their own avatar"
  ON storage.objects;
CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can delete their own avatar"
  ON storage.objects;
CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Licences: only the owner can INSERT / SELECT / UPDATE / DELETE
-- their own licence photo (private bucket, no public read).
DROP POLICY IF EXISTS "Users can upload their own licence"
  ON storage.objects;
CREATE POLICY "Users can upload their own licence"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'licenses'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can view their own licence"
  ON storage.objects;
CREATE POLICY "Users can view their own licence"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'licenses'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can update their own licence"
  ON storage.objects;
CREATE POLICY "Users can update their own licence"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'licenses'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can delete their own licence"
  ON storage.objects;
CREATE POLICY "Users can delete their own licence"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'licenses'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
