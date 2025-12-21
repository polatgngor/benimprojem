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

  // Parallel Send for Speed (ZINK Effect)
  const promises = tokens.map(async (token) => {
    const message = {
      token,
      notification,
      data,
      android: {
        priority: 'high',
        ttl: 0,
        notification: {
          priority: 'max', // MAX AGGRESSION
          channelId: 'incoming_request_channel',
          visibility: 'public',
          defaultSound: true,
          defaultVibrateTimings: true,
          defaultLightSettings: true
        }
      },
      apns: {
        headers: {
          'apns-priority': '10', // Immediate
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            contentAvailable: true,
            priority: '10'
          }
        }
      }
    };

    try {
      const response = await admin.messaging().send(message);
      successCount++;
      return { token, success: true, response };
    } catch (err) {
      failureCount++;
      console.error('[fcm] send error for token', token, err.message || err);
      return { token, success: false, error: err };
    }
  });

  await Promise.all(promises);

  console.log('[fcm] sendPushToTokens finished', successCount, 'success', failureCount, 'failure');
}

module.exports = {
  sendPushToTokens
};