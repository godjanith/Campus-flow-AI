import axios from 'axios';

const rawUrl =
  import.meta.env.VITE_API_URL || 'https://campusflow-ai-server-doo6.onrender.com';
const baseURL = rawUrl.endsWith('/api')
  ? rawUrl
  : `${rawUrl.replace(/\/$/, '')}/api`;

const api = axios.create({ baseURL });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('campusflow_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default api;