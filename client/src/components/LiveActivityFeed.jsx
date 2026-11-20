import React from 'react';
import { SparklesIcon } from '@heroicons/react/24/outline';

export default function LiveActivityFeed({ tickets }) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
      <div className="flex items-center space-x-2 mb-4">
        <SparklesIcon className="w-5 h-5 text-indigo-600 animate-spin" />
        <h3 className="text-lg font-bold text-gray-800">CampusFlow AI Live Activity Stream</h3>
      </div>
      <div className="space-y-4">
        {tickets?.slice(0, 5).map((t, idx) => (
          <div key={idx} className="flex items-start space-x-3 pb-3 border-b border-gray-50 last:border-0">
            <div className="w-8 h-8 rounded-full bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold text-xs mt-0.5">
              AI
            </div>
            <div className="flex-1">
              <p className="text-sm font-medium text-gray-800">Triaged ticket: <span className="text-indigo-600">{t.title}</span></p>
              <p className="text-xs text-gray-500">Assigned Priority: {t.priority} • Location: {t.location}</p>
            </div>
            <span className="text-xs text-gray-400">Just now</span>
          </div>
        ))}
      </div>
    </div>
  );
}
