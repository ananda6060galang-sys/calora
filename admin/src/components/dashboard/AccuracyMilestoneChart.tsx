import React, { useState } from 'react';
import { Plus, ChevronDown, Calendar } from 'lucide-react';

export const AccuracyMilestoneChart: React.FC = () => {
  const [timeframe, setTimeframe] = useState('Weekly');
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  return (
    <div className="bg-white rounded-3xl p-6 border border-[#EAECE8] shadow-card space-y-4">
      {/* ── TOP HEADER: Metric + Score Pill ─────────────────────── */}
      <div className="flex items-center justify-between">
        <div className="space-y-0.5">
          <div className="flex items-baseline space-x-2">
            <span className="text-3xl font-black tracking-tight text-[#162018]">
              87.52%
            </span>
            <span className="text-xs text-gray-400 font-medium">Avg Accuracy</span>
          </div>
        </div>

        {/* Calora Score Pill from reference */}
        <div className="flex items-center space-x-1.5 px-3 py-1.5 rounded-full bg-[#F4F6F2] border border-[#EAECE8] text-xs font-bold text-[#162018]">
          <Plus className="w-3.5 h-3.5 text-[#72D000] stroke-[3]" />
          <span>Calora Score</span>
        </div>
      </div>

      {/* ── BESPOKE STEP-CURVE SVG CHART WITH MILESTONE BADGES ──── */}
      <div className="relative h-44 w-full pt-6">
        <svg
          viewBox="0 0 500 160"
          className="w-full h-full overflow-visible"
          preserveAspectRatio="none"
        >
          {/* Subtle horizontal grid lines */}
          <line x1="0" y1="40" x2="500" y2="40" stroke="#F4F6F2" strokeWidth="1.5" strokeDasharray="4 4" />
          <line x1="0" y1="90" x2="500" y2="90" stroke="#F4F6F2" strokeWidth="1.5" strokeDasharray="4 4" />
          <line x1="0" y1="140" x2="500" y2="140" stroke="#F4F6F2" strokeWidth="1.5" />

          {/* Vertical drop dashed guide lines */}
          <line x1="160" y1="90" x2="160" y2="140" stroke="#72D000" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.4" />
          <line x1="280" y1="35" x2="280" y2="140" stroke="#72D000" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.4" />
          <line x1="360" y1="45" x2="360" y2="140" stroke="#72D000" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.4" />

          {/* Dotted prediction curve from node 360 onwards */}
          <path
            d="M 360 45 C 390 70, 420 130, 450 120 C 470 115, 485 100, 500 95"
            fill="none"
            stroke="#A4DE66"
            strokeWidth="3.5"
            strokeDasharray="6 6"
          />

          {/* Main solid step-curved green line matching reference */}
          <path
            d="M 10 135 C 30 135, 40 85, 70 85 C 90 85, 100 125, 120 125 C 140 125, 150 90, 160 90 C 170 90, 180 135, 205 135 C 230 135, 240 135, 255 135 C 265 135, 270 35, 280 35 C 295 35, 305 65, 320 65 C 335 65, 345 45, 360 45"
            fill="none"
            stroke="#72D000"
            strokeWidth="4"
            strokeLinecap="round"
            strokeLinejoin="round"
          />

          {/* Node 1: Value 75 */}
          <circle cx="160" cy="90" r="5" fill="white" stroke="#72D000" strokeWidth="3.5" />
          {/* Node 2: Value 78 */}
          <circle cx="280" cy="35" r="5" fill="white" stroke="#72D000" strokeWidth="3.5" />
          {/* Node 3: Value 77 */}
          <circle cx="360" cy="45" r="5" fill="white" stroke="#72D000" strokeWidth="3.5" />
        </svg>

        {/* Milestone Node Badges (Matching reference green rounded badges) */}
        {/* Badge 75 (Bottom drop) */}
        <div
          className="absolute left-[30%] top-[48%] -translate-x-1/2 px-2 py-0.5 rounded-full bg-[#72D000] text-white font-extrabold text-[10px] shadow-sm pointer-events-none"
        >
          75
        </div>

        {/* Badge 78 (Peak) */}
        <div
          className="absolute left-[54%] top-[10%] -translate-x-1/2 px-2 py-0.5 rounded-full bg-[#72D000] text-white font-extrabold text-[10px] shadow-sm pointer-events-none"
        >
          78
        </div>

        {/* Badge 77 (Second peak) */}
        <div
          className="absolute left-[70%] top-[16%] -translate-x-1/2 px-2 py-0.5 rounded-full bg-[#72D000] text-white font-extrabold text-[10px] shadow-sm pointer-events-none"
        >
          77
        </div>
      </div>

      {/* ── BOTTOM LEGEND + TIMEFRAME DROPDOWN ───────────────────── */}
      <div className="flex items-center justify-between pt-2 border-t border-[#F4F6F2]">
        <div className="flex items-center space-x-4 text-xs font-semibold text-gray-500">
          <div className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#72D000]" />
            <span className="text-[#162018]">Previous</span>
          </div>
          <div className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#A4DE66]" />
            <span>AI Prediction</span>
          </div>
        </div>

        {/* Dropdown Selector from reference ("Weekly ⌵") */}
        <div className="relative">
          <button
            onClick={() => setIsDropdownOpen(!isDropdownOpen)}
            className="flex items-center space-x-1.5 px-3 py-1.5 rounded-full bg-[#F4F6F2] hover:bg-gray-100 text-xs font-bold text-[#162018] transition-colors"
          >
            <Calendar className="w-3.5 h-3.5 text-gray-400" />
            <span>{timeframe}</span>
            <ChevronDown className="w-3.5 h-3.5 text-gray-400" />
          </button>

          {isDropdownOpen && (
            <div className="absolute right-0 bottom-full mb-1 w-28 bg-white rounded-xl shadow-lg border border-[#EAECE8] py-1 z-30 text-xs">
              {['Daily', 'Weekly', 'Monthly', 'Yearly'].map((tf) => (
                <button
                  key={tf}
                  onClick={() => {
                    setTimeframe(tf);
                    setIsDropdownOpen(false);
                  }}
                  className="w-full text-left px-3 py-1.5 hover:bg-[#F4F6F2] font-semibold text-[#162018]"
                >
                  {tf}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
