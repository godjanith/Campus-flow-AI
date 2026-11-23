import React, { useState } from 'react';
import { XMarkIcon, SparklesIcon, PhotoIcon } from '@heroicons/react/24/outline';
import api from '../services/api';

const BUILDINGS = [
  { name: 'Engineering Block A', lat: 13.1723, lng: 77.5366 },
  { name: 'Engineering Block B', lat: 13.1715, lng: 77.5364 },
  { name: 'Central Library', lat: 13.1720, lng: 77.5350 },
  { name: 'Auditorium Complex', lat: 13.1712, lng: 77.5355 },
  { name: 'School of Management', lat: 13.1726, lng: 77.5358 },
  { name: 'Main Security Gate', lat: 13.1708, lng: 77.5370 },
];

export default function SimulateReportModal({ isOpen, onClose }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [building, setBuilding] = useState(BUILDINGS[0].name);
  const [image, setImage] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const selectedBldg = BUILDINGS.find((b) => b.name === building) || BUILDINGS[0];
      const formData = new FormData();
      formData.append('title', title);
      formData.append('description', description);
      formData.append('building', building);
      formData.append('lat', selectedBldg.lat + (Math.random() - 0.5) * 0.0003);
      formData.append('lng', selectedBldg.lng + (Math.random() - 0.5) * 0.0003);
      formData.append('reporterName', 'Janith V C (Web Simulator)');
      formData.append('reporterRegNo', '20252MCA0318');
      if (image) {
        formData.append('image', image);
      }

      await api.post('/tickets', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });

      setTitle('');
      setDescription('');
      setImage(null);
      onClose();
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to dispatch simulated ticket');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[1000] flex items-center justify-center bg-slate-900/40 p-4 backdrop-blur-sm">
      <div className="w-full max-w-lg rounded-2xl border border-slate-200 bg-white p-6 shadow-2xl">
        <div className="flex items-center justify-between border-b border-slate-100 pb-4">
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600">
              <SparklesIcon className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900">Simulate Field Incident</h3>
              <p className="text-xs text-slate-500">Tests AI Triage + Multer Upload + Socket.io Bus</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-600"
          >
            <XMarkIcon className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="mt-4 space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
              Campus Building / Zone
            </label>
            <select
              value={building}
              onChange={(e) => setBuilding(e.target.value)}
              className="mt-1.5 w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm font-medium text-slate-900 focus:border-indigo-500 focus:bg-white focus:outline-none"
            >
              {BUILDINGS.map((b) => (
                <option key={b.name} value={b.name}>
                  {b.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
              Incident Headline
            </label>
            <input
              type="text"
              required
              placeholder="e.g., Main server rack overheating & sparking"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="mt-1.5 w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm text-slate-900 focus:border-indigo-500 focus:bg-white focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
              Field Observation Details
            </label>
            <textarea
              rows={3}
              required
              placeholder="Describe hazard severity, floor level, or equipment affected..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="mt-1.5 w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm text-slate-900 focus:border-indigo-500 focus:bg-white focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-600">
              Photo Evidence (Optional)
            </label>
            <label className="mt-1.5 flex cursor-pointer items-center justify-center gap-2 rounded-xl border border-dashed border-slate-300 bg-slate-50/70 px-4 py-3 text-xs font-semibold text-slate-600 hover:border-indigo-400 hover:bg-indigo-50/40 transition">
              <PhotoIcon className="h-5 w-5 text-indigo-600" />
              <span>{image ? image.name : 'Attach JPEG/PNG Evidence for Multimodal AI'}</span>
              <input
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => setImage(e.target.files?.[0] || null)}
              />
            </label>
          </div>

          <div className="flex items-center justify-end gap-2.5 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="rounded-xl bg-[#0F294A] px-5 py-2.5 text-sm font-bold text-white shadow-md hover:bg-[#0A1C33] border border-[#C59B27]/40 disabled:opacity-50 transition"
            >
              {submitting ? 'Running AI Triage...' : 'Dispatch Live Ticket'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}