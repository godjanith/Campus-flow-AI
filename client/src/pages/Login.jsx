import React, { useState } from 'react';
import {
  ShieldCheck,
  Zap,
  ArrowRight,
  AlertCircle,
  Lock,
  Mail,
  User,
  GraduationCap,
  CheckCircle2,
  Sparkles,
} from 'lucide-react';
import api from '../services/api';

export default function Login({ onLoginSuccess }) {
  const [isRegister, setIsRegister] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [regNo, setRegNo] = useState('');
  const [role, setRole] = useState('STUDENT');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const handlePreset = (presetEmail, presetPass) => {
    setEmail(presetEmail);
    setPassword(presetPass);
    setIsRegister(false);
    setError('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccessMsg('');
    setLoading(true);

    try {
      if (isRegister) {
        if (!name.trim()) throw new Error('Please enter your full name');
        if (password.length < 6) throw new Error('Password must be at least 6 characters');

        const { data } = await api.post('/auth/register', {
          name: name.trim(),
          email: email.trim(),
          password,
          regNo: regNo.trim() || '20252MCA0318',
          role,
        });

        const userData = data.user || data;
        localStorage.setItem('campusflow_token', data.token);
        localStorage.setItem('campusflow_user', JSON.stringify(userData));
        setSuccessMsg('Registration successful! Launching command center...');
        setTimeout(() => onLoginSuccess(userData), 400);
      } else {
        const { data } = await api.post('/auth/login', {
          email: email.trim(),
          password,
        });

        const userData = data.user || data;
        localStorage.setItem('campusflow_token', data.token);
        localStorage.setItem('campusflow_user', JSON.stringify(userData));
        onLoginSuccess(userData);
      }
    } catch (err) {
      setError(
        err.response?.data?.message ||
          err.message ||
          'Authentication failed. Please verify credentials or connection.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-4 py-12 bg-[#F8FAFC]">
      <div className="w-full max-w-lg rounded-3xl border border-slate-200/90 bg-white p-8 shadow-2xl shadow-slate-900/5">
        {/* Flagship Header */}
        <div className="flex items-center justify-between mb-6 pb-4 border-b border-slate-100">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#0F294A] text-[#C59B27] shadow-md shadow-[#0F294A]/20 border border-[#C59B27]/40">
              <Zap className="h-6 w-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black tracking-tight text-[#0F294A]">
                  CampusFlow <span className="text-[#C59B27]">AI</span>
                </h1>
              </div>
              <p className="text-xs font-semibold text-slate-500">
                Presidency University Official Portal
              </p>
            </div>
          </div>
          <span className="rounded-full border border-amber-300/80 bg-amber-50 px-2.5 py-1 font-mono text-[10px] font-extrabold text-[#0F294A]">
            v2.0 FLAGSHIP
          </span>
        </div>

        {/* Auth Mode Toggle Tabs */}
        <div className="mb-6 grid grid-cols-2 gap-1 rounded-2xl bg-slate-100 p-1 border border-slate-200">
          <button
            type="button"
            onClick={() => {
              setIsRegister(false);
              setError('');
            }}
            className={`rounded-xl py-2 text-xs font-bold transition ${
              !isRegister
                ? 'bg-white text-[#0F294A] shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Sign In
          </button>
          <button
            type="button"
            onClick={() => {
              setIsRegister(true);
              setError('');
            }}
            className={`rounded-xl py-2 text-xs font-bold transition ${
              isRegister
                ? 'bg-white text-[#0F294A] shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Register Member
          </button>
        </div>

        {/* Demo Fast-Login Pills (For Competitions & Judges) */}
        {!isRegister && (
          <div className="mb-6 rounded-2xl border border-slate-200 bg-slate-50/70 p-3.5">
            <div className="flex items-center justify-between mb-2">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-600 flex items-center gap-1.5">
                <Sparkles className="h-3.5 w-3.5 text-[#C59B27]" />
                One-Click Demo Credentials
              </span>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => handlePreset('admin@presidencyuniversity.in', 'adminpassword123')}
                className="rounded-xl border border-slate-200 bg-white px-2.5 py-2 text-left hover:border-[#0F294A] transition shadow-xs"
              >
                <p className="text-[11px] font-bold text-[#0F294A]">Commander (Admin)</p>
                <p className="text-[10px] text-slate-500 font-mono truncate">admin@presidencyuniversity.in</p>
              </button>
              <button
                type="button"
                onClick={() => handlePreset('student@presidencyuniversity.in', 'student123')}
                className="rounded-xl border border-slate-200 bg-white px-2.5 py-2 text-left hover:border-[#0F294A] transition shadow-xs"
              >
                <p className="text-[11px] font-bold text-[#0F294A]">Campus Student</p>
                <p className="text-[10px] text-slate-500 font-mono truncate">student@presidencyuniversity.in</p>
              </button>
            </div>
          </div>
        )}

        {/* Feedback Alerts */}
        {error && (
          <div className="mb-5 flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-3.5 py-2.5 text-xs font-semibold text-red-700">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {successMsg && (
          <div className="mb-5 flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 px-3.5 py-2.5 text-xs font-semibold text-emerald-800">
            <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
            <span>{successMsg}</span>
          </div>
        )}

        {/* Authentication Form */}
        <form onSubmit={handleSubmit} autoComplete="off" className="space-y-4">
          {isRegister && (
            <>
              <div>
                <label className="mb-1.5 block text-[11px] font-bold uppercase tracking-wider text-slate-600">
                  Full Name *
                </label>
                <div className="relative">
                  <User className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="e.g. Janith V C"
                    className="w-full rounded-xl border border-slate-200 bg-slate-50/50 py-2.5 pl-10 pr-3.5 text-sm font-medium text-slate-900 placeholder:text-slate-400 focus:border-[#0F294A] focus:bg-white focus:outline-none focus:ring-4 focus:ring-[#0F294A]/10 transition"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="mb-1.5 block text-[11px] font-bold uppercase tracking-wider text-slate-600">
                    Reg / Roll No.
                  </label>
                  <div className="relative">
                    <GraduationCap className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                    <input
                      type="text"
                      value={regNo}
                      onChange={(e) => setRegNo(e.target.value)}
                      placeholder="20252MCA0318"
                      className="w-full rounded-xl border border-slate-200 bg-slate-50/50 py-2.5 pl-10 pr-3.5 text-sm font-medium text-slate-900 placeholder:text-slate-400 focus:border-[#0F294A] focus:bg-white focus:outline-none focus:ring-4 focus:ring-[#0F294A]/10 transition"
                    />
                  </div>
                </div>

                <div>
                  <label className="mb-1.5 block text-[11px] font-bold uppercase tracking-wider text-slate-600">
                    Campus Role
                  </label>
                  <select
                    value={role}
                    onChange={(e) => setRole(e.target.value)}
                    className="w-full rounded-xl border border-slate-200 bg-slate-50/50 py-2.5 px-3 text-sm font-medium text-slate-900 focus:border-[#0F294A] focus:bg-white focus:outline-none"
                  >
                    <option value="STUDENT">Student</option>
                    <option value="FACULTY">Faculty Member</option>
                    <option value="STAFF">Campus Staff</option>
                    <option value="ADMIN">Facility Commander</option>
                  </select>
                </div>
              </div>
            </>
          )}

          <div>
            <label className="mb-1.5 block text-[11px] font-bold uppercase tracking-wider text-slate-600">
              {isRegister ? 'University Email Address *' : 'University Email *'}
            </label>
            <div className="relative">
              <Mail className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@presidencyuniversity.in"
                className="w-full rounded-xl border border-slate-200 bg-slate-50/50 py-2.5 pl-10 pr-3.5 text-sm font-medium text-slate-900 placeholder:text-slate-400 focus:border-[#0F294A] focus:bg-white focus:outline-none focus:ring-4 focus:ring-[#0F294A]/10 transition"
              />
            </div>
          </div>

          <div>
            <label className="mb-1.5 block text-[11px] font-bold uppercase tracking-wider text-slate-600">
              Access Password *
            </label>
            <div className="relative">
              <Lock className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="At least 6 characters"
                className="w-full rounded-xl border border-slate-200 bg-slate-50/50 py-2.5 pl-10 pr-3.5 text-sm font-medium text-slate-900 placeholder:text-slate-400 focus:border-[#0F294A] focus:bg-white focus:outline-none focus:ring-4 focus:ring-[#0F294A]/10 transition"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="mt-3 flex w-full items-center justify-center gap-2 rounded-xl bg-[#0F294A] py-3 text-sm font-bold text-white shadow-lg shadow-[#0F294A]/25 hover:bg-[#0A1C33] disabled:opacity-60 transition"
          >
            <span>
              {loading
                ? isRegister
                  ? 'Registering Account...'
                  : 'Authenticating...'
                : isRegister
                ? 'Create CampusFlow Account'
                : 'Enter Command Center'}
            </span>
            {!loading && <ArrowRight className="h-4 w-4 text-[#C59B27]" />}
          </button>
        </form>

        {/* Security Footer Notice */}
        <div className="mt-6 flex items-center justify-center gap-2 text-[11px] text-slate-400 font-medium">
          <ShieldCheck className="h-3.5 w-3.5 text-slate-400" />
          <span>Presidency University AI Infrastructure Node • 256-bit TLS Encrypted</span>
        </div>
      </div>
    </div>
  );
}