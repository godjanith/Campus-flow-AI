import React from 'react';
import { HomeIcon, TicketIcon, ChartBarIcon, MapIcon, ArrowLeftOnRectangleIcon } from '@heroicons/react/24/outline';

export default function Sidebar({ activeTab, setActiveTab, user, onLogout }) {
  const navItems = [
    { id: 'dashboard', name: 'Dashboard', icon: HomeIcon },
    { id: 'tickets', name: 'Issue Tickets', icon: TicketIcon },
    { id: 'analytics', name: 'AI Analytics', icon: ChartBarIcon },
    { id: 'map', name: 'Campus Map', icon: MapIcon },
  ];

  return (
    <aside className="w-64 bg-slate-900 text-white flex flex-col justify-between shadow-xl">
      <div>
        <div className="p-6 border-b border-slate-800 flex items-center space-x-3">
          <div className="bg-indigo-600 p-2 rounded-lg font-bold text-xl tracking-wider">CF</div>
          <div>
            <h1 className="font-bold text-lg leading-tight">CampusFlow AI</h1>
            <p className="text-xs text-slate-400">Competition Edition</p>
          </div>
        </div>
        <nav className="p-4 space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-medium transition-colors ${
                  isActive ? 'bg-indigo-600 text-white shadow-md' : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <Icon className="w-5 h-5" />
                <span>{item.name}</span>
              </button>
            );
          })}
        </nav>
      </div>

      <div className="p-4 border-t border-slate-800">
        <div className="flex items-center space-x-3 mb-4 px-2">
          <div className="w-9 h-9 rounded-full bg-indigo-500 flex items-center justify-center font-bold text-sm">
            {user?.name?.[0] || 'U'}
          </div>
          <div className="overflow-hidden">
            <p className="text-sm font-medium truncate">{user?.name || 'User'}</p>
            <p className="text-xs text-slate-400 capitalize">{user?.role || 'student'}</p>
          </div>
        </div>
        <button
          onClick={onLogout}
          className="w-full flex items-center space-x-3 px-4 py-2.5 rounded-lg text-sm font-medium text-rose-400 hover:bg-rose-950/30 transition-colors"
        >
          <ArrowLeftOnRectangleIcon className="w-5 h-5" />
          <span>Sign Out</span>
        </button>
      </div>
    </aside>
  );
}
