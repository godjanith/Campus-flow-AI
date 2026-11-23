import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();

const dbs = ['campusflow_ai', 'campusflow', 'complaintDB'];

async function clearIncidents() {
  console.log('--- Purging Stored Incidents & Tickets ---');
  for (const dbName of dbs) {
    try {
      const conn = await mongoose.createConnection(`mongodb://127.0.0.1:27017/${dbName}`).asPromise();
      const collections = await conn.db.listCollections().toArray();
      for (const col of collections) {
        if (col.name === 'tickets' || col.name === 'complaints') {
          const res = await conn.collection(col.name).deleteMany({});
          console.log(`[${dbName}] Purged ${res.deletedCount} items from collection: ${col.name}`);
        }
      }
      await conn.close();
    } catch (err) {
      console.error(`[${dbName}] Error:`, err.message);
    }
  }
  console.log('--- Incident Cleanup Complete ---');
  process.exit(0);
}

clearIncidents();
