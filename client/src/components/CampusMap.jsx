import React, { useMemo, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Circle } from 'react-leaflet';
import L from 'leaflet';

const PRESIDENCY_CENTER = [13.1718, 77.5361];

const SEVERITY_COLORS = {
  CRITICAL: { core: '#DC2626', ring: 'rgba(220, 38, 38, 0.55)' },
  HIGH: { core: '#EA580C', ring: 'rgba(234, 88, 12, 0.50)' },
  MEDIUM: { core: '#2563EB', ring: 'rgba(37, 99, 235, 0.45)' },
  LOW: { core: '#059669', ring: 'rgba(5, 150, 105, 0.40)' },
};

const createBeaconIcon = (severity, status) => {
  const palette =
    status === 'RESOLVED'
      ? { core: '#10B981', ring: 'transparent' }
      : SEVERITY_COLORS[severity] || SEVERITY_COLORS.MEDIUM;

  const pulseHtml =
    status !== 'RESOLVED'
      ? `<span class="campus-pin-pulse" style="background:${palette.ring};"></span>`
      : '';

  return L.divIcon({
    className: 'custom-campus-beacon',
    html: `
      <div class="campus-pin-wrapper" style="width:32px;height:32px;">
        ${pulseHtml}
        <span class="campus-pin-core" style="background:${palette.core};"></span>
      </div>
    `,
    iconSize: [32, 32],
    iconAnchor: [16, 16],
  });
};

