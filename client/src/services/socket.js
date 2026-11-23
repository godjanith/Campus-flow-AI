// This file is kept for backwards compatibility but the main socket
// is now exported from api.js to prevent duplicate Socket.io connections.
// Import from '../services/api' instead to get the shared socket instance.
import { socket } from './api';
export default socket;