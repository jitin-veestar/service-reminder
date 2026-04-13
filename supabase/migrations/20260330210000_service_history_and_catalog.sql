-- 1) Rename old visit table (run only if your table is still named `services`):
--    ALTER TABLE public.services RENAME TO service_history;
--
-- 2) Visit / RO records live in `service_history` (same columns you had on `services`).

-- 3) New catalog: reusable service offerings per technician (`services` table).

CREATE TABLE IF NOT EXISTS public.services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  technician_id uuid NOT NULL,
  name text NOT NULL,
  description text,
  default_price double precision,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS services_technician_id_idx ON public.services (technician_id);

COMMENT ON TABLE public.services IS 'Technician service menu (names, default prices). Visit rows use service_history.';
COMMENT ON TABLE public.service_history IS 'Per-customer RO visit records (dates, checklist, amounts).';

-- RLS (adjust to match your auth model; example for auth.uid() = technician_id):
-- ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Technicians manage own offerings" ON public.services
--   FOR ALL USING (auth.uid() = technician_id) WITH CHECK (auth.uid() = technician_id);
--
-- ALTER TABLE public.service_history ENABLE ROW LEVEL SECURITY;
-- ... mirror your previous policies on the old `services` table ...
