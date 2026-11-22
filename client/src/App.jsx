import React, { useState } from 'react';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';

export default function App() {
  const [user, setUser] = useState(() => {
    try {
      const saved = localStorage.getItem('campusflow_user');
      return saved && saved !== 'undefined' ? JSON.parse(saved) : null;
    } catch {
      localStorage.removeItem('campusflow_user');
      return null;
    }
  });

  const handleLogout = () => {
    localStorage.removeItem('campusflow_token');
    localStorage.removeItem('campusflow_user');
    setUser(null);
  };

  if (!user) {
    return <Login onLoginSuccess={(userData) => setUser(userData)} />;
  }

  return <Dashboard user={user} onLogout={handleLogout} />;
}