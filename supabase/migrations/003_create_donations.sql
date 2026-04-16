-- Donations table to record settled donations
CREATE TABLE IF NOT EXISTS public.donations (
  id serial PRIMARY KEY,
  user_id text,
  campaign_id text,
  amount integer,
  order_id text,
  created_at timestamptz DEFAULT now()
);