export default function CampusMap({ tickets, apiBaseUrl, onStatusChange }) {
  const [mapMode, setMapMode] = useState('SATELLITE'); // Default to High-Res Satellite View

  const activeTickets = useMemo(
    () => tickets.filter((t) => t.location?.lat && t.location?.lng),
    [tickets]
  );

  return (
    <div className="relative h-[430px] w-full overflow-hidden rounded-2xl border border-slate-200/90 bg-white shadow-sm">
      {/* Top-Left Layer Switcher (Satellite vs. Daylight Blueprint) */}
      <div className="absolute left-14 top-3 z-[400] flex items-center rounded-xl border border-slate-200/90 bg-white/95 p-1 text-xs font-bold shadow-sm backdrop-blur">
        <button
          type="button"
          onClick={() => setMapMode('SATELLITE')}
          className={`rounded-lg px-2.5 py-1 transition ${
            mapMode === 'SATELLITE'
              ? 'bg-[#0F294A] text-white shadow-sm'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          Satellite
        </button>
        <button
          type="button"
          onClick={() => setMapMode('STREET')}
          className={`rounded-lg px-2.5 py-1 transition ${
            mapMode === 'STREET'
              ? 'bg-[#0F294A] text-white shadow-sm'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          Daylight Map
        </button>
      </div>

      {/* Floating Spatial Legend Pill */}
      <div className="absolute right-3 top-3 z-[400] flex flex-wrap items-center gap-3 rounded-xl border border-slate-200/90 bg-white/95 px-3.5 py-2 text-xs font-semibold text-slate-700 shadow-sm backdrop-blur">
        <span className="flex items-center gap-1.5">
          <span className="h-2.5 w-2.5 rounded-full bg-red-600"></span> Critical
        </span>
        <span className="flex items-center gap-1.5">
          <span className="h-2.5 w-2.5 rounded-full bg-orange-600"></span> High
        </span>
        <span className="flex items-center gap-1.5">
          <span className="h-2.5 w-2.5 rounded-full bg-blue-600"></span> Medium
        </span>
        <span className="flex items-center gap-1.5">
          <span className="h-2.5 w-2.5 rounded-full bg-emerald-600"></span> Resolved
        </span>
      </div>

      {/* Campus Coordinate Tag */}
      <div className="absolute bottom-3 left-3 z-[400] rounded-lg border border-slate-200 bg-white/95 px-2.5 py-1 font-mono text-[11px] font-medium text-slate-700 shadow-sm">
        PRESIDENCY UNIVERSITY • 13.1718° N, 77.5361° E
      </div>

      <MapContainer
        center={PRESIDENCY_CENTER}
        zoom={17}
        maxZoom={19}
        scrollWheelZoom={true}
        className="h-full w-full z-10"
      >
        {mapMode === 'SATELLITE' ? (
          <>
            {/* Esri World Imagery High-Resolution Satellite Base */}
            <TileLayer
              attribution="Tiles &copy; Esri &mdash; Source: Esri, Maxar, Earthstar Geographics, and the GIS User Community"
              url="https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
              maxNativeZoom={18}
              maxZoom={19}
            />
            {/* Crisp Road & Building Reference Labels Overlay */}
            <TileLayer
              url="https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}"
              maxNativeZoom={18}
              maxZoom={19}
            />
          </>
        ) : (
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            className="campus-daylight-tiles"
            maxZoom={19}
          />
        )}

        {/* Campus Geofence Perimeter */}
        <Circle
          center={PRESIDENCY_CENTER}
          radius={240}
          pathOptions={{
            color: mapMode === 'SATELLITE' ? '#38BDF8' : '#4F46E5',
            weight: 2,
            dashArray: '6 6',
            fillColor: mapMode === 'SATELLITE' ? '#38BDF8' : '#6366F1',
            fillOpacity: 0.08,
          }}
        />

        {activeTickets.map((ticket) => (
          <Marker
            key={ticket._id}
            position={[ticket.location.lat, ticket.location.lng]}
            icon={createBeaconIcon(ticket.severity, ticket.status)}
          >
            <Popup minWidth={260} maxWidth={300}>
              <div className="p-1.5 text-slate-800">
                <div className="mb-1.5 flex items-center justify-between gap-2">
                  <span className="font-mono text-[11px] font-bold text-indigo-600">
                    {ticket.ticketCode}
                  </span>
                  <span
                    className={`rounded-full px-2 py-0.5 text-[10px] font-bold uppercase ${
                      ticket.severity === 'CRITICAL'
                        ? 'bg-red-100 text-red-700'
                        : ticket.severity === 'HIGH'
                        ? 'bg-orange-100 text-orange-700'
                        : 'bg-blue-100 text-blue-700'
                    }`}
                  >
                    {ticket.severity}
                  </span>
                </div>

                <h4 className="text-sm font-bold leading-snug text-slate-900">
                  {ticket.title}
                </h4>
                <p className="mt-0.5 text-xs font-medium text-slate-500">
                  {ticket.building} • {ticket.category}
                </p>

                {ticket.imageUrl && (
                  <img
                    src={`${apiBaseUrl}${ticket.imageUrl}`}
                    alt="Evidence"
                    className="mt-2 h-24 w-full rounded-lg border border-slate-200 object-cover"
                  />
                )}

                <p className="mt-2 rounded-lg bg-slate-50 p-2 text-xs leading-relaxed text-slate-700 border border-slate-100">
                  {ticket.aiSummary}
                </p>

                <div className="mt-2.5 flex items-center gap-1.5">
                  {ticket.status !== 'IN_PROGRESS' && ticket.status !== 'RESOLVED' && (
                    <button
                      onClick={(e) => { e.stopPropagation(); onStatusChange(ticket._id, 'IN_PROGRESS'); }}
                      onMouseDown={(e) => e.stopPropagation()}
                      className="flex-1 rounded-lg bg-amber-500 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-amber-600 transition cursor-pointer"
                    >
                      Dispatch Crew
                    </button>
                  )}
                  {ticket.status !== 'RESOLVED' && (
                    <button
                      onClick={(e) => { e.stopPropagation(); onStatusChange(ticket._id, 'RESOLVED'); }}
                      onMouseDown={(e) => e.stopPropagation()}
                      className="flex-1 rounded-lg bg-emerald-600 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 transition cursor-pointer"
                    >
                      Mark Resolved
                    </button>
                  )}
                </div>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}