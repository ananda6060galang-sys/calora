-- 1. Ensure public.profiles has avatar_url if genuinely missing
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;

-- 2. Create avatars storage bucket if not exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 3. Clean up existing avatar storage policies to avoid duplicate conflicts
DROP POLICY IF EXISTS "Avatar images are publicly accessible." ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar." ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar." ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar." ON storage.objects;

-- 4. Enable public read access for avatar images
CREATE POLICY "Avatar images are publicly accessible."
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- 5. Enable authenticated users to upload avatar only in their own folder
CREATE POLICY "Users can upload their own avatar."
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = (select auth.uid())::text
);

-- 6. Enable authenticated users to update avatar only in their own folder
CREATE POLICY "Users can update their own avatar."
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = (select auth.uid())::text
)
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = (select auth.uid())::text
);

-- 7. Enable authenticated users to delete avatar only in their own folder
CREATE POLICY "Users can delete their own avatar."
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = (select auth.uid())::text
);
