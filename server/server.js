import dotenv from 'dotenv';
import express from 'express';
import http from 'http';
import path from 'path';
import fs from 'fs';
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

// ── Health & Gateway Root ──────────────────────────────────────────
app.get('/api', (req, res) => {
  res.json({
    success: true,
    service: 'CampusFlow AI Core Gateway',
    version: '2.0.0',
    status: 'ONLINE',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      tickets: '/api/tickets',
    },
  });
});

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

// ── 404 for Unmatched API routes (/api/*) ──────────────────────────
app.use('/api/*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `API route ${req.originalUrl} not found.`,
  });
});

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
app.get('*', (req, res) => {
  const indexPath = path.join(clientDistPath, 'index.html');
  if (fs.existsSync(indexPath)) {
    return res.sendFile(indexPath);
  }
  res.status(200).send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>CampusFlow AI Core Server</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0F294A; color: white; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; text-align: center; }
          .card { background: white; color: #0F294A; border-radius: 16px; padding: 32px; max-width: 480px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); border-top: 4px solid #C59B27; }
          h1 { margin-top: 0; font-size: 22px; }
          a { color: #0F294A; font-weight: bold; text-decoration: underline; }
          .badge { background: #E0E7FF; color: #3730A3; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>CampusFlow <span style="color: #C59B27;">AI</span></h1>
          <p><span class="badge">SERVER ONLINE</span></p>
          <p>Presidency University Core Node & WebSocket Hub is operating on port 5000.</p>
          <p><a href="/api/health">Check Health</a> &bull; <a href="/api/tickets">View Tickets API</a></p>
        </div>
      </body>
    </html>
  `);
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