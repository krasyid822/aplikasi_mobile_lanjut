import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// Supabase Edge Function: create-midtrans
// - Expects POST JSON { campaignId, amount, uid?, email? }
// - Calls Midtrans Snap API (sandbox)
// - Inserts a `payments` row in Supabase Postgres via REST using SERVICE ROLE KEY
// - Returns { orderId, redirect_url, token }

serve(async (req: Request) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });

  const MIDTRANS_SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY') || '';
  // Use non-reserved env names for secrets. Prefer these names but fall back
  // to older names for compatibility.
  const PROJECT_URL = Deno.env.get('PROJECT_URL') || Deno.env.get('SUPABASE_URL') || '';
  const SERVICE_ROLE_KEY = Deno.env.get('SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

  if (!MIDTRANS_SERVER_KEY || !PROJECT_URL || !SERVICE_ROLE_KEY) {
    return new Response('Missing configuration', { status: 500 });
  }

  let body: any;
  try {
    body = await req.json();
  } catch (_) {
    return new Response('Invalid JSON', { status: 400 });
  }

  const { campaignId, amount, uid, email } = body || {};
  if (!campaignId || !amount) return new Response('campaignId and amount are required', { status: 400 });

  const grossAmount = Number(amount);
  const orderId = `donation_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;

  const transactionPayload = {
    transaction_details: { order_id: orderId, gross_amount: grossAmount },
    item_details: [
      { id: campaignId, price: grossAmount, quantity: 1, name: `Donation for ${campaignId}` },
    ],
    customer_details: { email: email || '' },
  };

  // Call Midtrans Snap (sandbox)
  const auth = 'Basic ' + btoa(MIDTRANS_SERVER_KEY + ':');
  try {
    const resp = await fetch('https://app.sandbox.midtrans.com/snap/v1/transactions', {
      method: 'POST',
      headers: { 'Authorization': auth, 'Content-Type': 'application/json' },
      body: JSON.stringify(transactionPayload),
    });

    if (!resp.ok) {
      const txt = await resp.text();
      console.error('Midtrans error', resp.status, txt);
      return new Response('Midtrans error', { status: 502 });
    }

    const result = await resp.json();

    // Insert payment record into Supabase Postgres via REST API
    const insertResp = await fetch(`${PROJECT_URL}/rest/v1/payments`, {
      method: 'POST',
      headers: {
        'apikey': SERVICE_ROLE_KEY,
        'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      // Insert expects an array of rows
      body: JSON.stringify([{ order_id: orderId, uid: uid || null, campaign_id: campaignId, amount: grossAmount, status: 'pending', midtrans: result }]),
    });

    if (!insertResp.ok) {
      const txt = await insertResp.text();
      console.error('Supabase insert error', insertResp.status, txt);
      // proceed but warn
    }

    const payload = { orderId, redirect_url: result.redirect_url, token: result.token };
    return new Response(JSON.stringify(payload), { status: 200, headers: { 'Content-Type': 'application/json' } });
  } catch (err) {
    console.error('create-midtrans error', err);
    return new Response('Internal error', { status: 500 });
  }
});
