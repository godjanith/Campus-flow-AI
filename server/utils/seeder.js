import mongoose from 'mongoose';
import User from '../models/User.js';
import Ticket from '../models/Ticket.js';

export const seedDefaultAdmin = async () => {
  try {
    if (mongoose.connection.readyState !== 1) {
      console.log('[Seeder] Skipping seedDefaultAdmin: MongoDB not connected.');
      return;
    }
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
      ticketCode: 'CF-842910',
      title: 'Exposed High-Voltage Conduit Sparking',
      description: 'Main corridor junction box near Lab 304 emitting intermittent sparks, ozone smell, and loose cabling.',
      building: 'Engineering Block A',
      location: { lat: 13.1723, lng: 77.5366 },
      category: 'Electrical Safety',
      severity: 'CRITICAL',
      aiSummary: '[CRITICAL] Active electrical arcing hazard detected at Engineering Block A junction box near Lab 304.',
      estimatedResolutionTime: '20 mins',
      safetyAdvisory: 'DANGER: Evacuate 10-meter radius immediately. Do not touch metal doorframe.',
      triageEngineUsed: 'GEMINI_MULTIMODAL',
      status: 'OPEN',
      reportedBy: { name: 'Rahul R', regNo: '20252MCA0301' },
      imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=800&q=80',
      timeline: [
        { status: 'OPEN', note: 'Incident reported by student with field photo & triaged as CRITICAL by CampusFlow AI.', timestamp: new Date(Date.now() - 18 * 60000) },
      ],
      createdAt: new Date(Date.now() - 18 * 60000),
    },
    {
      ticketCode: 'CF-729104',
      title: 'Chilled Water Pipe Leak Flooding Lobby',
      description: 'Overhead HVAC chilled water return pipe leaking heavily onto granite tiles outside Auditorium entrance.',
      building: 'Auditorium Complex',
      location: { lat: 13.1712, lng: 77.5355 },
      category: 'Plumbing & Water',
      severity: 'HIGH',
      aiSummary: '[HIGH] Overhead chilled water line rupture causing slip hazard in Auditorium main lobby.',
      estimatedResolutionTime: '45 mins',
      safetyAdvisory: 'Caution: Wet granite flooring. Use West Wing entrance until barricades are placed.',
      triageEngineUsed: 'GEMINI_MULTIMODAL',
      status: 'IN_PROGRESS',
      reportedBy: { name: 'Ananya Sharma', regNo: '20252MCA0142' },
      imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80',
      timeline: [
        { status: 'OPEN', note: 'Ticket logged via CampusFlow Mobile with student photo evidence.', timestamp: new Date(Date.now() - 65 * 60000) },
        { status: 'IN_PROGRESS', note: 'Plumbing & HVAC isolation crew dispatched to Auditorium.', timestamp: new Date(Date.now() - 25 * 60000) },
      ],
      createdAt: new Date(Date.now() - 65 * 60000),
    },
  ];

  return await Ticket.insertMany(demoRecords);
};