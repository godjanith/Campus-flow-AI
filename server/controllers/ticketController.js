import Ticket from '../models/Ticket.js';
import { analyzeIncident, generateSafetyChatReply } from '../services/aiService.js';
import { seedDemoIncidents } from '../utils/seeder.js';

export const createTicket = async (req, res) => {
  try {
    const {
      title,
      description,
      building,
      lat,
      lng,
      reporterName,
      reporterRegNo,
    } = req.body;

    if (!title || !description) {
      return res.status(400).json({ message: 'Title and description are required.' });
    }

    const parsedLat = lat && !isNaN(parseFloat(lat)) ? parseFloat(lat) : 13.1718;
    const parsedLng = lng && !isNaN(parseFloat(lng)) ? parseFloat(lng) : 77.5361;

    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;
    const imagePath = req.file ? req.file.path : null;
    const mimeType = req.file ? req.file.mimetype : null;

    const aiResult = await analyzeIncident({
      title,
      description,
      building: building || 'Engineering Block A',
      imagePath,
      mimeType,
    });

    const ticketCode = `CF-${Math.floor(100000 + Math.random() * 900000)}`;

    const ticket = await Ticket.create({
      ticketCode,
      title,
      description,
      building: building || 'Engineering Block A',
      location: { lat: parsedLat, lng: parsedLng },
      imageUrl,
      category: aiResult.category,
      severity: aiResult.severity,
      aiSummary: aiResult.aiSummary,
      estimatedResolutionTime: aiResult.estimatedResolutionTime,
      safetyAdvisory: aiResult.safetyAdvisory,
      triageEngineUsed: aiResult.triageEngineUsed,
      status: 'OPEN',
      reportedBy: {
        name: reporterName || 'Janith V C',
        regNo: reporterRegNo || '20252MCA0318',
      },
      timeline: [
        {
          status: 'OPEN',
          note: `Reported & triaged as ${aiResult.severity} (${aiResult.category}) via ${aiResult.triageEngineUsed}.`,
          timestamp: new Date(),
        },
      ],
    });

    const io = req.app.get('io');
    if (io) {
      io.emit('ticket:created', ticket);
    }

    return res.status(201).json(ticket);
  } catch (error) {
    console.error('[Create Ticket Error]', error);
    return res.status(500).json({ message: error.message });
  }
};

export const getTickets = async (req, res) => {
  try {
    const tickets = await Ticket.find().sort({ createdAt: -1 });
    return res.json(tickets);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};

export const updateTicketStatus = async (req, res) => {
  try {
    const { status, note } = req.body;
    const validStatuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Invalid status value.' });
    }

    const ticket = await Ticket.findById(req.params.id);
    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found.' });
    }

    ticket.status = status;
    const defaultNotes = {
      OPEN: 'Ticket reopened by Campus Operations.',
      IN_PROGRESS: 'Field engineering crew dispatched to location.',
      RESOLVED: 'Issue verified resolved and closed by Admin Command.',
    };

    ticket.timeline.push({
      status,
      note: note || defaultNotes[status],
      timestamp: new Date(),
    });

    const updatedTicket = await ticket.save();

    const io = req.app.get('io');
    if (io) {
      io.emit('ticket:updated', updatedTicket);
    }

    return res.json(updatedTicket);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};

export const deleteTicket = async (req, res) => {
  try {
    const ticket = await Ticket.findById(req.params.id);
    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found.' });
    }
    await ticket.deleteOne();

    const io = req.app.get('io');
    if (io) {
      io.emit('ticket:deleted', req.params.id);
    }

    return res.json({ message: 'Ticket deleted successfully', id: req.params.id });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};

export const seedDemoData = async (req, res) => {
  try {
    const inserted = await seedDemoIncidents();
    const allTickets = await Ticket.find().sort({ createdAt: -1 });

    const io = req.app.get('io');
    if (io) {
      io.emit('tickets:seeded', allTickets);
    }

    return res.status(201).json({
      message: `Successfully seeded ${inserted.length} campus incidents.`,
      tickets: allTickets,
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};

export const chatWithSafetyCopilot = async (req, res) => {
  try {
    const { message } = req.body;
    if (!message || !message.trim()) {
      return res.status(400).json({ message: 'Message is required.' });
    }
    const result = await generateSafetyChatReply(message);
    return res.json(result);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};