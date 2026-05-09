const functions = require('firebase-functions');
const admin = require('firebase-admin');
const emailFunctions = require('./email_notifications');

if (!admin.apps.length) {
  admin.initializeApp();
}

Object.assign(exports, emailFunctions);

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



