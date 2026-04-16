import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// Supabase Edge Function: midtrans-webhook
// - Midtrans will POST transaction notifications (JSON)
// - Verify signature: sha512(order_id + status_code + gross_amount + server_key)
// - Update `payments` row and, on settlement/capture, insert into `donations` and
//   update `campaigns.collected`.

function toHex(buffer: ArrayBuffer) {
  return Array.from(new Uint8Array(buffer)).map(b => b.toString(16).padStart(2, '0')).join('');
}

serve(async (req: Request) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });

  const MIDTRANS_SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY') || '';
  const PROJECT_URL = Deno.env.get('PROJECT_URL') || Deno.env.get('SUPABASE_URL') || '';
  const SERVICE_ROLE_KEY = Deno.env.get('SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

  if (!MIDTRANS_SERVER_KEY || !PROJECT_URL || !SERVICE_ROLE_KEY) {
    return new Response('Missing configuration', { status: 500 });
  }

  let payload: any;
  try {
    payload = await req.json();
  } catch (e) {
    console.warn('Invalid JSON in webhook', e);
    return new Response('Invalid JSON', { status: 400 });
  }

  const { order_id: orderId, status_code: statusCode, gross_amount: grossAmount, signature_key: signatureKey, transaction_status: transactionStatus } = payload || {};

  if (!orderId || !statusCode || !grossAmount || !signatureKey) {
    console.warn('Invalid midtrans payload', payload);
    return new Response('Invalid payload', { status: 400 });
  }

  const toHash = `${orderId}${statusCode}${grossAmount}${MIDTRANS_SERVER_KEY}`;
  const digest = await crypto.subtle.digest('SHA-512', new TextEncoder().encode(toHash));
  const computed = toHex(digest);
  if (computed !== signatureKey) {
    console.warn('Signature mismatch', { computed, signatureKey });
    return new Response('Invalid signature', { status: 400 });
  }

  try {
    // Update payment status in Supabase
    await fetch(`${PROJECT_URL}/rest/v1/payments?order_id=eq.${encodeURIComponent(orderId)}`, {
      method: 'PATCH',
      headers: {
        'apikey': SERVICE_ROLE_KEY,
        'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ status: transactionStatus || statusCode, midtrans_payload: payload, updated_at: new Date().toISOString() }),
    });

    // If settled/capture, create donation and update campaign's collected
    if (transactionStatus === 'settlement' || transactionStatus === 'capture') {
      // Fetch payment row to get uid, campaign_id, amount
      const paymentResp = await fetch(`${PROJECT_URL}/rest/v1/payments?order_id=eq.${encodeURIComponent(orderId)}&select=*`, {
        headers: {
          'apikey': SERVICE_ROLE_KEY,
          'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
        },
      });
      const payments = await paymentResp.json();
      const payment = Array.isArray(payments) && payments.length > 0 ? payments[0] : null;
      if (payment) {
        const uid = payment.uid || null;
        const campaignId = payment.campaign_id;
        const amount = payment.amount || parseInt(grossAmount, 10);

        // Insert donation
        await fetch(`${PROJECT_URL}/rest/v1/donations`, {
          method: 'POST',
          headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify([{ user_id: uid, campaign_id: campaignId, amount: amount, order_id: orderId }]),
        });

        // Read current campaign collected and update
        const campResp = await fetch(`${PROJECT_URL}/rest/v1/campaigns?id=eq.${encodeURIComponent(campaignId)}&select=collected`, {
          headers: { 'apikey': SERVICE_ROLE_KEY, 'Authorization': `Bearer ${SERVICE_ROLE_KEY}` },
        });
        const camps = await campResp.json();
        const current = Array.isArray(camps) && camps.length > 0 ? (camps[0].collected || 0) : 0;
        const newCollected = (Number(current) || 0) + Number(amount || 0);

        await fetch(`${PROJECT_URL}/rest/v1/campaigns?id=eq.${encodeURIComponent(campaignId)}`, {
          method: 'PATCH',
          headers: {
            'apikey': SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ collected: newCollected }),
        });
      }
    }
  } catch (err) {
    console.error('Error handling midtrans webhook', err);
    // Return 200 to acknowledge Midtrans (avoid retries), but consider logging/alerting
  }

  return new Response('OK', { status: 200 });
});
