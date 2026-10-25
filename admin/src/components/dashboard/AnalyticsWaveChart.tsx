import React from 'react';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import {
  PiCalendarBlankBold,
  PiMinusBold,
} from 'react-icons/pi';

export const AnalyticsWaveChart: React.FC = () => {
  const { isDark } = useThemeLanguage();
  const gridLineColor = isDark ? '#222D23' : '#F2F4F0';

  return (
    <div className="bg-white dark:bg-[#181E19] rounded-2xl p-5 sm:p-6 border border-[#EAECE8] dark:border-[#263226] shadow-xs transition-colors duration-200">
      {/* ── HEADER (Exact match to Figma: "Sales Analytics ○" & Month controls) ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
        <div className="flex items-center space-x-2">
          <h3 className="text-sm sm:text-base font-bold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
            Food Request Activity
          </h3>
          <span className="w-3 h-3 rounded-full border border-gray-400 dark:border-gray-500 inline-block" />
        </div>

        <div className="flex items-center space-x-3 text-xs text-gray-500 dark:text-gray-400">
          <span className="cursor-pointer hover:text-[#111111] dark:hover:text-white transition-colors">
            Previous Month
          </span>
          <button className="flex items-center space-x-1.5 font-bold text-[#111111] dark:text-[#F3F5EF] hover:text-[#16A34A] transition-colors cursor-pointer">
            <span>March 2026</span>
            <PiCalendarBlankBold className="w-3.5 h-3.5 text-gray-400" />
          </button>
          <button className="text-gray-400 hover:text-gray-600 dark:hover:text-white cursor-pointer">
            <PiMinusBold className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* ── CHART CANVAS WITH FLOATING TOOLTIP CARD ────────────────── */}
      <div className="flex items-stretch h-52 sm:h-56 relative select-none">
        {/* Y-Axis scale matching Figma labels */}
        <div className="flex flex-col justify-between text-[11px] font-semibold text-gray-400 dark:text-gray-500 pr-3 pb-6 shrink-0">
          <span>260M</span>
          <span>220M</span>
          <span>180M</span>
          <span>140M</span>
        </div>

        {/* SVG Curve Canvas */}
        <div className="flex-1 relative pb-6 border-b border-[#F2F4F0] dark:border-[#222D23]">
          <svg
            viewBox="0 0 500 160"
            className="w-full h-full overflow-visible"
            preserveAspectRatio="none"
          >
            <defs>
              {/* Vibrant lime/green gradient fill for the wave area matching Figma */}
              <linearGradient id="figmaWaveGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#84E000" stopOpacity={isDark ? 0.45 : 0.42} />
                <stop offset="55%" stopColor="#A6F226" stopOpacity={isDark ? 0.16 : 0.18} />
                <stop offset="100%" stopColor={isDark ? '#181E19' : '#FFFFFF'} stopOpacity="0.0" />
              </linearGradient>
            </defs>

            {/* Horizontal dashed grid lines */}
            <line x1="0" y1="15" x2="500" y2="15" stroke={gridLineColor} strokeWidth="1" strokeDasharray="3 3" />
            <line x1="0" y1="55" x2="500" y2="55" stroke={gridLineColor} strokeWidth="1" strokeDasharray="3 3" />
            <line x1="0" y1="95" x2="500" y2="95" stroke={gridLineColor} strokeWidth="1" strokeDasharray="3 3" />
            <line x1="0" y1="135" x2="500" y2="135" stroke={gridLineColor} strokeWidth="1" />

            {/* Dotted vertical drop line at Day 14 connecting tooltip to X-axis */}
            <line
              x1="205"
              y1="48"
              x2="205"
              y2="135"
              stroke={isDark ? '#B8FF3B' : '#0C2417'}
              strokeWidth="1.2"
              strokeDasharray="2 2"
            />

            {/* 1. Green Wave Filled Area (Figma wave) */}
            <path
              d="M 10 135 
                 C 40 135, 60 115, 90 115 
                 C 130 115, 160 55, 205 48 
                 C 240 42, 270 95, 310 95 
                 C 340 95, 370 25, 410 25 
                 C 440 25, 470 65, 500 50 
                 L 500 145 L 10 145 Z"
              fill="url(#figmaWaveGradient)"
              className="transition-all duration-300"
            />

            {/* 2. Orange Line / Curve from Figma */}
            <path
              d="M 10 95 
                 C 50 95, 70 120, 110 120 
                 C 150 120, 180 80, 220 80 
                 C 250 80, 280 115, 320 115 
                 C 370 115, 420 75, 500 115"
              fill="none"
              stroke="#FFA048"
              strokeWidth="2.5"
              strokeLinecap="round"
              className="transition-all duration-300"
            />

            {/* 3. Lime Green Wave Stroke Line from Figma */}
            <path
              d="M 10 135 
                 C 40 135, 60 115, 90 115 
                 C 130 115, 160 55, 205 48 
                 C 240 42, 270 95, 310 95 
                 C 340 95, 370 25, 410 25 
                 C 440 25, 470 65, 500 50"
              fill="none"
              stroke="#76D700"
              strokeWidth="2.5"
              strokeLinecap="round"
              className="transition-all duration-300"
            />

            {/* Peak indicator dot on Day 14 with lime halo */}
            <circle
              cx="205"
              cy="48"
              r="6"
              fill="#76D700"
              fillOpacity="0.3"
            />
            <circle
              cx="205"
              cy="48"
              r="3.5"
              fill="#76D700"
              stroke={isDark ? '#181E19' : '#FFFFFF'}
              strokeWidth="2"
            />
          </svg>

          {/* Floating Tooltip Pill from Figma Screenshot (Exact "220,342,123" style) */}
          <div
            className="absolute -top-3 left-[36%] -translate-x-1/2 bg-white dark:bg-[#0B1E13] text-[#111111] dark:text-white px-3.5 py-1.5 rounded-xl shadow-md border border-gray-100 dark:border-[#203D2B] pointer-events-none flex flex-col items-center z-10"
          >
            <span className="text-xs font-black tracking-tight text-[#111111] dark:text-white">
              220,342,123
            </span>
          </div>
        </div>
      </div>

      {/* X-Axis day markers from Figma (1, 5, 10, 15, 20, 25, 30) */}
      <div className="flex justify-between pl-8 pr-2 pt-2 text-[11px] font-bold text-gray-400 dark:text-gray-500">
        <span>1</span>
        <span>5</span>
        <span>10</span>
        <span>15</span>
        <span>20</span>
        <span>25</span>
        <span>30</span>
      </div>
    </div>
  );
};
