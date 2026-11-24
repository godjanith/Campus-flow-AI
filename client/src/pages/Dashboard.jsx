import React, { useEffect, useState, useMemo } from 'react';
import {
  BoltIcon,
  PlayIcon,
  StopIcon,
  SparklesIcon,
  ArrowDownTrayIcon,
  PlusCircleIcon,
  ArrowRightOnRectangleIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  ClockIcon,
  CpuChipIcon,
  TrashIcon,
} from '@heroicons/react/24/outline';
import api, { socket, API_BASE_URL, updateBackendUrl } from '../services/api';
import CampusMap from '../components/CampusMap';
import AnalyticsCharts from '../components/AnalyticsCharts';
import SimulateReportModal from '../components/SimulateReportModal';
import { DEFAULT_CAMPUS_TICKETS } from '../utils/defaultTickets';

export default function Dashboard({ user, onLogout }) {
  const isAdmin = user?.role === 'ADMIN' || user?.role === 'FACULTY_COORDINATOR';
  const [tickets, setTickets] = useState(() => {
    try {
      const saved = localStorage.getItem('campusflow_cached_tickets');
      if (saved) {
        const parsed = JSON.parse(saved);
        // Prune older 6-issue demo set down to the 2 requested by user
        if (parsed.length > 2 && parsed.some((t) => t.ticketCode === 'CF-618492' || t.ticketCode === 'CF-503819')) {
          localStorage.setItem('campusflow_cached_tickets', JSON.stringify(DEFAULT_CAMPUS_TICKETS));
          return DEFAULT_CAMPUS_TICKETS;
        }
        return parsed;
      }
    } catch {}
    return DEFAULT_CAMPUS_TICKETS;
  });
  const [simRunning, setSimRunning] = useState(false);
  const [socketConnected, setSocketConnected] = useState(socket.connected);
  const [filterSeverity, setFilterSeverity] = useState('ALL');
  const [filterStatus, setFilterStatus] = useState('ALL');
  const [filterScope, setFilterScope] = useState('ALL');
  const [seeding, setSeeding] = useState(false);
  const [isSimModalOpen, setIsSimModalOpen] = useState(false);
  const [isNodeModalOpen, setIsNodeModalOpen] = useState(false);
  const [previewImage, setPreviewImage] = useState(null);
  const [customNodeUrl, setCustomNodeUrl] = useState(API_BASE_URL);
  const [liveToast, setLiveToast] = useState(null);

  const resolveImageUrl = (img) => {
    if (!img) return null;
    if (img.startsWith('http://') || img.startsWith('https://') || img.startsWith('data:')) {
      return img;
    }
    const base = API_BASE_URL.replace(/\/api\/?$/, '').replace(/\/$/, '');
    return `${base}${img.startsWith('/') ? '' : '/'}${img}`;
  };

  const showToast = (msg) => {
    setLiveToast(msg);
    setTimeout(() => setLiveToast(null), 4000);
  };

  const handleTicketCreated = (newTicket) => {
    setTickets((prev) => {
      if (prev.some((t) => t._id === newTicket._id || (t.ticketCode && t.ticketCode === newTicket.ticketCode))) {
        return prev;
      }
      const updated = [newTicket, ...prev];
      try {
        localStorage.setItem('campusflow_cached_tickets', JSON.stringify(updated));
      } catch {}
      return updated;
    });
    showToast(`NEW ${newTicket.severity || 'CAMPUS'} INCIDENT: ${newTicket.title}`);
  };

  useEffect(() => {
    const fetchInitial = async () => {
      try {
        const [ticketsRes, simRes] = await Promise.all([
          api.get('/tickets'),
          api.get('/tickets/simulation/status'),
        ]);
        if (Array.isArray(ticketsRes.data) && ticketsRes.data.length > 0) {
          setTickets(ticketsRes.data);
          localStorage.setItem('campusflow_cached_tickets', JSON.stringify(ticketsRes.data));
        } else {
          setTickets(DEFAULT_CAMPUS_TICKETS);
        }
        setSimRunning(simRes?.data?.running || false);
      } catch (err) {
        console.warn('Backend server currently offline or unreachable. Loaded resilient campus incidents:', err);
        const cached = localStorage.getItem('campusflow_cached_tickets');
        if (cached) {
          setTickets(JSON.parse(cached));
        } else {
          setTickets(DEFAULT_CAMPUS_TICKETS);
        }
      }
    };

    fetchInitial();

    // High-speed dual-sync polling: ensures any incident created on Mobile reflects on Desktop within 2.5s
    const pollInterval = setInterval(async () => {
      try {
        const { data } = await api.get('/tickets');
        if (Array.isArray(data)) {
          setTickets((prev) => {
            const hasChanges =
              data.length !== prev.length ||
              data.some((t, i) => prev[i]?._id !== t._id || prev[i]?.status !== t.status);
            if (hasChanges) {
              try {
                localStorage.setItem('campusflow_cached_tickets', JSON.stringify(data));
              } catch {}
              return data;
            }
            return prev;
          });
        }
      } catch (_) {}
    }, 2500);

    socket.on('connect', () => setSocketConnected(true));
    socket.on('disconnect', () => setSocketConnected(false));

    socket.on('ticket:created', (newTicket) => {
      setTickets((prev) => {
        if (prev.some((t) => t._id === newTicket._id || (t.ticketCode && t.ticketCode === newTicket.ticketCode))) return prev;
        const updated = [newTicket, ...prev];
        try { localStorage.setItem('campusflow_cached_tickets', JSON.stringify(updated)); } catch {}
        return updated;
      });
      showToast(`NEW ${newTicket.severity} INCIDENT: ${newTicket.title}`);
    });

    socket.on('ticket:updated', (updated) => {
      setTickets((prev) => {
        const list = prev.map((t) => (t._id === updated._id ? updated : t));
        try { localStorage.setItem('campusflow_cached_tickets', JSON.stringify(list)); } catch {}
        return list;
      });
    });

    socket.on('ticket:deleted', (deletedId) => {
      setTickets((prev) => {
        const list = prev.filter((t) => t._id !== deletedId);
        try { localStorage.setItem('campusflow_cached_tickets', JSON.stringify(list)); } catch {}
        return list;
      });
    });

    socket.on('tickets:seeded', (allTickets) => {
      setTickets(allTickets);
      try { localStorage.setItem('campusflow_cached_tickets', JSON.stringify(allTickets)); } catch {}
      showToast('Campus Demo Incidents injected into MongoDB');
    });

    socket.on('tickets:cleared', () => {
      setTickets([]);
      try { localStorage.removeItem('campusflow_cached_tickets'); } catch {}
      showToast('All campus hazards and incidents purged from database');
    });

    socket.on('simulation:state', ({ running }) => {
      setSimRunning(running);
    });

    return () => {
      clearInterval(pollInterval);
      socket.off('connect');
      socket.off('disconnect');
      socket.off('ticket:created');
      socket.off('ticket:updated');
      socket.off('ticket:deleted');
      socket.off('tickets:seeded');
      socket.off('tickets:cleared');
      socket.off('simulation:state');
    };
  }, []);

  const handleToggleSimulation = async () => {
    try {
      const { data } = await api.post('/tickets/simulation/toggle');
      setSimRunning(data.running);
      showToast(
        data.running
          ? 'Live Campus Telemetry Simulation STARTED (7s interval)'
          : 'Live Campus Telemetry Simulation PAUSED'
      );
    } catch (err) {
      alert('Failed to toggle simulation');
    }
  };

  const handleSeedDemo = async () => {
    setSeeding(true);
    try {
      await api.post('/tickets/seed');
    } catch (err) {
      console.warn('Backend unavailable for seeding, loaded default campus incidents locally:', err);
      setTickets(DEFAULT_CAMPUS_TICKETS);
      try {
        localStorage.setItem('campusflow_cached_tickets', JSON.stringify(DEFAULT_CAMPUS_TICKETS));
      } catch {}
      showToast('6 Official Campus Demo Incidents loaded locally');
    } finally {
      setSeeding(false);
    }
  };

  const handlePurgeAll = async () => {
    if (
      !window.confirm(
        'Are you sure you want to purge all active incident records? This will clear the campus hazard map and empty the complaints database.'
      )
    ) {
      return;
    }
    try {
      await api.delete('/tickets/purge/all');
    } catch (err) {
      console.warn('Backend purge call offline, clearing local incident ledger:', err);
    }
    setTickets([]);
    try {
      localStorage.removeItem('campusflow_cached_tickets');
    } catch {}
    showToast('All campus incident records have been purged.');
  };

  const handleStatusChange = async (id, status) => {
    setTickets((prev) => {
      const updated = prev.map((t) => (t._id === id ? { ...t, status } : t));
      try {
        localStorage.setItem('campusflow_cached_tickets', JSON.stringify(updated));
      } catch {}
      return updated;
    });
    showToast(`Ticket status updated to ${status}`);
    try {
      await api.patch(`/tickets/${id}/status`, { status });
    } catch (err) {
      console.warn('Server offline, updated ticket status locally:', err);
    }
  };

  const handleExportCSV = () => {
    const headers = [
      'Ticket Code',
      'Title',
      'Building',
      'Category',
      'Severity',
      'Status',
      'AI Engine',
      'ETA',
      'Reported By',
      'Created At',
    ];
    const rows = filteredTickets.map((t) => [
      t.ticketCode,
      `"${t.title.replace(/"/g, '""')}"`,
      `"${t.building}"`,
      `"${t.category}"`,
      t.severity,
      t.status,
      t.triageEngineUsed,
      `"${t.estimatedResolutionTime}"`,
      `"${t.reportedBy?.name || 'Student'}"`,
      new Date(t.createdAt).toISOString(),
    ]);

    const csvContent =
      'data:text/csv;charset=utf-8,' +
      [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `campusflow_audit_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const filteredTickets = useMemo(() => {
    return tickets.filter((t) => {
      const matchSev = filterSeverity === 'ALL' || t.severity === filterSeverity;
      const matchStat = filterStatus === 'ALL' || t.status === filterStatus;
      let matchScope = true;
      if (filterScope === 'MY') {
        const userReg = (user?.regNo || '').toLowerCase().trim();
        const userName = (user?.name || '').toLowerCase().trim();
        const repReg = (t.reportedBy?.regNo || '').toLowerCase().trim();
        const repName = (t.reportedBy?.name || '').toLowerCase().trim();
        matchScope = (userReg && repReg === userReg) ||
                     (userName && repName.includes(userName)) ||
                     (repName && userName.includes(repName));
      }
      return matchSev && matchStat && matchScope;
    });
  }, [tickets, filterSeverity, filterStatus, filterScope, user]);

  const stats = useMemo(() => {
    return {
      total: tickets.length,
      critical: tickets.filter((t) => t.severity === 'CRITICAL' && t.status !== 'RESOLVED').length,
      inProgress: tickets.filter((t) => t.status === 'IN_PROGRESS').length,
      resolved: tickets.filter((t) => t.status === 'RESOLVED').length,
    };
  }, [tickets]);

  return (
    <div className="min-h-screen pb-12">
      {/* Live Socket Notification Banner */}
      {liveToast && (
        <div className="fixed bottom-5 right-5 z-[1100] flex items-center gap-2.5 rounded-2xl border border-indigo-200 bg-white px-4 py-3 text-xs font-bold text-slate-900 shadow-xl">
          <span className="h-2.5 w-2.5 animate-ping rounded-full bg-indigo-600"></span>
          <span>{liveToast}</span>
        </div>
      )}

      {/* Vercel Cloud Sync Guidance Banner */}
      {typeof window !== 'undefined' && window.location.hostname.includes('vercel.app') && (
        <div className="bg-[#C59B27] text-slate-950 px-4 py-2 text-xs font-bold flex flex-wrap items-center justify-between gap-2 border-b border-amber-600 shadow-sm">
          <div className="flex items-center gap-2">
            <span className="text-sm">⚡</span>
            <span>
              You are viewing the Vercel Cloud Preview. To synchronize live with your physical phone (<strong>ZD222KW7QR</strong>), open <strong>http://localhost:5000</strong> on this computer!
            </span>
          </div>
          <a
            href="http://localhost:5000"
            target="_blank"
            rel="noreferrer"
            className="bg-[#0F294A] text-white px-3 py-1 rounded-lg text-[11px] font-bold hover:bg-slate-800 transition"
          >
            Open Local Sync Hub (Port 5000) ↗
          </a>
        </div>
      )}

      {/* Top Glass Navigation Bar */}
      <header className="sticky top-0 z-[500] border-b-2 border-b-[#C59B27] bg-[#0F294A] text-white shadow-md">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4 px-4 py-3.5 sm:px-6">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-white p-1 shadow-sm border border-[#C59B27]/60 overflow-hidden">
              <img
                src="/presidency_logo.png"
                alt="Presidency University"
                className="h-full w-full object-contain"
                onError={(e) => {
                  e.target.style.display = 'none';
                }}
              />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-lg font-black tracking-tight text-white">
                  CampusFlow <span className="text-[#C59B27]">AI</span>
                </h1>
                <span
                  className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 font-mono text-[10px] font-bold ${
                    socketConnected
                      ? 'bg-emerald-950/80 text-emerald-400 border border-emerald-500/40'
                      : 'bg-red-950/80 text-red-400 border border-red-500/40'
                  }`}
                >
                  <span
                    className={`h-1.5 w-1.5 rounded-full ${
                      socketConnected ? 'bg-emerald-400 animate-pulse' : 'bg-red-400'
                    }`}
                  ></span>
                  {socketConnected ? 'SOCKET LIVE' : 'OFFLINE'}
                </span>
                <button
                  type="button"
                  onClick={() => setIsNodeModalOpen(true)}
                  title="Configure Target Server Node"
                  className="hidden sm:inline-flex items-center gap-1 font-mono text-[9.5px] font-bold text-[#C59B27] bg-[#C59B27]/15 hover:bg-[#C59B27]/30 border border-[#C59B27]/40 rounded-full px-2.5 py-0.5 transition cursor-pointer"
                >
                  Node: {API_BASE_URL.replace(/^https?:\/\//, '')}
                </button>
                <span className={`rounded-full px-2 py-0.5 font-mono text-[9px] font-bold ${
                  isAdmin
                    ? 'bg-amber-400/20 text-amber-300 border border-amber-400/40'
                    : 'bg-cyan-400/20 text-cyan-300 border border-cyan-400/40'
                }`}>
                  {isAdmin ? 'ADMIN COMMAND' : `STUDENT • ${user?.regNo || 'VERIFIED'}`}
                </span>
              </div>
              <p className="text-xs font-semibold text-[#C59B27]/90">
                {isAdmin
                  ? 'Presidency University • Official Infrastructure Command Portal'
                  : 'Presidency University • Student Incident & Safety Portal'}
              </p>
            </div>
          </div>

          {/* Role-Based Controls (Admin vs Student) */}
          <div className="flex flex-wrap items-center gap-1.5 sm:gap-2">
            {isAdmin ? (
              <>
                <button
                  onClick={handleToggleSimulation}
                  className={`inline-flex items-center gap-1 rounded-xl px-2.5 py-2 text-[11px] font-bold transition shadow-sm sm:gap-1.5 sm:px-3.5 sm:text-xs ${
                    simRunning
                      ? 'bg-rose-600 text-white hover:bg-rose-700'
                      : 'bg-emerald-600 text-white hover:bg-emerald-700'
                  }`}
                >
                  {simRunning ? (
                    <>
                      <StopIcon className="h-3.5 w-3.5 sm:h-4 sm:w-4" /> <span className="hidden sm:inline">Stop</span> Auto-Sim
                    </>
                  ) : (
                    <>
                      <PlayIcon className="h-3.5 w-3.5 sm:h-4 sm:w-4" /> <span className="hidden sm:inline">Live</span> Auto-Sim
                    </>
                  )}
                </button>

                <button
                  onClick={() => setIsSimModalOpen(true)}
                  className="inline-flex items-center gap-1 rounded-xl border border-[#C59B27]/50 bg-white/10 px-2.5 py-2 text-[11px] font-bold text-white hover:bg-white/20 transition sm:gap-1.5 sm:px-3.5 sm:text-xs"
                >
                  <PlusCircleIcon className="h-3.5 w-3.5 text-[#C59B27] sm:h-4 sm:w-4" /> <span className="hidden sm:inline">Inject</span> Incident
                </button>

                <button
                  onClick={handleSeedDemo}
                  disabled={seeding}
                  className="inline-flex items-center gap-1 rounded-xl border border-slate-200 bg-white px-2.5 py-2 text-[11px] font-bold text-slate-700 hover:bg-slate-50 transition sm:gap-1.5 sm:px-3.5 sm:text-xs"
                >
                  <SparklesIcon className="h-3.5 w-3.5 text-amber-500 sm:h-4 sm:w-4" />
                  {seeding ? 'Seeding...' : 'Seed Demo'}
                </button>

                <button
                  onClick={handlePurgeAll}
                  title="Empty all complaints and clear campus grid"
                  className="inline-flex items-center gap-1 rounded-xl border border-rose-300 bg-rose-50 px-2.5 py-2 text-[11px] font-bold text-rose-700 hover:bg-rose-100 transition shadow-xs sm:gap-1.5 sm:px-3.5 sm:text-xs"
                >
                  <TrashIcon className="h-3.5 w-3.5 text-rose-600 sm:h-4 sm:w-4" />
                  <span className="hidden sm:inline">Empty</span> Purge
                </button>
              </>
            ) : (
              <button
                onClick={() => setIsSimModalOpen(true)}
                className="inline-flex items-center gap-1.5 rounded-xl bg-[#C59B27] px-3.5 py-2 text-xs font-bold text-slate-900 hover:bg-amber-400 transition shadow-sm"
              >
                <PlusCircleIcon className="h-4 w-4" /> Report New Incident
              </button>
            )}

            <button
              onClick={handleExportCSV}
              title="Export CSV"
              className="inline-flex items-center gap-1 rounded-xl border border-slate-200 bg-white px-2.5 py-2 text-[11px] font-bold text-slate-700 hover:bg-slate-50 transition sm:gap-1.5 sm:px-3.5 sm:text-xs"
            >
              <ArrowDownTrayIcon className="h-3.5 w-3.5 text-slate-500 sm:h-4 sm:w-4" /> CSV
            </button>

            <button
              onClick={onLogout}
              title="Sign Out"
              className="rounded-xl border border-slate-200 bg-white p-2 text-slate-500 hover:bg-red-50 hover:text-red-600 transition"
            >
              <ArrowRightOnRectangleIcon className="h-4 w-4" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Command Center Container */}
      <main className="mx-auto max-w-7xl space-y-6 px-4 pt-6 sm:px-6">
        {/* KPI Telemetry Row */}
        <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
          <div className="rounded-2xl border border-slate-200/90 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Total Logged
              </span>
              <CpuChipIcon className="h-5 w-5 text-[#0F294A]" />
            </div>
            <p className="mt-2 text-3xl font-extrabold text-slate-900">{stats.total}</p>
            <p className="mt-1 text-xs font-medium text-slate-500">Synced with MongoDB Compass</p>
          </div>

          <div className="rounded-2xl border border-red-200/80 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-red-500">
                Active Critical
              </span>
              <ExclamationTriangleIcon className="h-5 w-5 text-red-600" />
            </div>
            <p className="mt-2 text-3xl font-extrabold text-red-600">{stats.critical}</p>
            <p className="mt-1 text-xs font-medium text-slate-500">Immediate hazard response</p>
          </div>

          <div className="rounded-2xl border border-amber-200/80 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-amber-600">
                Crews Dispatched
              </span>
              <ClockIcon className="h-5 w-5 text-amber-500" />
            </div>
            <p className="mt-2 text-3xl font-extrabold text-amber-600">{stats.inProgress}</p>
            <p className="mt-1 text-xs font-medium text-slate-500">Field engineers on-site</p>
          </div>

          <div className="rounded-2xl border border-emerald-200/80 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-emerald-600">
                Resolved
              </span>
              <CheckCircleIcon className="h-5 w-5 text-emerald-600" />
            </div>
            <p className="mt-2 text-3xl font-extrabold text-emerald-600">{stats.resolved}</p>
            <p className="mt-1 text-xs font-medium text-slate-500">Verified SLA closure</p>
          </div>
        </div>

        {/* Spatial Twin Map + Analytics Grid */}
        <div className="grid grid-cols-1 gap-6 xl:grid-cols-12">
          <div className="xl:col-span-7">
            <div className="mb-2.5 flex items-center justify-between">
              <h2 className="text-sm font-extrabold uppercase tracking-wider text-slate-700">
                Live Geospatial Campus Twin
              </h2>
              <span className="text-xs font-medium text-slate-500">
                Click any pulsing beacon to inspect AI brief & dispatch
              </span>
            </div>
            <CampusMap
              tickets={filteredTickets}
              apiBaseUrl={API_BASE_URL}
              onStatusChange={handleStatusChange}
              isAdmin={isAdmin}
            />
          </div>

          <div className="xl:col-span-5 flex flex-col justify-between space-y-4">
            <div className="mb-0.5 flex items-center justify-between">
              <h2 className="text-sm font-extrabold uppercase tracking-wider text-slate-700">
                AI Telemetry & SLA Breakdown
              </h2>
              <span className="font-mono text-xs text-[#0F294A] font-bold">
                {simRunning ? 'STREAMING LIVE' : 'STANDBY'}
              </span>
            </div>
            <AnalyticsCharts tickets={tickets} />
          </div>
        </div>

        {/* Live Incident Feed & Dispatch Queue */}
        <div className="rounded-2xl border border-slate-200/90 bg-white p-6 shadow-sm">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-4 border-b border-slate-100 pb-4">
            <div>
              <h2 className="text-base font-extrabold text-slate-900">
                Real-Time Incident Triage & Dispatch Ledger
              </h2>
              <p className="text-xs text-slate-500">
                Every submission is autonomously classified, assigned an SLA target, and pushed via WebSockets.
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <div className="flex rounded-xl bg-slate-100 p-0.5 border border-slate-200 text-xs font-bold">
                <button
                  type="button"
                  onClick={() => setFilterScope('ALL')}
                  className={`rounded-lg px-2.5 py-1 transition ${
                    filterScope === 'ALL'
                      ? 'bg-white text-slate-900 shadow-xs'
                      : 'text-slate-500 hover:text-slate-800'
                  }`}
                >
                  All Incidents
                </button>
                <button
                  type="button"
                  onClick={() => setFilterScope('MY')}
                  className={`rounded-lg px-2.5 py-1 transition ${
                    filterScope === 'MY'
                      ? 'bg-white text-slate-900 shadow-xs'
                      : 'text-slate-500 hover:text-slate-800'
                  }`}
                >
                  My Submissions
                </button>
              </div>

              <select
                value={filterSeverity}
                onChange={(e) => setFilterSeverity(e.target.value)}
                className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-bold text-slate-700 focus:outline-none"
              >
                <option value="ALL">All Severities</option>
                <option value="CRITICAL">Critical Only</option>
                <option value="HIGH">High Only</option>
                <option value="MEDIUM">Medium Only</option>
                <option value="LOW">Low Only</option>
              </select>

              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-bold text-slate-700 focus:outline-none"
              >
                <option value="ALL">All Statuses</option>
                <option value="OPEN">Open</option>
                <option value="IN_PROGRESS">In Progress</option>
                <option value="RESOLVED">Resolved</option>
              </select>
            </div>
          </div>

          {filteredTickets.length === 0 ? (
            <div className="py-12 text-center">
              <p className="text-sm font-semibold text-slate-600">
                No incidents match your current filter.
              </p>
              <p className="mt-1 text-xs text-slate-400">
                Click "Seed 6 Incidents" or "Live Auto-Sim" in the top bar to populate real-time data.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
              {filteredTickets.map((ticket) => (
                <div
                  key={ticket._id}
                  className="flex flex-col justify-between rounded-2xl border border-slate-200/90 bg-white p-4 hover:border-[#C59B27] hover:shadow-md transition shadow-xs"
                >
                  <div>
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-mono text-xs font-black text-[#0F294A] bg-slate-100 px-2 py-0.5 rounded-md">
                        {ticket.ticketCode}
                      </span>
                      <div className="flex items-center gap-1.5">
                        <span
                          className={`rounded-full px-2.5 py-0.5 text-[10px] font-extrabold ${
                            ticket.severity === 'CRITICAL'
                              ? 'bg-red-100 text-red-700'
                              : ticket.severity === 'HIGH'
                              ? 'bg-orange-100 text-orange-700'
                              : ticket.severity === 'MEDIUM'
                              ? 'bg-blue-100 text-blue-700'
                              : 'bg-slate-200 text-slate-700'
                          }`}
                        >
                          {ticket.severity}
                        </span>
                        <span
                          className={`rounded-full px-2.5 py-0.5 text-[10px] font-extrabold ${
                            ticket.status === 'RESOLVED'
                              ? 'bg-emerald-100 text-emerald-700'
                              : ticket.status === 'IN_PROGRESS'
                              ? 'bg-amber-100 text-amber-800'
                              : 'bg-slate-200 text-slate-700'
                          }`}
                        >
                          {ticket.status}
                        </span>
                      </div>
                    </div>

                    <h3 className="mt-2 text-sm font-bold text-slate-900">{ticket.title}</h3>
                    <p className="mt-0.5 text-xs font-semibold text-slate-500">
                      {ticket.building} • {ticket.category}
                    </p>

                    {ticket.imageUrl && (
                      <div
                        onClick={() =>
                          setPreviewImage({
                            url: resolveImageUrl(ticket.imageUrl),
                            title: ticket.title,
                            code: ticket.ticketCode,
                            building: ticket.building,
                            category: ticket.category,
                            severity: ticket.severity,
                            reporter: `${ticket.reportedBy?.name || 'Student'} (${ticket.reportedBy?.regNo || 'Verified'})`,
                          })
                        }
                        className="group relative mt-3 cursor-pointer overflow-hidden rounded-xl border border-slate-200 bg-slate-900 shadow-sm transition hover:border-[#C59B27]"
                      >
                        <img
                          src={resolveImageUrl(ticket.imageUrl)}
                          alt={ticket.title}
                          className="h-36 w-full object-cover transition duration-300 group-hover:scale-105"
                          onError={(e) => {
                            e.target.style.display = 'none';
                          }}
                        />
                        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-black/20 opacity-90 transition group-hover:opacity-100" />
                        <div className="absolute bottom-2 left-2.5 right-2.5 flex items-center justify-between text-white">
                          <span className="flex items-center gap-1.5 rounded-md bg-black/60 px-2 py-0.5 text-[10px] font-bold backdrop-blur border border-white/20">
                            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                            Student Field Photo
                          </span>
                          <span className="flex items-center gap-1 text-[10px] font-bold text-[#C59B27] group-hover:underline">
                            Inspect 🔍
                          </span>
                        </div>
                      </div>
                    )}

                    <div className="mt-3 rounded-xl border border-[#C59B27]/30 bg-amber-50/30 p-2.5 text-xs text-slate-700">
                      <p className="font-bold text-[#0F294A]">{ticket.aiSummary}</p>
                      <p className="mt-1 text-[11px] text-slate-500">
                        <strong className="text-slate-700">Safety Protocol:</strong>{' '}
                        {ticket.safetyAdvisory}
                      </p>
                    </div>
                  </div>

                  <div className="mt-4 flex items-center justify-between border-t border-slate-200/70 pt-3">
                    <span className="font-mono text-[11px] text-slate-500">
                      ETA: {ticket.estimatedResolutionTime}
                    </span>
                    {isAdmin ? (
                      <div className="flex items-center gap-1.5">
                        {ticket.status === 'OPEN' && (
                          <button
                            onClick={() => handleStatusChange(ticket._id, 'IN_PROGRESS')}
                            className="rounded-lg bg-amber-500 px-2.5 py-1 text-xs font-bold text-white hover:bg-amber-600 transition cursor-pointer"
                          >
                            Dispatch
                          </button>
                        )}
                        {ticket.status !== 'RESOLVED' && (
                          <button
                            onClick={() => handleStatusChange(ticket._id, 'RESOLVED')}
                            className="rounded-lg bg-emerald-600 px-2.5 py-1 text-xs font-bold text-white hover:bg-emerald-700 transition cursor-pointer"
                          >
                            Resolve
                          </button>
                        )}
                      </div>
                    ) : (
                      <span className="font-mono text-[11px] font-bold text-slate-600 bg-slate-100 px-2.5 py-1 rounded-md border border-slate-200">
                        {ticket.status}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>

      <SimulateReportModal
        isOpen={isSimModalOpen}
        onClose={() => setIsSimModalOpen(false)}
        user={user}
        onTicketCreated={handleTicketCreated}
      />

      {/* Target Backend Node Connection Modal */}
      {isNodeModalOpen && (
        <div className="fixed inset-0 z-[1200] flex items-center justify-center bg-slate-900/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-2xl">
            <h3 className="text-base font-bold text-slate-900">Configure Target Server Node</h3>
            <p className="mt-1 text-xs text-slate-500">
              Point this Web Command Console to your local Node server or tunnel to reflect mobile app submissions in real-time.
            </p>
            <div className="mt-4 space-y-3">
              <div>
                <label className="block text-[11px] font-bold uppercase text-slate-600">
                  Backend API URL
                </label>
                <input
                  type="text"
                  value={customNodeUrl}
                  onChange={(e) => setCustomNodeUrl(e.target.value)}
                  placeholder="http://localhost:5000 or http://172.17.83.174:5000"
                  className="mt-1 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-xs font-mono text-slate-900 focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div className="flex flex-wrap gap-1.5 pt-1">
                <button
                  type="button"
                  onClick={() => setCustomNodeUrl('http://localhost:5000')}
                  className="rounded-lg bg-slate-100 px-2 py-1 text-[11px] font-semibold text-slate-700 hover:bg-slate-200"
                >
                  localhost:5000
                </button>
                <button
                  type="button"
                  onClick={() => setCustomNodeUrl('http://172.17.83.174:5000')}
                  className="rounded-lg bg-slate-100 px-2 py-1 text-[11px] font-semibold text-slate-700 hover:bg-slate-200"
                >
                  172.17.83.174:5000 (LAN)
                </button>
              </div>
            </div>
            <div className="mt-6 flex items-center justify-end gap-2 border-t border-slate-100 pt-4">
              <button
                type="button"
                onClick={() => setIsNodeModalOpen(false)}
                className="rounded-xl px-4 py-2 text-xs font-bold text-slate-600 hover:bg-slate-100"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => {
                  updateBackendUrl(customNodeUrl);
                  setIsNodeModalOpen(false);
                }}
                className="rounded-xl bg-[#0F294A] px-4 py-2 text-xs font-bold text-white hover:bg-slate-800"
              >
                Save & Connect Node
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Full-Screen High-Resolution Student Photo Inspection Modal */}
      {previewImage && (
        <div
          className="fixed inset-0 z-[1300] flex items-center justify-center bg-slate-950/85 p-4 backdrop-blur-md transition"
          onClick={() => setPreviewImage(null)}
        >
          <div
            className="relative max-h-[92vh] w-full max-w-3xl overflow-hidden rounded-2xl border border-slate-700 bg-slate-900 shadow-2xl text-white"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between border-b border-slate-800 px-5 py-3.5 bg-slate-900/90">
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-mono text-xs font-bold text-[#C59B27] bg-[#C59B27]/10 px-2 py-0.5 rounded border border-[#C59B27]/30">
                    {previewImage.code}
                  </span>
                  <h3 className="text-sm font-bold text-white">{previewImage.title}</h3>
                </div>
                <p className="mt-1 text-[11px] text-slate-400">
                  📍 {previewImage.building} &bull; Uploaded by <strong className="text-slate-200">{previewImage.reporter}</strong>
                </p>
              </div>
              <button
                onClick={() => setPreviewImage(null)}
                className="rounded-xl bg-slate-800 p-2 text-slate-300 hover:bg-slate-700 hover:text-white transition"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>
            <div className="flex items-center justify-center bg-black/95 p-3 max-h-[68vh] overflow-hidden">
              <img
                src={previewImage.url}
                alt={previewImage.title}
                className="max-h-[64vh] w-auto max-w-full rounded-lg object-contain shadow-2xl"
              />
            </div>
            <div className="flex items-center justify-between border-t border-slate-800 px-5 py-3 text-xs text-slate-400 bg-slate-900">
              <span className="flex items-center gap-1.5">
                <span className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse"></span>
                Official Student Field Evidence &bull; Facility Engineering Desk
              </span>
              <button
                onClick={() => window.open(previewImage.url, '_blank')}
                className="text-[#C59B27] hover:underline font-bold text-[11px]"
              >
                Open Original Resolution ↗
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}