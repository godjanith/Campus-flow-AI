import React, { useState } from 'react';
import { ShieldCheckIcon, BoltIcon } from '@heroicons/react/24/outline';
import api from '../services/api';

export default function Login({ onLoginSuccess }) {
  const [email, setEmail] = useState('admin@presidencyuniversity.in');
  const [password, setPassword] = useState('adminpassword123');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const { data } = await api.post('/auth/login', { email, password });
      localStorage.setItem('campusflow_token', data.token);
      localStorage.setItem('campusflow_user', JSON.stringify(data));
      onLoginSuccess(data);
    } catch (err) {
      setError(err.response?.data?.message || 'Unable to connect to CampusFlow server.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center p-4">
      <div className="w-full max-w-md rounded-3xl border border-slate-200/90 bg-white/95 p-8 shadow-xl shadow-slate-200/60 backdrop-blur">
        <div className="mb-6 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-indigo-600 text-white shadow-md shadow-indigo-200">
              <BoltIcon className="h-6 w-6" />
            </div>
            <div>
              <h1 className="text-xl font-extrabold tracking-tight text-slate-900">
                CampusFlow <span className="text-indigo-600">AI</span>
              </h1>
              <p className="text-xs font-medium text-slate-500">
                Spatial Infrastructure Command
              </p>
            </div>
          </div>
          <span className="rounded-full border border-emerald-200 bg-emerald-50 px-2.5 py-1 font-mono text-[10px] font-bold text-emerald-700">
            v2.0 LIVE
          </span>
        </div>

        <div className="mb-6 rounded-2xl border border-indigo-100 bg-indigo-50/60 p-3.5 text-xs text-indigo-900">
          <div className="flex items-center gap-2 font-bold">
            <ShieldCheckIcon className="h-4 w-4 text-indigo-600" />
            <span>Presidency University Operations Node</span>
          </div>
          <p className="mt-1 text-indigo-700/90">
            Pre-filled with default Admin Commander credentials for instant local evaluation.
          </p>
        </div>

        {error && (
          <div className="mb-4 rounded-xl border border-red-200 bg-red-50 px-3.5 py-2.5 text-xs font-semibold text-red-700">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
              Commander Email
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1.5 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-900 focus:border-indigo-500 focus:bg-white focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
              Access Key
            </label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1.5 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-900 focus:border-indigo-500 focus:bg-white focus:outline-none"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-indigo-600 py-3 text-sm font-bold text-white shadow-md shadow-indigo-200 hover:bg-indigo-700 disabled:opacity-50 transition"
          >
            {loading ? 'Authenticating...' : 'Enter Command Center'}
          </button>
        </form>
      </div>
    </div>
  );
}