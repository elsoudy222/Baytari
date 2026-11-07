-- Baytari M1 — Auth + Profiles
-- File: supabase/migrations/20261107000001_auth_profiles.sql
-- Apply in the Supabase dashboard: project jzvwytisqravbqzzznfk
--   -> SQL Editor -> New query -> paste this file -> Run.
-- Run it ONCE. It is safe to re-run: every statement uses
-- "IF NOT EXISTS" / "OR REPLACE" / "DROP POLICY IF EXISTS" first.
--
-- What this migration creates (and ONLY this — the rest of the
-- schema from the implementation plan, clinics / vets / pets /
-- services / appointments / shifts / reviews, comes in later stages):
--   1. The user_role enum.
--   2. The public.profiles table (one row per auth user).
--   3. Row Level Security (RLS) + 4 policies on profiles.
--   4. An updated_at trigger so updated_at refreshes on every edit.
--
-- DESIGN DECISION — no database trigger creates the profile row:
-- The Flutter app creates the profile row itself, right after
-- sign-up / on the first sign-in, from the data stored in the
-- auth user's metadata (full_name + role, saved at sign-up time).
-- Why the app does it instead of a Postgres trigger:
--   * It works whether Supabase "Confirm email" is ON or OFF.
--     With confirmation ON, sign-up returns NO session, so the
--     user cannot insert a row yet; the row is created on the
--     first successful sign-in instead, from the same metadata.
--   * The role the user picked in the app (owner / vet) is the
--     source of truth, and the app code that picks it is also the
--     code that writes it — one place to look, easy to test.
--   * The profile-creation logic is visible in the Dart code
--     (features/auth/data/datasources/supabase_auth_remote_data_source.dart,
--     method _ensureProfile), not hidden in the database.

-- 1) Role enum ---------------------------------------------------------
-- owner: a pet owner. vet: a veterinarian (clinic vet).
-- staff_vet / clinic_admin exist in the enum now so later stages
-- can use them, but the M1 register screen only offers owner/vet.
-- (Postgres enums cannot be extended inside a transaction easily,
-- so all four values are created up front.)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE public.user_role AS ENUM (
      'owner',
      'vet',
      'staff_vet',
      'clinic_admin'
    );
  END IF;
END
$$;

-- 2) profiles table ----------------------------------------------------
-- id is BOTH the primary key AND a foreign key to auth.users(id):
-- one profile per auth user, and deleting the auth user deletes
-- the profile automatically (ON DELETE CASCADE).
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  role public.user_role NOT NULL DEFAULT 'owner',
  full_name text NOT NULL,
  phone text,
  email text NOT NULL,
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Fast look-ups of vets (used by the M3 "browse vets" feature).
CREATE INDEX IF NOT EXISTS profiles_role_idx
  ON public.profiles (role);

-- 3) updated_at trigger ------------------------------------------------
-- Keeps updated_at honest without the app remembering to set it.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_set_updated_at ON public.profiles;
CREATE TRIGGER profiles_set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- 4) Row Level Security -------------------------------------------------
-- RLS is ON: without a policy below, NOBODY (not even a logged-in
-- user) can read or write this table. Each policy answers one question.
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- A user can always read their OWN profile row.
DROP POLICY IF EXISTS "Users can view their own profile"
  ON public.profiles;
CREATE POLICY "Users can view their own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Any logged-in user can read VET profiles (name, role). This is
-- what lets owners browse vets in M3; owners' own rows are already
-- covered by the policy above, and other owners' rows stay hidden.
DROP POLICY IF EXISTS "Authenticated users can view vet profiles"
  ON public.profiles;
CREATE POLICY "Authenticated users can view vet profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (role = 'vet');

-- A user can create ONLY their own profile row (id must be their
-- own auth id). This is the INSERT the app performs after sign-up
-- / on first sign-in.
DROP POLICY IF EXISTS "Users can insert their own profile"
  ON public.profiles;
CREATE POLICY "Users can insert their own profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- A user can update ONLY their own profile row (name, phone, avatar).
DROP POLICY IF EXISTS "Users can update their own profile"
  ON public.profiles;
CREATE POLICY "Users can update their own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- No DELETE policy on purpose: profiles are deleted automatically
-- when the auth user is deleted (ON DELETE CASCADE above). Users
-- must not delete each other's rows, and their own row is tied to
-- their account, so deleting the account is the way to delete it.
