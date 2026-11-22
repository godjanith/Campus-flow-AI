import axios from 'axios';
import { io } from 'socket.io-client';

const rawUrl =
  import.meta.env.VITE_API_URL || 'https://campusflow-ai-server-doo6.onrender.com';

export const API_BASE_URL = rawUrl.replace(/\/api\/?$/, '').replace(/\/$/, '');

const api = axios.create({
  baseURL: `${API_BASE_URL}/api`,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('campusflow_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export const socket = io(API_BASE_URL, {
  transports: ['websocket', 'polling'],
});

export default api;