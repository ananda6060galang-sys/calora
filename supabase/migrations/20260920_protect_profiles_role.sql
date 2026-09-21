-- ============================================================================
-- Calora — Protect public.profiles.role against client-side privilege escalation
-- ============================================================================
-- 1. Trigger function that prevents non-privileged roles (like 'authenticated')
--    from modifying the 'role' column on public.profiles.
--    Does not query public.profiles, completely eliminating RLS recursion risk.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.protect_profile_role()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  -- If 'role' is being changed by an authenticated client request, reject it
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    IF (SELECT auth.role()) = 'authenticated' THEN
      RAISE EXCEPTION 'Modifying user role is not permitted';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- 2. Attach trigger to public.profiles BEFORE UPDATE
DROP TRIGGER IF EXISTS tr_protect_profile_role ON public.profiles;
CREATE TRIGGER tr_protect_profile_role
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_role();

-- ============================================================================
-- 3. Update the RLS policy for UPDATE on public.profiles:
--    Allow authenticated users to update their own profile row.
--    (The trigger above strictly enforces that the 'role' column cannot be altered).
--    This ensures legitimate admins (role = 'admin') can update their own
--    profile fields (weight, avatar, etc.) without failing RLS checks.
-- ============================================================================
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);
