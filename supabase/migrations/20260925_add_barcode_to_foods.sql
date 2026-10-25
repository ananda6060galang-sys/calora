-- Migration: Add barcode, brand, and image_url to foods and food_request tables
-- Aligns with Calora Barcode Scanner end-to-end functionality

ALTER TABLE public.foods
  ADD COLUMN IF NOT EXISTS barcode text,
  ADD COLUMN IF NOT EXISTS brand text,
  ADD COLUMN IF NOT EXISTS image_url text;

CREATE INDEX IF NOT EXISTS foods_barcode_idx ON public.foods (barcode);

ALTER TABLE public.food_request
  ADD COLUMN IF NOT EXISTS barcode text;

CREATE INDEX IF NOT EXISTS food_request_barcode_idx ON public.food_request (barcode);
