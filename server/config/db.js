import mongoose from 'mongoose';

const connectDB = async () => {
  const uri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/campusflow_ai';
  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });
    console.log(`[MongoDB] Connected: ${conn.connection.host} -> DB: ${conn.connection.name}`);
  } catch (error) {
    console.error(`[MongoDB Error] ${error.message}`);
    console.warn(`[MongoDB Warning] Continuing in resilient memory mode so API and sockets stay operational.`);
  }
};

export default connectDB;
