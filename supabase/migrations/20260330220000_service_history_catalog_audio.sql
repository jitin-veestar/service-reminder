-- Links each visit to an optional catalog row (`public.services`) and optional voice note in Storage.

ALTER TABLE public.service_history
  ADD COLUMN IF NOT EXISTS catalog_service_id uuid REFERENCES public.services (id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS audio_storage_path text;

COMMENT ON COLUMN public.service_history.catalog_service_id IS 'Optional FK to technician service offering (default price, name).';
COMMENT ON COLUMN public.service_history.audio_storage_path IS 'Path in bucket service-recordings, e.g. {auth.uid()}/{customer_id}/{uuid}.m4a';

-- Storage bucket (private; app uses signed URLs).
INSERT INTO storage.buckets (id, name, public)
VALUES ('service-recordings', 'service-recordings', false)
ON CONFLICT (id) DO NOTHING;

-- Authenticated users may read/write only under folder named with their user id (first path segment).
DROP POLICY IF EXISTS "service_recordings_select_own" ON storage.objects;
DROP POLICY IF EXISTS "service_recordings_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "service_recordings_update_own" ON storage.objects;
DROP POLICY IF EXISTS "service_recordings_delete_own" ON storage.objects;

CREATE POLICY "service_recordings_select_own"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'service-recordings'
    AND split_part(name, '/', 1) = (auth.uid())::text
  );

CREATE POLICY "service_recordings_insert_own"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'service-recordings'
    AND split_part(name, '/', 1) = (auth.uid())::text
  );

CREATE POLICY "service_recordings_update_own"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'service-recordings'
    AND split_part(name, '/', 1) = (auth.uid())::text
  )
  WITH CHECK (
    bucket_id = 'service-recordings'
    AND split_part(name, '/', 1) = (auth.uid())::text
  );

CREATE POLICY "service_recordings_delete_own"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'service-recordings'
    AND split_part(name, '/', 1) = (auth.uid())::text
  );
