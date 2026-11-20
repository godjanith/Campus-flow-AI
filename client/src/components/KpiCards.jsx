import React from 'react';
import { TicketIcon, ExclamationTriangleIcon, CheckCircleIcon, ClockIcon } from '@heroicons/react/24/outline';

export default function KpiCards({ analytics }) {
  const cards = [
    { title: 'Total Issues', value: analytics?.total || 0, icon: TicketIcon, color: 'bg-indigo-500' },
    { title: 'Urgent / Priority', value: analytics?.urgent || 0, icon: ExclamationTriangleIcon, color: 'bg-rose-500' },
    { title: 'In Progress', value: analytics?.inProgress || 0, icon: ClockIcon, color: 'bg-amber-500' },
    { title: 'Resolved', value: analytics?.resolved || 0, icon: CheckCircleIcon, color: 'bg-emerald-500' },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      {cards.map((c, i) => {
        const Icon = c.icon;
        return (
          <div key={i} className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex items-center space-x-4">
            <div className={`${c.color} p-3 rounded-lg text-white`}>
              <Icon className="w-6 h-6" />
            </div>
            <div>
              <p className="text-sm text-gray-500 font-medium">{c.title}</p>
              <h3 className="text-2xl font-bold text-gray-800">{c.value}</h3>
            </div>
          </div>
        );
      })}
    </div>
  );
}
