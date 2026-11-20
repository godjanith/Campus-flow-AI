import User from '../models/User.js';
import Ticket from '../models/Ticket.js';

export const seedDefaultAdmin = async () => {
  try {
    const adminEmail = 'admin@presidencyuniversity.in';
    const existingAdmin = await User.findOne({ email: adminEmail });

    if (!existingAdmin) {
      await User.create({
        name: 'Campus Facility Commander',
        email: adminEmail,
        password: 'adminpassword123',
        role: 'ADMIN',
        regNo: 'ADMIN-001',
      });
      console.log(`[Seeder] Default Admin created: ${adminEmail} / adminpassword123`);
    } else {
      console.log(`[Seeder] Default Admin verified: ${adminEmail}`);
    }
  } catch (error) {
    console.error(`[Seeder Error] ${error.message}`);
  }
};

export const seedDemoIncidents = async () => {
  const demoRecords = [
    {
      ticketCode: `CF-${Math.floor(100000 + Math.random() * 900000)}`,
      title: 'Exposed High-Voltage Conduit Sparking',
      description: 'Main corridor junction box near Lab 304 emitting intermittent sparks and ozone smell.',
      building: 'Engineering Block A',
      location: { lat: 13.1723, lng: 77.5366 },
      category: 'Electrical Safety',
      severity: 'CRITICAL',
      aiSummary: '[CRITICAL] Active electrical arcing hazard detected at Engineering Block A junction box near Lab 304.',
      estimatedResolutionTime: '20 mins',
      safetyAdvisory: 'DANGER: Evacuate 10-meter radius immediately. Do not touch metal doorframe.',
      triageEngineUsed: 'GEMINI_MULTIMODAL',
      status: 'OPEN',
      reportedBy: { name: 'Janith V C', regNo: '20252MCA0318' },
      timeline: [
        { status: 'OPEN', note: 'Incident reported & triaged as CRITICAL by CampusFlow AI.', timestamp: new Date(Date.now() - 15 * 60000) },
      ],
    },
    {
      ticketCode: `CF-${Math.floor(100000 + Math.random() * 900000)}`,
      title: 'Chilled Water Pipe Leak Flooding Lobby',
      description: 'Overhead HVAC chilled water return pipe leaking heavily onto granite tiles outside Auditorium.',
      building: 'Auditorium Complex',
      location: { lat: 13.1712, lng: 77.5355 },
      category: 'Plumbing & Water',
      severity: 'HIGH',
      aiSummary: '[HIGH] Overhead chilled water line rupture causing slip hazard in Auditorium main lobby.',
      estimatedResolutionTime: '45 mins',
      safetyAdvisory: 'Caution: Wet granite flooring. Use West Wing entrance until barricades are placed.',
      triageEngineUsed: 'GEMINI_MULTIMODAL',
      status: 'IN_PROGRESS',
      reportedBy: { name: 'Rahul R', regNo: '20252MCA0301' },
      timeline: [
        { status: 'OPEN', note: 'Ticket logged via CampusFlow Mobile.', timestamp: new Date(Date.now() - 55 * 60000) },
        { status: 'IN_PROGRESS', note: 'Plumbing & HVAC isolation crew dispatched to Auditorium.', timestamp: new Date(Date.now() - 25 * 60000) },
      ],
    },
    {
      ticketCode: `CF-${Math.floor(100000 + Math.random() * 900000)}`,
      title: 'Core Distribution Switch Packet Loss',
      description: 'Wi-Fi access points on 2nd floor dropping all student connections every 2 minutes.',
      building: 'Central Library',
      location: { lat: 13.1720, lng: 77.5350 },
      category: 'IT & Network',
      severity: 'HIGH',
      aiSummary: '[HIGH] PoE distribution switch instability affecting 2nd-floor Central Library wireless mesh.',
      estimatedResolutionTime: '1 hour',
      safetyAdvisory: 'Switch to wired study carrels on Floor 1 while NOC engineers reboot the PoE blade.',
      triageEngineUsed: 'OFFLINE_NLP_HEURISTIC',
      status: 'IN_PROGRESS',
      reportedBy: { name: 'Ananya Sharma', regNo: '20252MCA0142' },
      timeline: [
        { status: 'OPEN', note: 'Network anomaly reported by student.', timestamp: new Date(Date.now() - 90 * 60000) },
        { status: 'IN_PROGRESS', note: 'IT Network Operations Engineer assigned.', timestamp: new Date(Date.now() - 40 * 60000) },
      ],
    },
    {
      ticketCode: `CF-${Math.floor(100000 + Math.random() * 900000)}`,
      title: 'Biometric Turnstile Gate Stuck Open',
      description: 'North Gate RFID turnstile motor jammed in open state allowing unauthenticated entry.',
      building: 'Main Security Gate',
      location: { lat: 13.1708, lng: 77.5370 },
      category: 'Security Hazard',
      severity: 'MEDIUM',
      aiSummary: '[MEDIUM] Automated access control turnstile mechanical jam at North Entry Gate.',
      estimatedResolutionTime: '1.5 hours',
      safetyAdvisory: 'Security personnel stationed manually for ID verification until servo motor replacement.',
      triageEngineUsed: 'GEMINI_MULTIMODAL',
      status: 'OPEN',
      reportedBy: { name: 'Karthik Gowda', regNo: '20252MCA0210' },
      timeline: [
        { status: 'OPEN', note: 'Security hardware fault logged.', timestamp: new Date(Date.now() - 35 * 60000) },
      ],
    },
    {
      ticketCode: `CF-${Math.floor(100000 + Math.random() * 900000)}`,
      title: 'Lecture Hall 202 Split AC Compressor Fault',
      description: 'Air conditioning unit blowing warm air and displaying E4 error code during afternoon session.',
      building: 'School of Management',
      location: { lat: 13.1726, lng: 77.5358 },
      category: 'HVAC',
      severity: 'LOW',
      aiSummary: '[LOW] HVAC indoor unit E4 refrigerant pressure fault in Lecture Hall 202.',
      estimatedResolutionTime: '3 hours',
      safetyAdvisory: 'Keep windows open for ventilation; non-hazardous equipment fault.',
      triageEngineUsed: 'OFFLINE_NLP_HEURISTIC',
      status: 'RESOLVED',
      reportedBy: { name: 'Sneha Nair', regNo: '20252MBA0088' },
      timeline: [
        { status: 'OPEN', note: 'HVAC fault submitted.', timestamp: new Date(Date.now() - 240 * 60000) },
        { status: 'IN_PROGRESS', note: 'Technician inspecting outdoor condenser.', timestamp: new Date(Date.now() - 180 * 60000) },
        { status: 'RESOLVED', note: 'Capacitor replaced and cooling restored to 22°C.', timestamp: new Date(Date.now() - 60 * 60000) },
      ],
    },
    {
      ticketCode: `CF-${Math.floor(100000 + Math.random() * 900000)}`,
      title: 'Loose Staircase Anti-Skid Nosing Strip',
      description: 'Aluminum stair edge strip detached on 1st floor landing creating a tripping hazard.',
      building: 'Engineering Block B',
      location: { lat: 13.1715, lng: 77.5364 },
      category: 'Civil & Structural',
      severity: 'MEDIUM',
      aiSummary: '[MEDIUM] Detached metallic stair nosing strip on Engineering Block B 1st-floor stairwell.',
      estimatedResolutionTime: '2 hours',
      safetyAdvisory: 'Use handrail and watch step on 1st-floor stairwell landing.',
      triageEngineUsed: 'GEMINI_MULTIMODAL',
      status: 'RESOLVED',
      reportedBy: { name: 'Janith V C', regNo: '20252MCA0318' },
      timeline: [
        { status: 'OPEN', note: 'Civil hazard reported via mobile.', timestamp: new Date(Date.now() - 300 * 60000) },
        { status: 'IN_PROGRESS', note: 'Carpentry & civil team dispatched with anchors.', timestamp: new Date(Date.now() - 210 * 60000) },
        { status: 'RESOLVED', note: 'Re-anchored strip with heavy-duty masonry fasteners.', timestamp: new Date(Date.now() - 120 * 60000) },
      ],
    },
  ];

  return await Ticket.insertMany(demoRecords);
};