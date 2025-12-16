const express = require('express');
const router = express.Router();
const { sequelize } = require('../models');
const { QueryTypes } = require('sequelize');

// Get active announcements
router.get('/', async (req, res) => {
    try {
        const { target_app } = req.query; // 'driver', 'customer', or null for both

        // Ensure table exists or handle error if not, but typically we assume schema exists.
        // Using replacements to prevent SQL injection for target_app
        let query = "SELECT * FROM announcements WHERE is_active = TRUE AND (expires_at IS NULL OR expires_at > NOW())";
        const params = [];

        if (target_app) {
            query += " AND (target_app = ? OR target_app = 'both')";
            params.push(target_app);
        }

        query += " ORDER BY created_at DESC";

        const rows = await sequelize.query(query, {
            replacements: params,
            type: QueryTypes.SELECT
        });

        res.json(rows);
    } catch (error) {
        console.error('Error fetching announcements:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
