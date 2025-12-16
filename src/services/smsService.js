const axios = require('axios');

// MutluCell Credentials (from user request)
// In production, these should be in process.env
const SMS_CONFIG = {
    username: process.env.SMS_USERNAME, // MutluCell username
    password: process.env.SMS_PASSWORD, // MutluCell password
    org: process.env.SMS_ORG,         // MutluCell org/sender ID
    url: 'https://smsgw.mutlucell.com/smsgw-ws/sndblkex'
};

async function sendSms(phone, message) {
    try {
        // Sanitize phone number: remove + if present, ensure it starts with 90 or appropriate format
        // MutluCell usually expects 905xxxxxxxxx or similar. The user example showed "90507..."
        // Let's ensure we just strip non-digits.
        let cleanPhone = phone.replace(/\D/g, '');

        // If it starts with 0 (e.g. 05...), replace with 905...
        if (cleanPhone.startsWith('0')) {
            cleanPhone = '9' + cleanPhone;
        }
        // If it starts with 5... (e.g. 507...), prepend 90
        else if (cleanPhone.startsWith('5')) {
            cleanPhone = '90' + cleanPhone;
        }

        const xmlBody = `<?xml version="1.0" encoding="UTF-8"?>
<smspack ka="${SMS_CONFIG.username}" pwd="${SMS_CONFIG.password}" org="${SMS_CONFIG.org}">
    <mesaj>
        <metin>${message}</metin>
        <nums>${cleanPhone}</nums>
    </mesaj>
</smspack>`;

        const response = await axios.post(SMS_CONFIG.url, xmlBody, {
            headers: {
                'Content-Type': 'text/xml'
            }
        });

        // MutluCell usually returns a transaction ID or error code starting with '$' or just text.
        // We log it for debugging.
        console.log(`[MutluCell] Response for ${cleanPhone}:`, response.data);

        return response.data;

    } catch (error) {
        console.error('[MutluCell] Error sending SMS:', error.message);
        // We don't throw here to prevent crashing the flow, but we might want to know if it failed.
        // For now, logging is enough as this is "fire and forget" or we can return false.
        return null;
    }
}

module.exports = { sendSms };
