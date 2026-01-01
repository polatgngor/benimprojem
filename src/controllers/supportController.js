const { SupportTicket, SupportMessage } = require('../models');
const socketProvider = require('../lib/socketProvider');
const { hasProfanity } = require('../utils/profanityFilter');

// Create a new ticket
exports.createTicket = async (req, res) => {
    const { subject, message } = req.body;
    const userId = req.user.userId;

    if (!subject || !message) {
        return res.status(400).json({ error: 'Subject and message are required.' });
    }

    try {
        // 1. Validate Profanity
        if (hasProfanity(subject) || hasProfanity(message)) {
            return res.status(400).json({ error: 'Mesajınız veya konunuz uygunsuz içerik barındırıyor.' });
        }

        // 1. Create Ticket
        const ticket = await SupportTicket.create({
            user_id: userId,
            subject,
            status: 'open'
        });

        // 2. Add First Message
        await SupportMessage.create({
            ticket_id: ticket.id,
            sender_id: userId,
            sender_type: 'user',
            message
        });

        res.status(201).json({ message: 'Ticket created successfully.', ticketId: ticket.id });
    } catch (error) {
        console.error('Create Ticket Error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

// Get tickets for the logged user
exports.getMyTickets = async (req, res) => {
    const userId = req.user.userId;
    try {
        const tickets = await SupportTicket.findAll({
            where: { user_id: userId },
            order: [['created_at', 'DESC']]
        });
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
        const ticket = await SupportTicket.findByPk(ticketId);
        if (!ticket) return res.status(404).json({ error: 'Ticket not found.' });
        if (ticket.user_id !== userId) return res.status(403).json({ error: 'Unauthorized.' });

        const messages = await SupportMessage.findAll({
            where: { ticket_id: ticketId },
            order: [['created_at', 'ASC']]
        });
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
        const ticket = await SupportTicket.findByPk(ticketId);
        if (!ticket) return res.status(404).json({ error: 'Ticket not found.' });
        if (ticket.user_id !== userId) return res.status(403).json({ error: 'Unauthorized.' });

        if (hasProfanity(message)) {
            return res.status(400).json({ error: 'Mesajınız uygunsuz içerik barındırıyor.' });
        }

        // Insert Message
        const newMsg = await SupportMessage.create({
            ticket_id: ticketId,
            sender_id: userId,
            sender_type: 'user',
            message
        });

        // Emit Real-time Event
        const io = socketProvider.getIO();
        if (io) {
            io.to(`ticket_${ticketId}`).emit('new_support_message', newMsg.toJSON());
        }

        res.status(201).json(newMsg);
    } catch (error) {
        console.error('Send Message Error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};

