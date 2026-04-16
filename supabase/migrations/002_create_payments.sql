-- Payments table to track Midtrans orders and status
CREATE TABLE IF NOT EXISTS public.payments (
  order_id text PRIMARY KEY,
  uid text,
  campaign_id text,
  amount integer,
  status text,
  midtrans jsonb,
  midtrans_payload jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
