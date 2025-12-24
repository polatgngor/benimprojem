require('dotenv').config();
const { sequelize } = require('../models');

async function resetData() {
    try {
        console.log('🔄 Veritabanı sıfırlama işlemi başlatılıyor...');

        // 1. Veritabanı bağlantısını kontrol et
        await sequelize.authenticate();
        console.log('✅ Veritabanı bağlantısı başarılı.');

        // 2. Foreign Key kontrolünü devre dışı bırak (Truncate işlemi için gerekli)
        await sequelize.query('SET FOREIGN_KEY_CHECKS = 0', { raw: true });
        console.log('🔓 Foreign Key kontrolleri geçici olarak kapatıldı.');

        // 3. Tüm tabloları çek ve temizle
        const models = Object.values(sequelize.models);

        console.log(`🗑️  Toplam ${models.length} tablo temizlenecek...`);

        for (const model of models) {
            const tableName = model.getTableName();
            process.stdout.write(`   - Tablo temizleniyor: ${tableName}... `);

            // Truncate (Tabloyu boşalt ve ID'leri sıfırla)
            await model.destroy({ truncate: true, cascade: false });

            process.stdout.write('✅ TAMAM\n');
        }

        // 4. Redis'i temizle (Opsiyonel ama önerilir)
        // Eğer redisClient varsa kullanılabilir, yoksa bu adımı atlıyoruz.
        try {
            const redis = require('../utils/redisClient');
            if (redis && redis.status === 'ready') {
                await redis.flushall();
                console.log('🧹 Redis önbelleği temizlendi.');
            }
        } catch (e) {
            console.log('⚠️  Redis temizlenemedi veya modül bulunamadı (Önemsiz).');
        }

        // 5. Foreign Key kontrolünü tekrar aç
        await sequelize.query('SET FOREIGN_KEY_CHECKS = 1', { raw: true });
        console.log('🔒 Foreign Key kontrolleri tekrar açıldı.');

        console.log('🎉 İŞLEM BAŞARILI: Veritabanı tamamen sıfırlandı (Şema korundu).');
        process.exit(0);

    } catch (error) {
        console.error('❌ HATA:', error);
        process.exit(1);
    }
}

// Kullanıcıdan onay iste (yanlışlıkla çalıştırmaya karşı)
const readline = require('readline').createInterface({
    input: process.stdin,
    output: process.stdout
});

readline.question('⚠️  DİKKAT: Bu işlem TÜM VERİLERİ SİLECEKTİR! Onaylıyor musunuz? (evet/hayir): ', (answer) => {
    if (answer.toLowerCase() === 'evet') {
        resetData();
    } else {
        console.log('❌ İşlem iptal edildi.');
        process.exit(0);
    }
    readline.close();
});
