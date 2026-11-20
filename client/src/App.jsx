import React, { useState } from 'react';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';

export default function App() {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('campusflow_user');
    return saved ? JSON.parse(saved) : null;
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