import axios from 'axios';
import { io } from 'socket.io-client';

const resolveBaseUrl = () => {
  if (typeof window !== 'undefined') {
    const custom = localStorage.getItem('campusflow_backend_url');
    if (custom) return custom.replace(/\/api\/?$/, '').replace(/\/$/, '');

    // If served from Express backend directly (e.g. port 5000 or custom host)
    if (
      window.location.port === '5000' ||
      (window.location.hostname !== 'localhost' && !window.location.hostname.includes('vercel.app'))
    ) {
      return window.location.origin;
    }
  }
  const rawUrl = import.meta.env.VITE_API_URL || 'http://localhost:5000';
  return rawUrl.replace(/\/api\/?$/, '').replace(/\/$/, '');
};

export const API_BASE_URL = resolveBaseUrl();
export const GEMINI_API_KEY = import.meta.env.VITE_GEMINI_API_KEY || '';

export const updateBackendUrl = (newUrl) => {
  if (newUrl && newUrl.trim()) {
    localStorage.setItem('campusflow_backend_url', newUrl.trim());
  } else {
    localStorage.removeItem('campusflow_backend_url');
  }
  window.location.reload();
};

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