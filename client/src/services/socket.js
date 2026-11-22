import { io } from 'socket.io-client';

const rawUrl =
  import.meta.env.VITE_API_URL || 'https://campusflow-ai-server-doo6.onrender.com';
const SOCKET_URL = rawUrl.replace(/\/api\/?$/, '').replace(/\/$/, '');

const socket = io(SOCKET_URL, {
  transports: ['websocket', 'polling'],
});

export default socket;