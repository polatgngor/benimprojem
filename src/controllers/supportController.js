const db = require('../db');
const socketProvider = require('../lib/socketProvider');

// Create a new ticket
exports.createTicket = async (req, res) => {
    const { subject, message } = req.body;
    const userId = req.user.userId;

    if (!subject || !message) {
        return res.status(400).json({ error: 'Subject and message are required.' });
    }

    try {
        // 1. Create Ticket
        const [ticketResult] = await db.query(
            'INSERT INTO support_tickets (user_id, subject, status) VALUES (?, ?, ?)',
            [userId, subject, 'open']
        );
        const ticketId = ticketResult.insertId;

        // 2. Add First Message
        await db.query(
            'INSERT INTO support_messages (ticket_id, sender_id, sender_type, message) VALUES (?, ?, ?, ?)',
            [ticketId, userId, 'user', message]
        );

        res.status(201).json({ message: 'Ticket created successfully.', ticketId });
    } catch (error) {
        console.error('Create Ticket Error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

// Get tickets for the logged user
exports.getMyTickets = async (req, res) => {
    const userId = req.user.userId;
    try {
        const [tickets] = await db.query(
            'SELECT * FROM support_tickets WHERE user_id = ? ORDER BY created_at DESC',
            [userId]
        );
        res.json(tickets);
    } catch (error) {
        console.error('Get Tickets Error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

// Get messages for a specific ticket
exports.getTicketMessages = async (req, res) => {
    const userId = req.user.userId;
    const { ticketId } = req.params;

    try {
        // Check if ticket belongs to user (Security)
        const [ticket] = await db.query('SELECT user_id FROM support_tickets WHERE id = ?', [ticketId]);
        if (ticket.length === 0) return res.status(404).json({ error: 'Ticket not found.' });
        if (ticket[0].user_id !== userId) return res.status(403).json({ error: 'Unauthorized.' });

        const [messages] = await db.query(
            'SELECT * FROM support_messages WHERE ticket_id = ? ORDER BY created_at ASC',
            [ticketId]
        );
        res.json(messages);
    } catch (error) {
        console.error('Get Messages Error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

// Send a message
exports.sendMessage = async (req, res) => {
    const userId = req.user.userId;
    const { ticketId } = req.params;
    const { message } = req.body;

    if (!message) return res.status(400).json({ error: 'Message cannot be empty.' });

    try {
        // Verify ownership
        const [ticket] = await db.query('SELECT * FROM support_tickets WHERE id = ?', [ticketId]);
        if (ticket.length === 0) return res.status(404).json({ error: 'Ticket not found.' });
        if (ticket[0].user_id !== userId) return res.status(403).json({ error: 'Unauthorized.' });

        // Insert Message
        const [result] = await db.query(
            'INSERT INTO support_messages (ticket_id, sender_id, sender_type, message) VALUES (?, ?, ?, ?)',
            [ticketId, userId, 'user', message]
        );

        // If ticket was closed/answered, maybe reopen it? (Optional logic, keeping simple for now)

        // Fetch the new message to emit
        const [newMsg] = await db.query('SELECT * FROM support_messages WHERE id = ?', [result.insertId]);

        // Emit Real-time Event
        const io = socketProvider.getIO();
        if (io) {
            io.to(`ticket_${ticketId}`).emit('new_support_message', newMsg[0]);
        }

        res.status(201).json(newMsg[0]);
    } catch (error) {
        console.error('Send Message Error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};
