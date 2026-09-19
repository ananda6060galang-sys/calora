-- ============================================================================
-- Calora — Core Schema
-- ============================================================================
-- Brings the live database in line with the ERD documented in the PRD
-- (section 13) and LAPORAN PJBL (Lampiran 1, Tabel L.1–L.5).
--
-- Context: only `profiles` and `diary_entries` exist at the time of writing.
-- The remaining ERD tables are created here so the deployed schema matches
-- the documented design. Tables backing not-yet-implemented features
-- (workout_*, weight_logs, food_request, foods, food_categories) are created
-- empty on purpose — the report's "Kelemahan" section states these features
-- are designed but not yet wired to the database.
--
-- Safe to re-run: every statement is idempotent.
-- ============================================================================


-- ============================================================================
-- 1. food_categories — master data, read-only for users
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.food_categories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT food_categories_name_unique UNIQUE (name)
);

ALTER TABLE public.food_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Food categories are readable by everyone" ON public.food_categories;
CREATE POLICY "Food categories are readable by everyone"
  ON public.food_categories FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Only admins can write food categories" ON public.food_categories;
CREATE POLICY "Only admins can write food categories"
  ON public.food_categories FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin')
  );


-- ============================================================================
-- 2. foods — public food database, users read-only (business rule)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.foods (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id   uuid REFERENCES public.food_categories(id) ON DELETE SET NULL,
  name          text NOT NULL,
  serving_label text NOT NULL,
  calories      integer NOT NULL DEFAULT 0 CHECK (calories >= 0),
  protein_g     double precision NOT NULL DEFAULT 0 CHECK (protein_g >= 0),
  carbs_g       double precision NOT NULL DEFAULT 0 CHECK (carbs_g >= 0),
  fat_g         double precision NOT NULL DEFAULT 0 CHECK (fat_g >= 0),
  portion_grams double precision CHECK (portion_grams IS NULL OR portion_grams >= 0),
  source        text NOT NULL DEFAULT 'manual',
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS foods_name_idx ON public.foods (lower(name));
CREATE INDEX IF NOT EXISTS foods_category_id_idx ON public.foods (category_id);

ALTER TABLE public.foods ENABLE ROW LEVEL SECURITY;

-- Users may NEVER write to foods directly — submissions go through food_request.
DROP POLICY IF EXISTS "Foods are readable by authenticated users" ON public.foods;
CREATE POLICY "Foods are readable by authenticated users"
  ON public.foods FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Only admins can write foods" ON public.foods;
CREATE POLICY "Only admins can write foods"
  ON public.foods FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin')
  );


-- ============================================================================
-- 3. food_request — user submissions, admin-moderated only
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.food_request (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id   uuid REFERENCES public.food_categories(id) ON DELETE SET NULL,
  food_name     text NOT NULL,
  serving_label text NOT NULL,
  calories      integer NOT NULL DEFAULT 0 CHECK (calories >= 0),
  protein_g     double precision NOT NULL DEFAULT 0 CHECK (protein_g >= 0),
  carbs_g       double precision NOT NULL DEFAULT 0 CHECK (carbs_g >= 0),
  fat_g         double precision NOT NULL DEFAULT 0 CHECK (fat_g >= 0),
  status        text NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'approved', 'rejected')),
  notes         text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS food_request_user_id_idx ON public.food_request (user_id);
CREATE INDEX IF NOT EXISTS food_request_status_idx ON public.food_request (status);

ALTER TABLE public.food_request ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own food requests" ON public.food_request;
CREATE POLICY "Users can read their own food requests"
  ON public.food_request FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can submit food requests" ON public.food_request;
CREATE POLICY "Users can submit food requests"
  ON public.food_request FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Users may edit/withdraw only while still pending.
DROP POLICY IF EXISTS "Users can update their own pending food requests" ON public.food_request;
CREATE POLICY "Users can update their own pending food requests"
  ON public.food_request FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id AND status = 'pending')
  WITH CHECK ((SELECT auth.uid()) = user_id AND status = 'pending');

