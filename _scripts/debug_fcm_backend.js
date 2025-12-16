require('dotenv').config();
const { UserDevice } = require('./src/models');
const { sendPushToTokens } = require('./src/lib/fcm');

// Usage: node debug_fcm_backend.js <user_id>

async function main() {
    const userId = process.argv[2];
    if (!userId) {
        console.log("Usage: node debug_fcm_backend.js <user_id>");
        process.exit(1);
    }

    console.log(`Checking devices for User ID: ${userId}...`);

    try {
        const devices = await UserDevice.findAll({ where: { user_id: userId } });

        if (devices.length === 0) {
            console.log("❌ No devices found in 'user_devices' table for this user.");
            console.log("The app might not have registered the token yet, or the user ID is wrong.");
        } else {
            console.log(`✅ Found ${devices.length} device(s):`);
            const tokens = devices.map(d => d.device_token);

            devices.forEach((d, i) => {
                console.log(`   [${i}] Platform: ${d.platform}, Token: ${d.device_token.substring(0, 20)}...`);
            });

            console.log("\nAttempting to send push notification to these tokens...");

            await sendPushToTokens(
                tokens,
                {
                    title: "Backend Debug Test",
                    body: "If you see this, the backend logic is working!"
                },
                {
                    type: "debug_test"
                }
            );
        }

    } catch (error) {
        console.error("❌ Error:", error);
    } finally {
        process.exit(0);
    }
}

main();
