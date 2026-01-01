const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const SupportMessage = sequelize.define('SupportMessage', {
        ticket_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        sender_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        sender_type: {
            type: DataTypes.ENUM('user', 'admin', 'system'),
            defaultValue: 'user'
        },
        message: {
            type: DataTypes.TEXT,
            allowNull: false
        }
    }, {
        tableName: 'support_messages',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: false
    });

    return SupportMessage;
};
