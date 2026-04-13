-- Expected service interval in days (e.g. 90, 120) for reminder logic.

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS service_frequency_days integer NOT NULL DEFAULT 120;

COMMENT ON COLUMN public.customers.service_frequency_days IS 'Days between RO services for this customer';
