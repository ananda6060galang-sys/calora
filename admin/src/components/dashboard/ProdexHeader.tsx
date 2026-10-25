import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { Search, Bell } from 'lucide-react';

export const ProdexHeader: React.FC = () => {
  const { user, searchQuery, setSearchQuery } = useAdmin();
  const firstName = user?.name?.split(' ')[0] || 'Galang';

  return (
    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
      {/* ── GREETING TITLE ────────────────────────────────────────── */}
      <div>
        <h1 className="text-2xl font-normal text-[#1A1C29]">
          Welcome back, <span className="font-bold text-[#1A1C29]">{firstName}!</span>
        </h1>
      </div>

      {/* ── RIGHT CONTROLS: SEARCH + NOTIFICATION + AVATAR ────────── */}
      <div className="flex items-center space-x-3">
        {/* Search Input Pill from reference */}
        <div className="relative w-64 md:w-80">
          <div className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
            <Search className="w-4 h-4" />
          </div>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search...."
            className="w-full pl-10 pr-4 py-2.5 rounded-2xl bg-[#F4F5F7] text-xs text-[#1A1C29] placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#D4FF32]/50 border-none transition-all"
          />
        </div>

        {/* Circular Notification Bell Button from reference */}
        <button
          title="Notifications"
          className="relative w-10 h-10 rounded-2xl bg-white border border-[#E8EAE6] hover:bg-gray-50 flex items-center justify-center text-gray-700 shadow-xs transition-colors"
        >
          <Bell className="w-4 h-4" />
          <span className="w-2 h-2 rounded-full bg-[#FF5A5F] absolute top-2.5 right-2.5" />
        </button>

        {/* User Profile Avatar from reference */}
        <div className="relative">
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-[#1B1D28] to-[#2E3347] text-[#D4FF32] font-black text-sm flex items-center justify-center ring-2 ring-[#E8EAE6] shadow-xs overflow-hidden">
            {user?.avatar_url ? (
              <img
                src={user.avatar_url}
                alt={user.name || 'Admin'}
                className="w-full h-full object-cover rounded-2xl absolute inset-0"
                onError={(e) => {
                  (e.currentTarget as HTMLElement).style.display = 'none';
                }}
              />
            ) : null}
            <span>{firstName[0]}</span>
          </div>
        </div>
      </div>
    </div>
  );
};
