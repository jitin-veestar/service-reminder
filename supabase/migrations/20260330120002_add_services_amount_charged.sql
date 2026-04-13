-- Amount billed for this service visit (reports / history).

ALTER TABLE public.services
  ADD COLUMN IF NOT EXISTS amount_charged double precision NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.services.amount_charged IS 'Charge for this RO service visit';
