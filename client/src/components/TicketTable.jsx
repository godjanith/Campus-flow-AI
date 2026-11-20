import React from 'react';

export default function TicketTable({ tickets, onSelectTicket, onUpdateStatus }) {
  const getBadgeColor = (status) => {
    switch (status) {
      case 'Resolved': return 'bg-emerald-100 text-emerald-800';
      case 'In Progress': return 'bg-amber-100 text-amber-800';
      case 'AI Triaged': return 'bg-indigo-100 text-indigo-800';
      case 'Urgent': return 'bg-rose-100 text-rose-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="p-6 border-b border-gray-100 flex justify-between items-center">
        <h3 className="text-lg font-bold text-gray-800">Campus Issue Tickets & AI Triaging</h3>
        <span className="text-sm text-gray-500">{tickets?.length || 0} Total Tickets</span>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-gray-50 text-gray-500 text-xs uppercase font-semibold">
              <th className="p-4">Title / Issue</th>
              <th className="p-4">Category</th>
              <th className="p-4">Location</th>
              <th className="p-4">Priority</th>
              <th className="p-4">Status</th>
              <th className="p-4">AI Urgency</th>
              <th className="p-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 text-sm">
            {tickets?.map((t) => (
              <tr key={t._id} className="hover:bg-gray-50/50 transition-colors">
                <td className="p-4 font-medium text-gray-800">
                  <div onClick={() => onSelectTicket(t)} className="cursor-pointer hover:text-indigo-600">
                    {t.title}
                  </div>
                  <div className="text-xs text-gray-400 font-normal">By {t.reportedBy?.name || 'Student'}</div>
                </td>
                <td className="p-4 text-gray-600">{t.category}</td>
                <td className="p-4 text-gray-600">{t.location}</td>
                <td className="p-4">
                  <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${getBadgeColor(t.priority)}`}>
                    {t.priority}
                  </span>
                </td>
                <td className="p-4">
                  <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${getBadgeColor(t.status)}`}>
                    {t.status}
                  </span>
                </td>
                <td className="p-4 font-bold text-indigo-600">
                  {t.aiAnalysis?.urgencyScore || 3}/10
                </td>
                <td className="p-4 text-right space-x-2">
                  <button
                    onClick={() => onSelectTicket(t)}
                    className="px-3 py-1.5 bg-indigo-50 text-indigo-600 hover:bg-indigo-100 rounded-lg text-xs font-medium"
                  >
                    View / Manage
                  </button>
                </td>
              </tr>
            ))}
            {(!tickets || tickets.length === 0) && (
              <tr>
                <td colSpan="7" className="p-8 text-center text-gray-400">No tickets found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
