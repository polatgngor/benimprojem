const admin = require('firebase-admin');
const path = require('path');

let appInitialized = false;

function initFirebase() {
  if (appInitialized) return;
  try {
    const serviceAccountPath =
      process.env.FIREBASE_SERVICE_ACCOUNT_PATH || path.join(__dirname, '../../firebase-service-account.json');
    const serviceAccount = require(serviceAccountPath);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    appInitialized = true;
    console.log('[fcm] Firebase admin initialized');
  } catch (err) {
    console.error('[fcm] Failed to initialize firebase-admin', err.message || err);
  }
}

/**
 * tokens: string[] (FCM registration tokens)
 * notification: { title: string, body: string }
 * data: key/value string map (opsiyonel)
 */
async function sendPushToTokens(tokens, notification, data = {}) {
  if (!tokens || tokens.length === 0) return;

  initFirebase();
  if (!appInitialized) {
    console.warn('[fcm] Not initialized, cannot send push');
    return;
  }

  // sendMulticast bazı sürümlerde yok; bu yüzden token başına send kullanıyoruz
  let successCount = 0;
  let failureCount = 0;

  for (const token of tokens) {
    const message = {
      token,
      notification,
      data
    };

    try {
      const response = await admin.messaging().send(message);
      successCount++;
      console.log('[fcm] send result for token', token, '=>', response);
    } catch (err) {
      failureCount++;
      console.error('[fcm] send error for token', token, err.message || err);
    }
  }

  console.log('[fcm] sendPushToTokens finished', successCount, 'success', failureCount, 'failure');
}

module.exports = {
  sendPushToTokens
};