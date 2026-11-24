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
import api, { socket, API_BASE_URL } from '../services/api';
import CampusMap from '../components/CampusMap';
import AnalyticsCharts from '../components/AnalyticsCharts';
import SimulateReportModal from '../components/SimulateReportModal';

export default function Dashboard({ user, onLogout }) {
  const [tickets, setTickets] = useState([]);
  const [simRunning, setSimRunning] = useState(false);
  const [socketConnected, setSocketConnected] = useState(socket.connected);
  const [filterSeverity, setFilterSeverity] = useState('ALL');
  const [filterStatus, setFilterStatus] = useState('ALL');
  const [seeding, setSeeding] = useState(false);
  const [isSimModalOpen, setIsSimModalOpen] = useState(false);
  const [liveToast, setLiveToast] = useState(null);

  const showToast = (msg) => {
    setLiveToast(msg);
    setTimeout(() => setLiveToast(null), 4000);
  };

  useEffect(() => {
    const fetchInitial = async () => {
      try {
        const [ticketsRes, simRes] = await Promise.all([
          api.get('/tickets'),
          api.get('/tickets/simulation/status'),
        ]);
        setTickets(ticketsRes.data);
        setSimRunning(simRes.data.running);
      } catch (err) {
        console.error('Failed to load initial telemetry:', err);
      }
    };

    fetchInitial();

    socket.on('connect', () => setSocketConnected(true));
    socket.on('disconnect', () => setSocketConnected(false));

    socket.on('ticket:created', (newTicket) => {
      setTickets((prev) => {
        if (prev.some((t) => t._id === newTicket._id)) return prev;
        return [newTicket, ...prev];
      });
      showToast(`NEW ${newTicket.severity} INCIDENT: ${newTicket.title}`);
    });

    socket.on('ticket:updated', (updated) => {
      setTickets((prev) => prev.map((t) => (t._id === updated._id ? updated : t)));
    });

    socket.on('ticket:deleted', (deletedId) => {
      setTickets((prev) => prev.filter((t) => t._id !== deletedId));
    });

    socket.on('tickets:seeded', (allTickets) => {
      setTickets(allTickets);
      showToast('6 Campus Demo Incidents injected into MongoDB');
    });

    socket.on('tickets:cleared', () => {
      setTickets([]);
      showToast('All campus hazards and incidents purged from database');
    });

    socket.on('simulation:state', ({ running }) => {
      setSimRunning(running);
    });

    return () => {
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
      alert('Failed to seed demo incidents');
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
      setTickets([]);
      showToast('All campus incident records have been purged.');
    } catch (err) {
      alert('Failed to purge incidents: ' + (err.response?.data?.message || err.message));
    }
  };

  const handleStatusChange = async (id, status) => {
    try {
      await api.patch(`/tickets/${id}/status`, { status });
      showToast(`Ticket updated to ${status}`);
    } catch (err) {
      alert('Status update failed');
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
      return matchSev && matchStat;
    });
  }, [tickets, filterSeverity, filterStatus]);

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
              </div>
              <p className="text-xs font-semibold text-[#C59B27]/90">
                Presidency University • Official Infrastructure Command Portal
              </p>
            </div>
          </div>

          {/* Judge Demo & Real-Time Simulation Controls */}
          <div className="flex flex-wrap items-center gap-1.5 sm:gap-2">
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
                      <img
                        src={`${API_BASE_URL}${ticket.imageUrl}`}
                        alt={ticket.title}
                        className="mt-2.5 h-32 w-full rounded-xl border border-slate-200 object-cover"
                      />
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
                    <div className="flex items-center gap-1.5">
                      {ticket.status === 'OPEN' && (
                        <button
                          onClick={() => handleStatusChange(ticket._id, 'IN_PROGRESS')}
                          className="rounded-lg bg-amber-500 px-2.5 py-1 text-xs font-bold text-white hover:bg-amber-600 transition"
                        >
                          Dispatch
                        </button>
                      )}
                      {ticket.status !== 'RESOLVED' && (
                        <button
                          onClick={() => handleStatusChange(ticket._id, 'RESOLVED')}
                          className="rounded-lg bg-emerald-600 px-2.5 py-1 text-xs font-bold text-white hover:bg-emerald-700 transition"
                        >
                          Resolve
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>

      <SimulateReportModal isOpen={isSimModalOpen} onClose={() => setIsSimModalOpen(false)} />
    </div>
  );
}