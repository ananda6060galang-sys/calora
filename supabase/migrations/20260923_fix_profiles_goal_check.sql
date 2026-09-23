-- ============================================================================
-- Calora — Fix profiles_goal_check constraint
-- ============================================================================
-- The Flutter application supports Goal.gainWeight which writes 'gain_weight'.
-- The previous constraint only permitted ('lose_weight', 'maintain_weight', 'gain_muscle', 'lean_bulk').
-- This migration updates profiles_goal_check to also accept 'gain_weight'.
-- ============================================================================

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_goal_check;

ALTER TABLE public.profiles ADD CONSTRAINT profiles_goal_check 
  CHECK (goal IS NULL OR goal = ANY (ARRAY[
    'lose_weight'::text,
    'maintain_weight'::text,
    'gain_weight'::text,
    'gain_muscle'::text,
    'lean_bulk'::text
  ]));
