import React from 'react';
import { useAdmin } from '../../context/AdminContext';

export const WelcomeBanner: React.FC = () => {
  const { user, stats } = useAdmin();
  const firstName = user?.name?.split(' ')[0] || 'Galang';

  return (
    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-[#6FCC00] to-[#88E000] p-7 text-[#111111] shadow-card">
      {/* Decorative Pill/Capsule Watermark Graphic (Matching reference image) */}
      <div className="absolute right-0 top-0 bottom-0 w-80 pointer-events-none opacity-25 flex items-center justify-end pr-4">
        <svg width="220" height="140" viewBox="0 0 220 140" fill="none" xmlns="http://www.w3.org/2000/svg">
          {/* Stylized rounded pill/tablet blisters */}
          <rect x="20" y="10" width="180" height="120" rx="30" stroke="white" strokeWidth="12" fill="none" />
          <circle cx="65" cy="50" r="16" fill="white" />
          <circle cx="110" cy="50" r="16" fill="white" />
          <circle cx="155" cy="50" r="16" fill="white" />
          <circle cx="65" cy="90" r="16" fill="white" />
          <circle cx="110" cy="90" r="16" fill="white" />
          <circle cx="155" cy="90" r="16" fill="white" />
        </svg>
      </div>

      <div className="relative z-10 space-y-3">
        <h2 className="text-2xl font-black tracking-tight text-white flex items-center space-x-2 drop-shadow-xs">
          <span>Hello, {firstName}!!</span>
          <span>👋</span>
        </h2>

        <p className="text-xs font-semibold text-white/90">
          You have incomplete <span className="font-extrabold text-white underline decoration-white/40 underline-offset-2">{stats.pendingRequests > 0 ? stats.pendingRequests : '12'} nutritional moderation tasks</span> today.
        </p>

        {/* Progress Capsule Bar from reference */}
        <div className="pt-2">
          <div className="w-56 h-2 rounded-full bg-white/30 overflow-hidden">
            <div className="w-2/3 h-full rounded-full bg-white shadow-xs" />
          </div>
        </div>
      </div>
    </div>
  );
};