DROP POLICY IF EXISTS "Users can withdraw their own pending food requests" ON public.food_request;
CREATE POLICY "Users can withdraw their own pending food requests"
  ON public.food_request FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id AND status = 'pending');

-- Admins moderate every request. Note: this is the ONLY user-generated table
-- admins may read — personal health data stays private (see AGENTS.md).
DROP POLICY IF EXISTS "Admins can moderate all food requests" ON public.food_request;
CREATE POLICY "Admins can moderate all food requests"
  ON public.food_request FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin')
  );


-- ============================================================================
-- 4. weight_logs — personal health data, owner-only
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.weight_logs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weight_kg   double precision NOT NULL CHECK (weight_kg > 0),
  logged_date date NOT NULL DEFAULT CURRENT_DATE,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS weight_logs_user_date_idx
  ON public.weight_logs (user_id, logged_date DESC);

ALTER TABLE public.weight_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage their own weight logs" ON public.weight_logs;
CREATE POLICY "Users manage their own weight logs"
  ON public.weight_logs FOR ALL
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);


-- ============================================================================
-- 5. exercises — master exercise catalogue, read-only for users
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.exercises (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text NOT NULL,
  muscle_group text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT exercises_name_unique UNIQUE (name)
);

ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Exercises are readable by authenticated users" ON public.exercises;
CREATE POLICY "Exercises are readable by authenticated users"
  ON public.exercises FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Only admins can write exercises" ON public.exercises;
CREATE POLICY "Only admins can write exercises"
  ON public.exercises FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin')
  );


-- ============================================================================
-- 6. workout_session — personal health data, owner-only
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.workout_session (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name       text,
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at   timestamptz,
  notes      text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS workout_session_user_idx
  ON public.workout_session (user_id, started_at DESC);

ALTER TABLE public.workout_session ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage their own workout sessions" ON public.workout_session;
CREATE POLICY "Users manage their own workout sessions"
  ON public.workout_session FOR ALL
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);


-- ============================================================================
-- 7. workout_sets — personal health data, owner-only
--     Cardinality per PRD ERD: workout_session 1—N workout_sets,
--                             exercises      1—N workout_sets
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.workout_sets (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id   uuid NOT NULL REFERENCES public.workout_session(id) ON DELETE CASCADE,
  exercise_id  uuid REFERENCES public.exercises(id) ON DELETE SET NULL,
  set_number   integer NOT NULL DEFAULT 1 CHECK (set_number > 0),
  reps         integer NOT NULL DEFAULT 0 CHECK (reps >= 0),
  weight_kg    double precision NOT NULL DEFAULT 0 CHECK (weight_kg >= 0),
  completed    boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS workout_sets_session_idx ON public.workout_sets (session_id);
CREATE INDEX IF NOT EXISTS workout_sets_exercise_idx ON public.workout_sets (exercise_id);

ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;

-- Ownership is inherited through the parent session.
DROP POLICY IF EXISTS "Users manage their own workout sets" ON public.workout_sets;
CREATE POLICY "Users manage their own workout sets"
  ON public.workout_sets FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.workout_session s
            WHERE s.id = session_id AND s.user_id = (SELECT auth.uid()))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.workout_session s
            WHERE s.id = session_id AND s.user_id = (SELECT auth.uid()))
  );


-- ============================================================================
-- 8. Seed food_categories so the Food Request / Food Search UI has options
-- ============================================================================
INSERT INTO public.food_categories (name) VALUES
  ('Protein'), ('Carbs'), ('Fats'), ('Dairy'), ('Fruit'), ('General')
ON CONFLICT (name) DO NOTHING;


-- ============================================================================
-- 9. Verify: list what now exists
-- ============================================================================
-- Run this after applying to confirm all 10 ERD tables are present:
--
--   SELECT table_name FROM information_schema.tables
--   WHERE table_schema = 'public' ORDER BY table_name;
--
-- Expected: diary_entries, exercises, food_categories, food_request, foods,
--           profiles, weight_logs, workout_session, workout_sets
