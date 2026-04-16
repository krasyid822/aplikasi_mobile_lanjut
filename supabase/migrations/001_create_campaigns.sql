-- Create campaigns table for Supabase (optional migration if moving data from Firestore)
CREATE TABLE IF NOT EXISTS public.campaigns (
  id text PRIMARY KEY,
  title text,
  description text,
  target integer DEFAULT 0,
  collected integer DEFAULT 0,
  image_url text,
  created_at timestamptz DEFAULT now()
);
