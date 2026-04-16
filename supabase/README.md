Supabase Midtrans integration (Edge Functions)
=============================================

This folder contains example Supabase Edge Functions and SQL migrations to integrate Midtrans Snap payments without requiring Firebase Blaze billing.

Files
- `functions/create-midtrans/index.ts` — Edge Function that creates a Midtrans Snap transaction and inserts a `payments` row.
- `functions/midtrans-webhook/index.ts` — Edge Function to receive Midtrans notifications and update `payments` / `donations` / `campaigns`.
- `migrations/00X_*.sql` — SQL migrations to create `campaigns`, `payments`, and `donations` tables in Postgres.

Deployment steps (overview)
1. Install Supabase CLI and login: `supabase login`.
2. Initialize / connect to your Supabase project: `supabase link --project-ref <your-ref>`.
3. Set required secrets (do NOT commit these). The Supabase CLI disallows secret names starting with `SUPABASE_`, so use the names below:
   - `supabase secrets set MIDTRANS_SERVER_KEY "<your-midtrans-server-key>"`
   - `supabase secrets set SERVICE_ROLE_KEY "<service-role-key>"`
   - `supabase secrets set PROJECT_URL "https://<ref>.supabase.co"`
   - The functions will read `PROJECT_URL` and `SERVICE_ROLE_KEY` (they also fall back to `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` for compatibility).

4. Apply SQL migrations to create tables: use the Supabase SQL editor or `supabase db push` / `supabase db remote commit` depending on your workflow.

5. Deploy functions:
   ```bash
   supabase functions deploy create-midtrans --project-ref <your-ref>
   supabase functions deploy midtrans-webhook --project-ref <your-ref>
   ```

6. Configure Midtrans merchant dashboard webhook pointing to:
   `https://<ref>.functions.supabase.co/midtrans-webhook`

7. In the Flutter app, set `lib/week4_payment_config.dart` `functionsBaseUrl` to the Supabase functions base URL, e.g. `https://<ref>.functions.supabase.co`.

Notes
- These examples use the Supabase REST API and Service Role Key from inside the Edge Function to write to Postgres. Keep the service role key secret.
- You can adapt the functions to call Firestore (instead of updating Supabase `campaigns`) if you prefer to keep campaign data in Firestore; that requires a Firebase service account and additional security setup.
