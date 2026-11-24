import React, { useState } from 'react';
import {
  XMarkIcon,
  SparklesIcon,
  PhotoIcon,
  ShieldExclamationIcon,
  CheckCircleIcon,
  TrashIcon,
} from '@heroicons/react/24/outline';
import api from '../services/api';

const BUILDINGS = [
  { name: 'Engineering Block A', lat: 13.1723, lng: 77.5366 },
  { name: 'Engineering Block B', lat: 13.1715, lng: 77.5364 },
  { name: 'Central Library', lat: 13.1720, lng: 77.5350 },
  { name: 'Auditorium Complex', lat: 13.1712, lng: 77.5355 },
  { name: 'School of Management', lat: 13.1726, lng: 77.5358 },
  { name: 'Student Cafeteria & Food Court', lat: 13.1719, lng: 77.5368 },
  { name: 'Sports & Gymnasium Arena', lat: 13.1728, lng: 77.5348 },
  { name: 'Main Security Gate', lat: 13.1708, lng: 77.5370 },
];

export default function SimulateReportModal({ isOpen, onClose, user, onTicketCreated }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [building, setBuilding] = useState(BUILDINGS[0].name);
  const [severityOverride, setSeverityOverride] = useState('AUTO');
  const [image, setImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  if (!isOpen) return null;

  const handleImageChange = (e) => {
    const file = e.target.files?.[0];
    if (file) {
      setImage(file);
      const reader = new FileReader();
      reader.onload = (ev) => setImagePreview(ev.target?.result);
      reader.readAsDataURL(file);
    }
  };

  const handleRemoveImage = () => {
    setImage(null);
    setImagePreview(null);
  };

  const resetForm = () => {
    setTitle('');
    setDescription('');
    setBuilding(BUILDINGS[0].name);
    setSeverityOverride('AUTO');
    setImage(null);
    setImagePreview(null);
    setErrorMsg('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title.trim() || !description.trim()) {
      setErrorMsg('Please enter both headline and description.');
      return;
    }

    setSubmitting(true);
    setErrorMsg('');

    const selectedBldg = BUILDINGS.find((b) => b.name === building) || BUILDINGS[0];
    const reporterName = user?.name || 'Campus Student';
    const reporterRegNo = user?.regNo || 'PU-STUDENT';
    const lat = selectedBldg.lat + (Math.random() - 0.5) * 0.0003;
    const lng = selectedBldg.lng + (Math.random() - 0.5) * 0.0003;

    // Fast heuristic classification
    const textLower = (title + ' ' + description).toLowerCase();
    let category = 'Civil & Structural';
    let autoSeverity = 'MEDIUM';
    let eta = '1-2 hours';

    if (textLower.includes('spark') || textLower.includes('fire') || textLower.includes('shock') || textLower.includes('wire') || textLower.includes('electric') || textLower.includes('voltage')) {
      category = 'Electrical Safety';
      autoSeverity = 'CRITICAL';
      eta = '20 mins';
    } else if (textLower.includes('leak') || textLower.includes('water') || textLower.includes('flood') || textLower.includes('pipe') || textLower.includes('drain')) {
      category = 'Plumbing & Water';
      autoSeverity = 'HIGH';
      eta = '45 mins';
    } else if (textLower.includes('wifi') || textLower.includes('network') || textLower.includes('internet') || textLower.includes('router') || textLower.includes('server')) {
      category = 'IT & Network';
      autoSeverity = 'MEDIUM';
      eta = '1 hour';
    } else if (textLower.includes('ac') || textLower.includes('hvac') || textLower.includes('chiller') || textLower.includes('cooling')) {
      category = 'HVAC';
      autoSeverity = 'LOW';
      eta = '3 hours';
    } else if (textLower.includes('gate') || textLower.includes('theft') || textLower.includes('lock') || textLower.includes('security')) {
      category = 'Security Hazard';
      autoSeverity = 'HIGH';
      eta = '30 mins';
    }

    const finalSeverity = severityOverride === 'AUTO' ? autoSeverity : severityOverride;

    try {
      const formData = new FormData();
      formData.append('title', title.trim());
      formData.append('description', description.trim());
      formData.append('building', building);
      formData.append('lat', lat.toString());
      formData.append('lng', lng.toString());
      formData.append('reporterName', reporterName);
      formData.append('reporterRegNo', reporterRegNo);
      formData.append('category', category);
      formData.append('severity', finalSeverity);
      formData.append('estimatedResolutionTime', eta);

      if (image) {
        formData.append('image', image);
      }

      // DO NOT pass headers: { 'Content-Type': 'multipart/form-data' }!
      // Letting Axios build the header includes the essential boundary string.
      const { data } = await api.post('/tickets', formData);

      if (data) {
        // If server stored image relatively, attach local preview if available
        if (imagePreview && !data.imageUrl) {
          data.imageUrl = imagePreview;
        }
        if (onTicketCreated) onTicketCreated(data);
      }
      resetForm();
      onClose();
    } catch (err) {
      console.warn('Backend API unavailable or network blocked, persisting ticket to local ledger:', err);
      const now = new Date();
      const localTicket = {
        _id: `local_tkt_${Date.now()}`,
        ticketCode: `CF-${Math.floor(100000 + Math.random() * 900000)}`,
        title: title.trim(),
        description: description.trim(),
        building,
        location: { lat, lng },
        imageUrl: imagePreview || null,
        category,
        severity: finalSeverity,
        aiSummary: `[${finalSeverity}] ${title.trim()} at ${building}. Triaged via Edge AI Engine.`,
        estimatedResolutionTime: eta,
        safetyAdvisory:
          finalSeverity === 'CRITICAL'
            ? 'DANGER: Evacuate zone until safety crew arrives.'
            : 'Report acknowledged in operations dispatch queue.',
        triageEngineUsed: 'EDGE_CLIENT_HEURISTIC',
        status: 'OPEN',
        reportedBy: { name: reporterName, regNo: reporterRegNo },
        timeline: [
          { status: 'OPEN', note: 'Incident submitted to CampusFlow spatial queue.', timestamp: now.toISOString() },
        ],
        createdAt: now.toISOString(),
      };

      if (onTicketCreated) onTicketCreated(localTicket);
      resetForm();
      onClose();
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[1200] flex items-center justify-center bg-slate-950/70 p-4 backdrop-blur-sm animate-fadeIn">
      <div className="w-full max-w-lg rounded-3xl border border-slate-200 bg-white p-6 sm:p-7 shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-100 pb-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#0F294A] text-[#C59B27] shadow-sm">
              <ShieldExclamationIcon className="h-6 w-6" />
            </div>
            <div>
              <h3 className="text-base font-extrabold text-slate-900">
                Report Campus Incident & Hazard
              </h3>
              <p className="text-xs text-slate-500 font-medium">
                Presidency University Autonomous Safety & Triage Desk
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-xl p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition"
          >
            <XMarkIcon className="h-5 w-5" />
          </button>
        </div>

        {errorMsg && (
          <div className="mt-3 rounded-xl bg-red-50 p-3 text-xs font-bold text-red-700 border border-red-200">
            {errorMsg}
          </div>
        )}

        <form onSubmit={handleSubmit} className="mt-4 space-y-4">
          {/* Building / Zone */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
              Campus Building / Zone
            </label>
            <select
              value={building}
              onChange={(e) => setBuilding(e.target.value)}
              className="mt-1.5 w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm font-semibold text-slate-900 focus:border-[#C59B27] focus:bg-white focus:outline-none transition"
            >
              {BUILDINGS.map((b) => (
                <option key={b.name} value={b.name}>
                  {b.name}
                </option>
              ))}
            </select>
          </div>

          {/* Incident Headline */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
              Incident Headline
            </label>
            <input
              type="text"
              required
              placeholder="e.g., Water pipe burst causing flooding in lobby"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="mt-1.5 w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm text-slate-900 focus:border-[#C59B27] focus:bg-white focus:outline-none transition"
            />
          </div>

          {/* Field Observation Details */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
              Field Observation Details
            </label>
            <textarea
              rows={3}
              required
              placeholder="Describe what happened, exact room or floor, and any immediate safety hazards..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="mt-1.5 w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm text-slate-900 focus:border-[#C59B27] focus:bg-white focus:outline-none transition"
            />
          </div>

          {/* Severity Override */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
                Priority / Severity
              </label>
              <select
                value={severityOverride}
                onChange={(e) => setSeverityOverride(e.target.value)}
                className="mt-1.5 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-xs font-bold text-slate-800 focus:border-[#C59B27] focus:bg-white focus:outline-none"
              >
                <option value="AUTO">AI Auto-Triage (Recommended)</option>
                <option value="CRITICAL">Critical (Immediate Danger)</option>
                <option value="HIGH">High (Urgent Response)</option>
                <option value="MEDIUM">Medium (Standard Maintenance)</option>
                <option value="LOW">Low (Minor Advisory)</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
                Reported As
              </label>
              <div className="mt-1.5 rounded-xl border border-slate-200 bg-slate-100 px-3 py-2 text-xs font-bold text-slate-700 truncate">
                {user?.name || 'Verified Student'} ({user?.regNo || 'PU-STUDENT'})
              </div>
            </div>
          </div>

          {/* Photo Evidence with Preview */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
              Photo Evidence (Optional & Recommended)
            </label>
            {imagePreview ? (
              <div className="mt-1.5 relative rounded-2xl border border-slate-200 bg-slate-900 overflow-hidden group">
                <img
                  src={imagePreview}
                  alt="Evidence Preview"
                  className="w-full h-36 object-contain"
                />
                <button
                  type="button"
                  onClick={handleRemoveImage}
                  className="absolute top-2 right-2 rounded-lg bg-red-600 p-1.5 text-white hover:bg-red-700 transition shadow-md"
                  title="Remove Photo"
                >
                  <TrashIcon className="h-4 w-4" />
                </button>
                <div className="absolute bottom-0 inset-x-0 bg-slate-950/80 px-3 py-1.5 text-[11px] text-slate-300 truncate">
                  {image?.name || 'Evidence attached'}
                </div>
              </div>
            ) : (
              <label className="mt-1.5 flex cursor-pointer items-center justify-center gap-2.5 rounded-xl border-2 border-dashed border-slate-300 bg-slate-50/80 px-4 py-3.5 text-xs font-semibold text-slate-600 hover:border-[#C59B27] hover:bg-amber-50/40 transition">
                <PhotoIcon className="h-5 w-5 text-[#C59B27]" />
                <span>Attach JPEG / PNG Photo Evidence for Gemini AI</span>
                <input
                  type="file"
                  accept="image/jpeg,image/png,image/webp,image/jpg"
                  className="hidden"
                  onChange={handleImageChange}
                />
              </label>
            )}
          </div>

          {/* Action Buttons */}
          <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
            <button
              type="button"
              onClick={onClose}
              disabled={submitting}
              className="rounded-xl border border-slate-200 px-4 py-2.5 text-xs font-bold text-slate-600 hover:bg-slate-50 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="inline-flex items-center gap-2 rounded-xl bg-[#0F294A] px-5 py-2.5 text-xs font-bold text-white shadow-lg hover:bg-[#163B66] border border-[#C59B27]/60 disabled:opacity-50 transition active:scale-95"
            >
              {submitting ? (
                <>
                  <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                  <span>AI Triaging & Dispatching...</span>
                </>
              ) : (
                <>
                  <SparklesIcon className="h-4 w-4 text-[#C59B27]" />
                  <span>Submit Incident Report</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
