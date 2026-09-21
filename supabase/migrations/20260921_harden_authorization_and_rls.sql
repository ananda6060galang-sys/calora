-- ============================================================================
-- Calora — Harden Authorization and Row Level Security (RLS)
-- ============================================================================
-- 1. Upgrade role protection trigger on public.profiles:
--    - Intercepts both INSERT and UPDATE before writing to the database.
--    - Guarantees that any request from role 'authenticated' (client API):
--        a) Must have role = 'user' on INSERT.
--        b) Cannot change role (NEW.role IS DISTINCT FROM OLD.role) on UPDATE.
--    - Does not query public.profiles, completely eliminating RLS recursion risk.
--    - Server/database administration (SQL Editor, migrations, service_role)
--      remains fully able to manage roles.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.protect_profile_role()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  -- On INSERT from an authenticated client:
  -- The role MUST be 'user' (or defaulted to 'user'). Setting role to 'admin' is blocked.
  IF TG_OP = 'INSERT' THEN
    IF (SELECT auth.role()) = 'authenticated' THEN
      IF NEW.role IS DISTINCT FROM 'user' THEN
        RAISE EXCEPTION 'Setting role to non-user is not permitted';
      END IF;
    END IF;
  -- On UPDATE from an authenticated client:
  -- The role cannot be modified.
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      IF (SELECT auth.role()) = 'authenticated' THEN
        RAISE EXCEPTION 'Modifying user role is not permitted';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_protect_profile_role ON public.profiles;
CREATE TRIGGER tr_protect_profile_role
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_role();

-- ============================================================================
-- 2. Owner-only RLS policies on public.profiles
--    Personal health & biometrics data: strictly private to the row owner.
--    Admins moderate food_requests, but cannot view/modify other users' profiles.
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- SELECT: authenticated users can only view their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = id);

-- INSERT: authenticated users can only create their own profile, and initial role must be 'user'
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) = id
    AND role = 'user'
  );

-- UPDATE: authenticated users can only update their own profile
-- (tr_protect_profile_role prevents changing role, while allowing admins to update normal fields)
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

-- DELETE: authenticated users can only delete their own profile
DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;
CREATE POLICY "Users can delete own profile"
  ON public.profiles FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = id);

-- ============================================================================
-- 3. Owner-only RLS policies on public.diary_entries
--    Personal nutrition diary data: strictly private to the row owner.
-- ============================================================================
ALTER TABLE public.diary_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can select own diary entries" ON public.diary_entries;
CREATE POLICY "Users can select own diary entries"
  ON public.diary_entries FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own diary entries" ON public.diary_entries;
CREATE POLICY "Users can insert own diary entries"
  ON public.diary_entries FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own diary entries" ON public.diary_entries;
CREATE POLICY "Users can update own diary entries"
  ON public.diary_entries FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own diary entries" ON public.diary_entries;
CREATE POLICY "Users can delete own diary entries"
  ON public.diary_entries FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 4. Table Privileges for Authenticated Role
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.diary_entries TO authenticated;
