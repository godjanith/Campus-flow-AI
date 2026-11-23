import mongoose from 'mongoose';

const timelineEntrySchema = new mongoose.Schema(
  {
    status: { type: String, enum: ['OPEN', 'IN_PROGRESS', 'RESOLVED'], required: true },
    note: { type: String, required: true },
    timestamp: { type: Date, default: Date.now },
  },
  { _id: false }
);

const ticketSchema = new mongoose.Schema(
  {
    ticketCode: { type: String, unique: true, required: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, required: true },
    building: { type: String, required: true, default: 'Engineering Block A' },
    location: {
      lat: { type: Number, default: 13.1718 },
      lng: { type: Number, default: 77.5361 },
    },
    imageUrl: { type: String, default: null },
    category: {
      type: String,
      enum: [
        'Electrical Safety',
        'Plumbing & Water',
        'IT & Network',
        'Civil & Structural',
        'HVAC',
        'Sanitation',
        'Security Hazard',
      ],
      default: 'Civil & Structural',
    },
    severity: {
      type: String,
      enum: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'],
      default: 'MEDIUM',
    },
    aiSummary: { type: String, required: true },
    estimatedResolutionTime: { type: String, default: '2 hours' },
    safetyAdvisory: { type: String, required: true },
    triageEngineUsed: {
      type: String,
      enum: ['GEMINI_MULTIMODAL', 'OFFLINE_NLP_HEURISTIC'],
      default: 'OFFLINE_NLP_HEURISTIC',
    },
    status: {
      type: String,
      enum: ['OPEN', 'IN_PROGRESS', 'RESOLVED'],
      default: 'OPEN',
    },
    reportedBy: {
      name: { type: String, default: 'Campus Student' },
      regNo: { type: String, default: '20252MCA0318' },
    },
    timeline: [timelineEntrySchema],
  },
  { timestamps: true }
);

// ── Compound Indexes for sub-50ms queries ──────────────────────────
ticketSchema.index({ status: 1, severity: 1, createdAt: -1 });
ticketSchema.index({ category: 1, status: 1 });
ticketSchema.index({ 'reportedBy.regNo': 1, createdAt: -1 });
ticketSchema.index({ createdAt: -1 });

export default mongoose.model('Ticket', ticketSchema);