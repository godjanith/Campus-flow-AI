import axios from 'axios';
import { io } from 'socket.io-client';

const rawUrl =
  import.meta.env.VITE_API_URL || 'http://localhost:5000';

export const API_BASE_URL = rawUrl.replace(/\/api\/?$/, '').replace(/\/$/, '');
export const GEMINI_API_KEY = import.meta.env.VITE_GEMINI_API_KEY || '';

const api = axios.create({
  baseURL: `${API_BASE_URL}/api`,
  timeout: 8000,
});

// Exponential backoff retry interceptor
api.interceptors.response.use(null, async (error) => {
  const config = error.config;
  if (!config || config._retryCount >= 2) return Promise.reject(error);

  config._retryCount = (config._retryCount || 0) + 1;
  const delay = Math.pow(2, config._retryCount) * 500;
  await new Promise((r) => setTimeout(r, delay));
  return api(config);
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('campusflow_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export const socket = io(API_BASE_URL, {
  transports: ['websocket', 'polling'],
  reconnection: true,
  reconnectionAttempts: 10,
  reconnectionDelay: 1000,
  reconnectionDelayMax: 5000,
  timeout: 10000,
});

export default api;