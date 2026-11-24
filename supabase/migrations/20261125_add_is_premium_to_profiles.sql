-- ============================================================================
-- Calora — Add is_premium column to public.profiles
-- ============================================================================
-- Supports Calora Pro / Premium subscription tier status.
-- Safe to re-run: idempotent statement.
-- ============================================================================

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_premium boolean NOT NULL DEFAULT false;

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.is_premium IS 'Indicates whether the user has an active Calora Pro/Premium subscription.';
