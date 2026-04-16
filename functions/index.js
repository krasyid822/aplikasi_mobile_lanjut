const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const crypto = require('crypto');

// Read Midtrans server key from environment. Use Firebase Functions Secrets
// (set with `firebase functions:secrets:set MIDTRANS_SERVER_KEY`) and bind
// the secret to functions via `runWith({ secrets: ['MIDTRANS_SERVER_KEY'] })`.
const MIDTRANS_SERVER_KEY = process.env.MIDTRANS_SERVER_KEY;
if (!MIDTRANS_SERVER_KEY) {
  console.warn('MIDTRANS_SERVER_KEY is not set. createMidtransTransaction and midtransWebhook will fail until configured.');
}

/**
 * Send a topic notification when a new campaign is created.
 * All devices subscribed to topic 'campaigns' will receive this.
 */
exports.onCampaignCreated = functions.firestore
  .document('campaigns/{campaignId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const title = data.title || 'Campaign baru';
    const campaignId = context.params.campaignId;

    const message = {
      notification: {
        title: 'Campaign Baru',
        body: title,
      },
      data: {
        campaignId: campaignId,
      },
      topic: 'campaigns',
    };

    try {
      await admin.messaging().send(message);
      console.log('Campaign notification sent for', campaignId);
    } catch (err) {
      console.error('Error sending campaign notification', err);
    }
    return null;
  });


  /**
   * Create a Midtrans Snap transaction and persist a payment record in Firestore.
   * Expects Authorization: Bearer <firebase-id-token> header to identify the user.
   * Request body: { campaignId: string, amount: number }
   * Response: { orderId, redirect_url, token }
   */
  exports.createMidtransTransaction = functions.runWith({ secrets: ['MIDTRANS_SERVER_KEY'] }).https.onRequest(async (req, res) => {
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');
    if (!MIDTRANS_SERVER_KEY) return res.status(500).send('Midtrans not configured');

    // Verify Firebase ID token from Authorization header
    const authHeader = req.get('Authorization') || '';
    const match = authHeader.match(/^Bearer\s+(.*)$/i);
    if (!match) return res.status(401).send('Missing Authorization header');
    const idToken = match[1];
    let uid = null;
    let userEmail = null;
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      uid = decoded.uid;
      userEmail = decoded.email || null;
    } catch (err) {
      console.error('Invalid ID token', err);
      return res.status(401).send('Invalid ID token');
    }

    const { campaignId, amount } = req.body || {};
    if (!campaignId || !amount) return res.status(400).send('campaignId and amount are required');

    const grossAmount = parseInt(amount, 10) || 0;

    // Read campaign info for item details
    let campaignTitle = 'Campaign';
    try {
      const camp = await admin.firestore().collection('campaigns').doc(campaignId).get();
      if (camp.exists) {
        const cd = camp.data() || {};
        campaignTitle = cd.title || campaignTitle;
      }
    } catch (e) {
      console.warn('Error fetching campaign', e);
    }

    const orderId = `donation_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;

    // Create a payment record (status: pending)
    const paymentRef = admin.firestore().collection('payments').doc(orderId);
    await paymentRef.set({
      orderId,
      uid,
      email: userEmail || null,
      campaignId,
      amount: grossAmount,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Build Midtrans Snap payload
    const payload = {
      transaction_details: { order_id: orderId, gross_amount: grossAmount },
      item_details: [
        { id: campaignId, price: grossAmount, quantity: 1, name: campaignTitle },
      ],
      customer_details: { email: userEmail || '' },
    };

    try {
      const resp = await fetch('https://app.sandbox.midtrans.com/snap/v1/transactions', {
        method: 'POST',
        headers: {
          'Authorization': 'Basic ' + Buffer.from(MIDTRANS_SERVER_KEY + ':').toString('base64'),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (!resp.ok) {
        const text = await resp.text();
        console.error('Midtrans error', resp.status, text);
        return res.status(502).send('Midtrans error');
      }

      const result = await resp.json();
      // Save midtrans response for later verification/debug
      await paymentRef.set({ midtrans: result }, { merge: true });

      return res.json({ orderId, redirect_url: result.redirect_url, token: result.token });
    } catch (err) {
      console.error('Error calling Midtrans', err);
      return res.status(500).send('Error calling Midtrans');
    }
  });


  /**
   * Midtrans webhook / notification handler.
   * Midtrans will POST transaction notifications here. We verify signature and
   * update the corresponding `payments` document and, on successful settlement/capture,
   * create a donation record and update campaign collected amount.
   */
  exports.midtransWebhook = functions.runWith({ secrets: ['MIDTRANS_SERVER_KEY'] }).https.onRequest(async (req, res) => {
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');
    if (!MIDTRANS_SERVER_KEY) return res.status(500).send('Midtrans not configured');

    const body = req.body || {};
    const { order_id: orderId, status_code: statusCode, gross_amount: grossAmount, signature_key: signatureKey, transaction_status: transactionStatus } = body;

    if (!orderId || !statusCode || !grossAmount || !signatureKey) {
      console.warn('Invalid midtrans payload', body);
      return res.status(400).send('Invalid payload');
    }

    const toHash = `${orderId}${statusCode}${grossAmount}${MIDTRANS_SERVER_KEY}`;
    const computed = crypto.createHash('sha512').update(toHash).digest('hex');
    if (computed !== signatureKey) {
      console.warn('Signature mismatch', { computed, signatureKey });
      return res.status(400).send('Invalid signature');
    }

    const paymentRef = admin.firestore().collection('payments').doc(orderId);
    const paymentSnap = await paymentRef.get();
    const payment = paymentSnap.exists ? (paymentSnap.data() || {}) : null;

    // Update payment document with the notification payload
    await paymentRef.set({ status: transactionStatus || statusCode, midtransPayload: body, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });

    try {
      // If transaction is successful and payment record exists, create donation and update campaign
      if (payment && (transactionStatus === 'settlement' || transactionStatus === 'capture')) {
        const uid = payment.uid || '';
        const campaignId = payment.campaignId;
        const amount = payment.amount || parseInt(grossAmount, 10);

        if (campaignId && amount) {
          const campaignRef = admin.firestore().collection('campaigns').doc(campaignId);
          await admin.firestore().runTransaction(async (t) => {
            const campSnap = await t.get(campaignRef);
            const current = (campSnap.exists && (campSnap.data().collected || 0)) || 0;
            t.update(campaignRef, { collected: (current || 0) + amount });
            const donationRef = admin.firestore().collection('donations').doc();
            t.set(donationRef, {
              userId: uid,
              campaignId,
              amount,
              date: admin.firestore.FieldValue.serverTimestamp(),
              orderId,
            });
            t.update(paymentRef, { status: transactionStatus, processedAt: admin.firestore.FieldValue.serverTimestamp() });
          });
        }
      }
    } catch (err) {
      console.error('Error handling midtrans webhook', err);
      // continue and acknowledge to midtrans to avoid retries; consider reprocessing later
    }

    return res.status(200).send('OK');
  });


/**
 * Send notifications when a donation is created.
 * Sends to the donor's device(s) and to the campaign owner if available.
 */
exports.onDonationCreated = functions.firestore
  .document('donations/{donationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const donorId = data.userId;
    const campaignId = data.campaignId;
    const amount = data.amount;
    const donationId = context.params.donationId;

    // Retrieve campaign info
    let campaignTitle = 'Campaign';
    let ownerId = null;
    if (campaignId) {
      const campaignSnap = await admin
        .firestore()
        .collection('campaigns')
        .doc(campaignId)
        .get();
      if (campaignSnap.exists) {
        const cd = campaignSnap.data();
        campaignTitle = (cd && cd.title) || campaignTitle;
        ownerId = (cd && cd.ownerId) || null;
      }
    }

    const donorMessage = {
      notification: {
        title: 'Donasi Berhasil',
        body: `Donasi Anda ${amount} untuk ${campaignTitle} berhasil.`,
      },
      data: {
        donationId,
        campaignId: campaignId || '',
      },
    };

    // Send to donor tokens
    if (donorId) {
      const userDoc = await admin.firestore().collection('users').doc(donorId).get();
      const tokens = (userDoc.exists && userDoc.data().fcmTokens) || [];
      if (tokens && tokens.length > 0) {
        try {
          const res = await admin.messaging().sendMulticast({
            tokens,
            notification: donorMessage.notification,
            data: donorMessage.data,
          });
          console.log('Donation notification sent to donor:', res.successCount);
        } catch (err) {
          console.error('Error sending donation notification to donor', err);
        }
      }
    }

    // Notify campaign owner (if different from donor)
    if (ownerId && ownerId !== donorId) {
      const ownerDoc = await admin.firestore().collection('users').doc(ownerId).get();
      const ownerTokens = (ownerDoc.exists && ownerDoc.data().fcmTokens) || [];
      if (ownerTokens && ownerTokens.length > 0) {
        const ownerMsg = {
          notification: {
            title: 'Donasi Masuk',
            body: `Ada donasi ${amount} untuk campaign ${campaignTitle}.`,
          },
          data: {
            donationId,
            campaignId: campaignId || '',
          },
        };
        try {
          const res = await admin.messaging().sendMulticast({
            tokens: ownerTokens,
            notification: ownerMsg.notification,
            data: ownerMsg.data,
          });
          console.log('Donation notification sent to owner:', res.successCount);
        } catch (err) {
          console.error('Error sending donation notification to owner', err);
        }
      }
    }

    return null;
  });
