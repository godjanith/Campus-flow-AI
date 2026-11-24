import React, { useState } from 'react';
import {
  ShieldCheck,
  ArrowRight,
  AlertCircle,
  Lock,
  Mail,
  User,
  GraduationCap,
  CheckCircle2,
  HelpCircle,
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

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccessMsg('');
    setLoading(true);

    try {
      if (isRegister) {
        if (!name.trim()) throw new Error('Please enter your full name');
        if (password.length < 6) throw new Error('Password must be at least 6 characters');

        const finalRole = role === 'FACULTY_COORDINATOR' ? 'FACULTY_COORDINATOR' : 'STUDENT';
        const defaultReg = finalRole === 'FACULTY_COORDINATOR' ? 'PU-FAC-EMP' : 'PU-STUDENT';

        const { data } = await api.post('/auth/register', {
          name: name.trim(),
          email: email.trim().toLowerCase(),
          password,
          regNo: regNo.trim() || defaultReg,
          role: finalRole,
        });

        const userData = data.user || data;
        localStorage.setItem('campusflow_token', data.token);
        localStorage.setItem('campusflow_user', JSON.stringify(userData));
        setSuccessMsg('Account registered successfully! Entering Command Center...');
        setTimeout(() => onLoginSuccess(userData), 400);
      } else {
        const { data } = await api.post('/auth/login', {
          email: email.trim().toLowerCase(),
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
          'Authentication failed. Please verify credentials or server connection.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-4 py-12 bg-[#F8FAFC]">
      <div className="w-full max-w-lg rounded-3xl border border-slate-200/90 bg-white p-8 shadow-2xl shadow-slate-900/5">
        {/* Official University Flagship Header with Uploaded Logo */}
        <div className="flex items-center justify-between mb-6 pb-4 border-b border-slate-100">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white p-1.5 shadow-md shadow-slate-900/10 border border-[#C59B27]/50 overflow-hidden">
              <img
                src="/presidency_logo.png"
                alt="Presidency University Official Logo"
                className="h-full w-full object-contain"
                onError={(e) => {
                  e.target.style.display = 'none';
                }}
              />
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
            OFFICIAL CAS
          </span>
        </div>

        {/* Auth Mode Toggle Tabs */}
        <div className="mb-6 grid grid-cols-2 gap-1 rounded-2xl bg-slate-100 p-1 border border-slate-200">
          <button
            type="button"
            onClick={() => {
              setIsRegister(false);
              setError('');
              setSuccessMsg('');
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
              setSuccessMsg('');
            }}
            className={`rounded-xl py-2 text-xs font-bold transition ${
              isRegister
                ? 'bg-white text-[#0F294A] shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Register Account
          </button>
        </div>

        {/* Central Institutional Security Banner (Replaced demo pills) */}
        <div className="mb-6 rounded-2xl border border-[#0F294A]/10 bg-[#0F294A]/[0.03] p-3.5">
          <div className="flex items-center gap-2 text-xs font-bold text-[#0F294A]">
            <ShieldCheck className="h-4 w-4 text-[#C59B27] shrink-0" />
            <span>Presidency University Central Authentication Service</span>
          </div>
          <p className="mt-1 text-xs leading-relaxed text-slate-500">
            {isRegister
              ? 'Institutional registration is strictly reserved for Students and Faculty Coordinators. Use your university credentials to establish your access profile.'
              : 'Enter your registered university email and password to open the live spatial infrastructure command console.'}
          </p>
        </div>

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
                    placeholder="e.g. Student / Faculty Name"
                    className="w-full rounded-xl border border-slate-200 bg-slate-50/50 py-2.5 pl-10 pr-3.5 text-sm font-medium text-slate-900 placeholder:text-slate-400 focus:border-[#0F294A] focus:bg-white focus:outline-none focus:ring-4 focus:ring-[#0F294A]/10 transition"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="mb-1.5 block text-[11px] font-bold uppercase tracking-wider text-slate-600">
                    Campus Role *
                  </label>
                  <select
                    value={role}
                    onChange={(e) => setRole(e.target.value)}
                    className="w-full rounded-xl border border-slate-200 bg-slate-50/50 py-2.5 px-3 text-sm font-medium text-slate-900 focus:border-[#0F294A] focus:bg-white focus:outline-none"
                  >
                    <option value="STUDENT">Student</option>
                    <option value="FACULTY_COORDINATOR">Faculty Coordinator</option>
                  </select>
                </div>

                <div>
                  <label className="mb-1.5 block text-[11px] font-bold uppercase tracking-wider text-slate-600">
                    {role === 'FACULTY_COORDINATOR' ? 'Faculty Employee ID *' : 'Student Reg / Roll No. *'}
                  </label>
                  <div className="relative">
                    <GraduationCap className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                    <input
                      type="text"
                      required
                      value={regNo}
                      onChange={(e) => setRegNo(e.target.value)}
                      placeholder={role === 'FACULTY_COORDINATOR' ? 'e.g. PU-FAC-1042' : 'e.g. 20252MCA0101'}
                      className="w-full rounded-xl border border-slate-200 bg-slate-50/50 py-2.5 pl-10 pr-3.5 text-sm font-medium text-slate-900 placeholder:text-slate-400 focus:border-[#0F294A] focus:bg-white focus:outline-none focus:ring-4 focus:ring-[#0F294A]/10 transition"
                    />
                  </div>
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
                ? 'Create Verified Account'
                : 'Enter Command Center'}
            </span>
            {!loading && <ArrowRight className="h-4 w-4 text-[#C59B27]" />}
          </button>
        </form>

        {/* Security & Support Footer */}
        <div className="mt-6 pt-4 border-t border-slate-100 flex flex-col items-center gap-2 text-center">
          <div className="flex items-center gap-1.5 text-[11px] text-slate-400 font-medium">
            <ShieldCheck className="h-3.5 w-3.5 text-slate-400" />
            <span>Presidency University AI Infrastructure Node • 256-bit TLS Encrypted</span>
          </div>
          <div className="flex items-center gap-1 text-[11px] text-slate-500">
            <HelpCircle className="h-3 w-3 text-slate-400" />
            <span>IT Helpdesk: <span className="font-mono text-slate-600">it.helpdesk@presidencyuniversity.in</span></span>
          </div>
        </div>
      </div>
    </div>
  );
}