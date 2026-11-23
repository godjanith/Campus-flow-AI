import express from 'express';
import upload from '../middleware/uploadMiddleware.js';
import { protect } from '../middleware/authMiddleware.js';
import {
  createTicket,
  getTickets,
  getTicketsByStudent,
  updateTicketStatus,
  deleteTicket,
  clearAllTickets,
  seedDemoData,
  chatWithSafetyCopilot,
  getCampusHealthScore,
} from '../controllers/ticketController.js';
import {
  startSimulation,
  stopSimulation,
  isSimulationRunning,
} from '../services/simulationService.js';

const router = express.Router();

router.get('/', getTickets);
router.post('/', upload.single('image'), createTicket);
router.post('/chat', chatWithSafetyCopilot);
router.get('/health-score', getCampusHealthScore);
router.get('/student/:regNo', getTicketsByStudent);

router.get('/simulation/status', (req, res) => {
  res.json({ running: isSimulationRunning() });
});

router.post('/simulation/toggle', protect, (req, res) => {
  const io = req.app.get('io');
  const running = isSimulationRunning() ? stopSimulation(io) : startSimulation(io);
  res.json({ running });
});

router.post('/seed', protect, seedDemoData);
router.delete('/purge/all', protect, clearAllTickets);
router.patch('/:id/status', protect, updateTicketStatus);
router.delete('/:id', protect, deleteTicket);

export default router;