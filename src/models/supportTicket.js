const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const SupportTicket = sequelize.define('SupportTicket', {
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        subject: {
            type: DataTypes.STRING,
            allowNull: false
        },
        status: {
            type: DataTypes.ENUM('open', 'closed', 'answered'),
            defaultValue: 'open'
        }
    }, {
        tableName: 'support_tickets',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: false // Schema doesn't seem to use updated_at, but safe to keep consistent or disable
    });

    return SupportTicket;
};
