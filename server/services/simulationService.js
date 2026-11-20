import Ticket from '../models/Ticket.js';
import { analyzeIncident } from './aiService.js';

const SIMULATED_EVENTS = [
  {
    title: 'Smart Meter Voltage Surge in Robotics Lab',
    description: 'Three-phase power monitor detected 254V spike on Lab Bench 4.',
    building: 'Engineering Block A',
    lat: 13.1724,
    lng: 77.5365,
    reporterName: 'Aarav Kulkarni',
    reporterRegNo: '20252MCA0119',
  },
  {
    title: 'Roof Rainwater Downspout Overflow',
    description: 'Blocked terrace drain causing water cascade near West Corridor entrance.',
    building: 'Central Library',
    lat: 13.1719,
    lng: 77.5351,
    reporterName: 'Diya Menon',
    reporterRegNo: '20252MCA0204',
  },
  {
    title: 'Seminar Hall Projector & HDMI Matrix Offline',
    description: 'AV rack controller unresponsive ahead of guest lecture.',
    building: 'School of Management',
    lat: 13.1727,
    lng: 77.5359,
    reporterName: 'Rohan Shetty',
    reporterRegNo: '20252MBA0045',
  },
  {
    title: 'Perimeter Bollard Lighting Failure',
    description: 'Four LED pathway bollards dark along South Hostel walkway.',
    building: 'Main Security Gate',
    lat: 13.1709,
    lng: 77.5369,
    reporterName: 'Meera Krishnan',
    reporterRegNo: '20252MCA0089',
  },
  {
    title: 'Chiller Plant Pressure Drop Alert',
    description: 'Automated BMS sensor flagged low refrigerant pressure on Wing B.',
    building: 'Auditorium Complex',
    lat: 13.1713,
    lng: 77.5354,
    reporterName: 'IoT BMS Telemetry',
    reporterRegNo: 'AUTO-SENSOR-04',
  },
];

let simulationInterval = null;
let eventCursor = 0;

export const startSimulation = (io) => {
  if (simulationInterval) return true;

  simulationInterval = setInterval(async () => {
    try {
      const sample = SIMULATED_EVENTS[eventCursor % SIMULATED_EVENTS.length];
      eventCursor += 1;

      const jitterLat = sample.lat + (Math.random() - 0.5) * 0.0004;
      const jitterLng = sample.lng + (Math.random() - 0.5) * 0.0004;

      const aiResult = await analyzeIncident({
        title: sample.title,
        description: sample.description,
        building: sample.building,
      });

      const ticket = await Ticket.create({
        ticketCode: `CF-${Math.floor(100000 + Math.random() * 900000)}`,
        title: sample.title,
        description: sample.description,
        building: sample.building,
        location: { lat: jitterLat, lng: jitterLng },
        category: aiResult.category,
        severity: aiResult.severity,
        aiSummary: aiResult.aiSummary,
        estimatedResolutionTime: aiResult.estimatedResolutionTime,
        safetyAdvisory: aiResult.safetyAdvisory,
        triageEngineUsed: aiResult.triageEngineUsed,
        status: 'OPEN',
        reportedBy: {
          name: sample.reporterName,
          regNo: sample.reporterRegNo,
        },
        timeline: [
          {
            status: 'OPEN',
            note: `Live Telemetry Stream: Triaged as ${aiResult.severity} (${aiResult.category}).`,
            timestamp: new Date(),
          },
        ],
      });

      io.emit('ticket:created', ticket);

      const openTicket = await Ticket.findOne({ status: 'OPEN', _id: { $ne: ticket._id } });
      if (openTicket) {
        openTicket.status = 'IN_PROGRESS';
        openTicket.timeline.push({
          status: 'IN_PROGRESS',
          note: 'Autonomous Dispatch: Nearest campus technician assigned & en route.',
          timestamp: new Date(),
        });
        await openTicket.save();
        io.emit('ticket:updated', openTicket);
      }
    } catch (err) {
      console.error('[Simulation Error]', err.message);
    }
  }, 7000);

  io.emit('simulation:state', { running: true });
  return true;
};

export const stopSimulation = (io) => {
  if (simulationInterval) {
    clearInterval(simulationInterval);
    simulationInterval = null;
  }
  io.emit('simulation:state', { running: false });
  return false;
};

export const isSimulationRunning = () => Boolean(simulationInterval);