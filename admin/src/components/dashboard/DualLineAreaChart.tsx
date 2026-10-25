import React, { useState } from 'react';
import { ChevronDown } from 'lucide-react';

export const DualLineAreaChart: React.FC = () => {
  const [period, setPeriod] = useState('Week');
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Jul', 'Sat'];

  return (
    <div className="bg-white rounded-2xl p-6 border border-[#E8EAE6] shadow-xs flex flex-col justify-between h-full">
      {/* ── HEADER & DROPDOWN (From reference) ────────────────────── */}
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-base font-bold text-[#1A1C29]">
          Transaction Overview
        </h3>

        {/* Dropdown pill */}
        <div className="relative">
          <button
            onClick={() => setIsDropdownOpen(!isDropdownOpen)}
            className="flex items-center space-x-1.5 px-3 py-1.5 rounded-xl border border-[#E8EAE6] bg-white hover:bg-gray-50 text-xs font-semibold text-[#1A1C29] transition-colors"
          >
            <span>{period}</span>
            <ChevronDown className="w-3.5 h-3.5 text-gray-400" />
          </button>

          {isDropdownOpen && (
            <div className="absolute right-0 mt-1 w-24 bg-white rounded-xl shadow-lg border border-[#E8EAE6] py-1 z-30 text-xs">
              {['Day', 'Week', 'Month'].map((p) => (
                <button
                  key={p}
                  onClick={() => {
                    setPeriod(p);
                    setIsDropdownOpen(false);
                  }}
                  className="w-full text-left px-3 py-1.5 hover:bg-[#F4F5F7] font-medium text-[#1A1C29]"
                >
                  {p}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── DUAL SMOOTH SVG CURVES WITH LIME GLOW AREA ────────────── */}
      <div className="flex items-stretch h-52">
        {/* Y-Axis scale from reference: 560k, 460k, 360k, 260k, 160k */}
        <div className="flex flex-col justify-between text-[11px] font-medium text-gray-400 pr-3 pb-6 select-none shrink-0">
          <span>560k</span>
          <span>460k</span>
          <span>360k</span>
          <span>260k</span>
          <span>160k</span>
        </div>

        {/* SVG Chart Canvas */}
        <div className="flex-1 relative pb-6 border-b border-[#F4F5F7]">
          <svg
            viewBox="0 0 450 160"
            className="w-full h-full overflow-visible"
            preserveAspectRatio="none"
          >
            <defs>
              {/* Lime glowing area gradient matching reference */}
              <linearGradient id="limeGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#D4FF32" stopOpacity="0.65" />
                <stop offset="60%" stopColor="#D4FF32" stopOpacity="0.2" />
                <stop offset="100%" stopColor="#FFFFFF" stopOpacity="0.0" />
              </linearGradient>
            </defs>

            {/* Subtle horizontal grid lines */}
            <line x1="0" y1="5" x2="450" y2="5" stroke="#F4F5F7" strokeWidth="1" strokeDasharray="3 3" />
            <line x1="0" y1="40" x2="450" y2="40" stroke="#F4F5F7" strokeWidth="1" strokeDasharray="3 3" />
            <line x1="0" y1="75" x2="450" y2="75" stroke="#F4F5F7" strokeWidth="1" strokeDasharray="3 3" />
            <line x1="0" y1="110" x2="450" y2="110" stroke="#F4F5F7" strokeWidth="1" strokeDasharray="3 3" />
            <line x1="0" y1="145" x2="450" y2="145" stroke="#F4F5F7" strokeWidth="1" />

            {/* 1. Lime Filled Area Beneath the Lime Curve */}
            <path
              d="M 10 145 
                 C 50 140, 80 135, 110 125 
                 C 140 115, 160 100, 190 100 
                 C 220 100, 240 115, 270 105 
                 C 300 95, 310 40, 340 40 
                 C 370 40, 390 90, 420 85 
                 C 435 82, 445 80, 450 80 
                 L 450 160 L 10 160 Z"
              fill="url(#limeGradient)"
            />

            {/* 2. Orange / Peach Smooth Curve Line */}
            <path
              d="M 10 145 
                 C 60 140, 80 90, 140 90 
                 C 190 90, 230 75, 270 70 
                 C 310 65, 370 45, 410 25 
                 C 430 15, 440 10, 450 5"
              fill="none"
              stroke="#FFA048"
              strokeWidth="2.5"
              strokeLinecap="round"
            />

            {/* 3. Electric Lime Smooth Curve Line */}
            <path
              d="M 10 145 
                 C 50 140, 80 135, 110 125 
                 C 140 115, 160 100, 190 100 
                 C 220 100, 240 115, 270 105 
                 C 300 95, 310 40, 340 40 
                 C 370 40, 390 90, 420 85 
                 C 435 82, 445 80, 450 80"
              fill="none"
              stroke="#BDEB25"
              strokeWidth="2.5"
              strokeLinecap="round"
            />
          </svg>
        </div>
      </div>

      {/* ── X-AXIS LABELS (Sun to Sat) ────────────────────────────── */}
      <div className="flex items-center pl-9 pt-2">
        <div className="flex-1 grid grid-cols-8 text-center">
          {days.map((d, i) => (
            <span key={i} className="text-[10px] font-medium text-gray-400">
              {d}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
};
