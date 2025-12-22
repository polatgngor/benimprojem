require('dotenv').config();
const { sequelize } = require('./src/models');

async function resetRides() {
    try {
        console.log('Veritabanına bağlanılıyor...');
        await sequelize.authenticate();
        console.log('Bağlantı başarılı.');

        // Foreign Key kontrolünü geçici olarak kapat
        await sequelize.query('SET FOREIGN_KEY_CHECKS = 0');

        console.log('RideRequests tablosu temizleniyor...');
        await sequelize.query('TRUNCATE TABLE ride_requests');

        console.log('Rides tablosu temizleniyor...');
        await sequelize.query('TRUNCATE TABLE rides');

        // Foreign Key kontrolünü tekrar aç
        await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');

        console.log('✅ TÜM SÜRÜŞLER VE ÇAĞRILAR SİLİNDİ. SÜRÜCÜLER ARTIK BOŞA DÜŞTÜ.');
        process.exit(0);
    } catch (error) {
        console.error('Hata oluştu:', error);
        process.exit(1);
    }
}

resetRides();
