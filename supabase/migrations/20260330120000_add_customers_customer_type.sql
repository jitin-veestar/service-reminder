-- App expects `customers.customer_type` with values `amc` or `one_time`
-- (see CustomerDto in lib/features/customers/data/dtos/customer_dto.dart).

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS customer_type text NOT NULL DEFAULT 'one_time';

ALTER TABLE public.customers
  DROP CONSTRAINT IF EXISTS customers_customer_type_check;

ALTER TABLE public.customers
  ADD CONSTRAINT customers_customer_type_check
  CHECK (customer_type IN ('amc', 'one_time'));

COMMENT ON COLUMN public.customers.customer_type IS 'amc = annual maintenance contract; one_time = pay per visit';
