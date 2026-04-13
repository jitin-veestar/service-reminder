-- Fix 403 on upload: ensure policies exist and match object paths.
-- App uploads to: {auth.uid()}/{customer_id}/{uuid}.m4a
-- Bucket id must be exactly: service-recordings

DROP POLICY IF EXISTS "service_recordings_select_own" ON storage.objects;
DROP POLICY IF EXISTS "service_recordings_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "service_recordings_update_own" ON storage.objects;
DROP POLICY IF EXISTS "service_recordings_delete_own" ON storage.objects;

-- split_part is reliable across Postgres versions; first segment must equal signed-in user id
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
