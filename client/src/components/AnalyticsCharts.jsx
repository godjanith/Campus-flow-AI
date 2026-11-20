import React, { useMemo } from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  ArcElement,
  Tooltip,
  Legend,
} from 'chart.js';
import { Bar, Doughnut } from 'react-chartjs-2';

ChartJS.register(CategoryScale, LinearScale, BarElement, ArcElement, Tooltip, Legend);

export default function AnalyticsCharts({ tickets }) {
  const categoryData = useMemo(() => {
    const counts = {};
    tickets.forEach((t) => {
      counts[t.category] = (counts[t.category] || 0) + 1;
    });
    const labels = Object.keys(counts);
    return {
      labels: labels.length ? labels : ['No Data'],
      datasets: [
        {
          label: 'Active Incidents',
          data: labels.length ? Object.values(counts) : [0],
          backgroundColor: '#4F46E5',
          borderRadius: 8,
          barThickness: 22,
        },
      ],
    };
  }, [tickets]);

  const severityData = useMemo(() => {
    const order = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
    const counts = order.map((sev) => tickets.filter((t) => t.severity === sev).length);
    return {
      labels: ['Critical', 'High', 'Medium', 'Low'],
      datasets: [
        {
          data: counts,
          backgroundColor: ['#DC2626', '#EA580C', '#2563EB', '#10B981'],
          borderWidth: 2,
          borderColor: '#FFFFFF',
        },
      ],
    };
  }, [tickets]);

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
      <div className="rounded-2xl border border-slate-200/90 bg-white p-5 shadow-sm">
        <div className="mb-3 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-bold text-slate-900">Infrastructure Domain Load</h3>
            <p className="text-xs text-slate-500">Live classification distribution across campus</p>
          </div>
          <span className="rounded-md bg-indigo-50 px-2 py-1 font-mono text-[11px] font-semibold text-indigo-700">
            AI TRIAGED
          </span>
        </div>
        <div className="h-48">
          <Bar
            data={categoryData}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              plugins: { legend: { display: false } },
              scales: {
                x: { grid: { display: false }, ticks: { font: { size: 11 } } },
                y: { beginAtZero: true, ticks: { stepSize: 1, font: { size: 11 } } },
              },
            }}
          />
        </div>
      </div>

      <div className="rounded-2xl border border-slate-200/90 bg-white p-5 shadow-sm">
        <div className="mb-3 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-bold text-slate-900">Severity Risk Matrix</h3>
            <p className="text-xs text-slate-500">Real-time threat & SLA priority breakdown</p>
          </div>
          <span className="rounded-md bg-slate-100 px-2 py-1 font-mono text-[11px] font-semibold text-slate-700">
            LIVE SLA
          </span>
        </div>
        <div className="h-48 flex items-center justify-center">
          <Doughnut
            data={severityData}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              cutout: '66%',
              plugins: {
                legend: {
                  position: 'right',
                  labels: { boxWidth: 12, usePointStyle: true, font: { size: 12 } },
                },
              },
            }}
          />
        </div>
      </div>
    </div>
  );
}