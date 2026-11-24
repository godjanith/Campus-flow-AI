import dotenv from 'dotenv';
import express from 'express';
import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import { Server } from 'socket.io';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config();
dotenv.config({ path: path.join(__dirname, '.env') });

import connectDB from './config/db.js';
import { seedDefaultAdmin } from './utils/seeder.js';
import authRoutes from './routes/authRoutes.js';
import ticketRoutes from './routes/ticketRoutes.js';
import errorHandler from './middleware/errorHandler.js';

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  },
  pingTimeout: 25000,
  pingInterval: 10000,
});

app.set('io', io);

// ── Security & Performance Middleware ───────────────────────────────
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  contentSecurityPolicy: false,
}));
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Rate limit for API routes (300 req/min per IP to prevent dev throttling)
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests, please try again later.' },
});
app.use('/api', apiLimiter);

// Static client build
const clientDistPath = path.join(__dirname, '../client/dist');
app.use(express.static(clientDistPath));

// Static uploads with caching headers
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), {
  maxAge: '1d',
  etag: true,
}));

// ── Health Check ───────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'CampusFlow AI Core Server',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// ── API Routes ─────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/tickets', ticketRoutes);

// ── Socket.io Connection Manager ───────────────────────────────────
const connectedClients = new Set();

io.on('connection', (socket) => {
  connectedClients.add(socket.id);
  console.log(`[Socket.io] Client connected: ${socket.id} (Total: ${connectedClients.size})`);

  socket.on('join:student', (regNo) => {
    if (regNo) socket.join(`student:${regNo}`);
  });

  socket.on('disconnect', () => {
    connectedClients.delete(socket.id);
    console.log(`[Socket.io] Client disconnected: ${socket.id} (Total: ${connectedClients.size})`);
  });
});

// ── Single Page App Catch-All for Non-API Routes ───────────────────
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api') || req.path.startsWith('/uploads')) {
    return next();
  }
  const indexPath = path.join(clientDistPath, 'index.html');
  res.sendFile(indexPath, (err) => {
    if (err) {
      res.status(200).send('CampusFlow AI Backend API is active. React web build pending.');
    }
  });
});

// ── 404 Catch-All for Unmatched API routes ─────────────────────────
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `API route ${req.originalUrl} not found.`,
  });
});

// ── Global Error Handler ───────────────────────────────────────────
app.use(errorHandler);

// ── Unhandled Rejection / Exception Handlers ───────────────────────
process.on('unhandledRejection', (reason) => {
  console.error('[Unhandled Rejection]', reason);
});
process.on('uncaughtException', (err) => {
  console.error('[Uncaught Exception]', err);
  process.exit(1);
});

// ── Start Server ───────────────────────────────────────────────────
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();
  await seedDefaultAdmin();

  server.listen(PORT, '0.0.0.0', () => {
    console.log(`====================================================`);
    console.log(`🚀 CampusFlow AI Backend running on port ${PORT}`);
    console.log(`📡 Local API:    http://localhost:${PORT}/api`);
    console.log(`📱 Emulator API: http://10.0.2.2:${PORT}/api`);
    console.log(`🗄️  MongoDB:      ${process.env.MONGO_URI}`);
    console.log(`====================================================`);
  });
};

startServer();