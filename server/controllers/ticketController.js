import mongoose from 'mongoose';
import Ticket from '../models/Ticket.js';
import { analyzeIncident, generateSafetyChatReply } from '../services/aiService.js';
import { seedDemoIncidents } from '../utils/seeder.js';

export const createTicket = async (req, res, next) => {
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
      return res.status(400).json({ success: false, message: 'Title and description are required.' });
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
        name: reporterName || 'Campus Operations Member',
        regNo: reporterRegNo || 'PU-STUDENT',
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
    next(error);
  }
};

export const getTickets = async (req, res, next) => {
  try {
    const tickets = await Ticket.find().sort({ createdAt: -1 }).lean();
    return res.json(tickets);
  } catch (error) {
    next(error);
  }
};

export const getTicketsByStudent = async (req, res, next) => {
  try {
    const { regNo } = req.params;
    const tickets = await Ticket.find({ 'reportedBy.regNo': regNo })
      .sort({ createdAt: -1 })
      .lean();
    return res.json(tickets);
  } catch (error) {
    next(error);
  }
};

export const updateTicketStatus = async (req, res, next) => {
  try {
    const { status, note } = req.body;
    const validStatuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status value.' });
    }

    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid ticket ID format.' });
    }

    const ticket = await Ticket.findById(req.params.id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'Ticket not found.' });
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
    next(error);
  }
};

export const deleteTicket = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid ticket ID format.' });
    }

    const ticket = await Ticket.findById(req.params.id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'Ticket not found.' });
    }
    await ticket.deleteOne();

    const io = req.app.get('io');
    if (io) {
      io.emit('ticket:deleted', req.params.id);
    }

    return res.json({ success: true, message: 'Ticket deleted successfully', id: req.params.id });
  } catch (error) {
    next(error);
  }
};

export const seedDemoData = async (req, res, next) => {
  try {
    const inserted = await seedDemoIncidents();
    const allTickets = await Ticket.find().sort({ createdAt: -1 }).lean();

    const io = req.app.get('io');
    if (io) {
      io.emit('tickets:seeded', allTickets);
    }

    return res.status(201).json({
      success: true,
      message: `Successfully seeded ${inserted.length} campus incidents.`,
      tickets: allTickets,
    });
  } catch (error) {
    next(error);
  }
};

export const chatWithSafetyCopilot = async (req, res, next) => {
  try {
    const { message } = req.body;
    if (!message || !message.trim()) {
      return res.status(400).json({ success: false, message: 'Message is required.' });
    }
    const result = await generateSafetyChatReply(message);
    return res.json(result);
  } catch (error) {
    next(error);
  }
};

export const getCampusHealthScore = async (req, res, next) => {
  try {
    const [total, open, inProgress, resolved, critical] = await Promise.all([
      Ticket.countDocuments(),
      Ticket.countDocuments({ status: 'OPEN' }),
      Ticket.countDocuments({ status: 'IN_PROGRESS' }),
      Ticket.countDocuments({ status: 'RESOLVED' }),
      Ticket.countDocuments({ severity: 'CRITICAL', status: { $ne: 'RESOLVED' } }),
    ]);

    const resolvedRate = total > 0 ? (resolved / total) * 100 : 100;
    const criticalPenalty = critical * 10;
    const healthScore = Math.max(0, Math.min(100, Math.round(resolvedRate - criticalPenalty)));

    const recentResolved = await Ticket.find({ status: 'RESOLVED' })
      .sort({ updatedAt: -1 })
      .limit(5)
      .select('ticketCode title category updatedAt')
      .lean();

    return res.json({
      success: true,
      healthScore,
      total,
      open,
      inProgress,
      resolved,
      critical,
      recentResolved,
    });
  } catch (error) {
    next(error);
  }
};