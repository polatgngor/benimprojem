'use strict';

const { sendPushToTokens } = require('../src/lib/fcm');

async function run() {
  const tokens = [
    'ea6WdNQfSMWKBXNnlmeupT:APA91bEff9jepjJItOJgxbZUHlmFTHa55tnlL0eMis_Wy1yysRfDkzWkU0L0PSDmmiSdzNXtzM9obved4c7zAFg_GgsAakbFjHmMRZBqwA7hOSWG44hS0yI'
  ];

  await sendPushToTokens(
    tokens,
    {
      title: 'Taksiniz Geldi!',
      body: '34TDN39 Plakalı sarı taksi konumdadır!'
    },
    {
      type: 'test',
      foo: 'bar'
    }
  );

  console.log('sendPushToTokens çağrısı bitti, loglarda hata yoksa FCM bağlantısı çalışıyor.');
}

run().catch((e) => {
  console.error('Test push hatası', e);
  process.exit(1);
});