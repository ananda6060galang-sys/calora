import React, { useState } from 'react';
import { ChevronDown } from 'lucide-react';

interface BarData {
  month: string;
  hatchedHeight: number; // in percentage of chart height (0-100)
  solidHeight: number; // in percentage of chart height (0-100)
  totalLabel: string;
}

export const SegmentedBarChart: React.FC = () => {
  const [period, setPeriod] = useState('Monthly');
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  // Exact data distribution matching the reference image
  const barData: BarData[] = [
    { month: 'Jan', hatchedHeight: 52, solidHeight: 28, totalLabel: '32 Requests' },
    { month: 'Feb', hatchedHeight: 32, solidHeight: 18, totalLabel: '20 Requests' },
    { month: 'Mar', hatchedHeight: 46, solidHeight: 24, totalLabel: '28 Requests' },
    { month: 'Apr', hatchedHeight: 22, solidHeight: 12, totalLabel: '14 Requests' },
    { month: 'May', hatchedHeight: 26, solidHeight: 16, totalLabel: '17 Requests' },
    { month: 'Jun', hatchedHeight: 56, solidHeight: 22, totalLabel: '31 Requests' },
    { month: 'Jul', hatchedHeight: 52, solidHeight: 24, totalLabel: '30 Requests' },
    { month: 'Aug', hatchedHeight: 24, solidHeight: 56, totalLabel: '32 Requests' },
    { month: 'Sep', hatchedHeight: 28, solidHeight: 22, totalLabel: '20 Requests' },
    { month: 'Oct', hatchedHeight: 32, solidHeight: 24, totalLabel: '22 Requests' },
    { month: 'Nov', hatchedHeight: 48, solidHeight: 28, totalLabel: '30 Requests' },
    { month: 'Dec', hatchedHeight: 42, solidHeight: 22, totalLabel: '26 Requests' },
  ];

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
            <div className="absolute right-0 mt-1 w-28 bg-white rounded-xl shadow-lg border border-[#E8EAE6] py-1 z-30 text-xs">
              {['Weekly', 'Monthly', 'Yearly'].map((p) => (
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

      {/* ── CHART CONTAINER WITH Y-AXIS & BARS ─────────────────────── */}
      <div className="flex items-stretch h-52">
        {/* Y-Axis scale from reference */}
        <div className="flex flex-col justify-between text-[11px] font-medium text-gray-400 pr-3 pb-6 select-none shrink-0">
          <span>40</span>
          <span>30</span>
          <span>20</span>
          <span>10</span>
          <span>0</span>
        </div>

        {/* 12 Bars Grid */}
        <div className="flex-1 grid grid-cols-12 gap-1.5 sm:gap-2 items-end pb-6 border-b border-[#F4F5F7]">
          {barData.map((item) => (
            <div
              key={item.month}
              className="flex flex-col items-center justify-end h-full relative group cursor-pointer"
            >
              {/* Stacked Capsule Bar */}
              <div className="w-full max-w-[28px] flex flex-col justify-end items-center transition-transform group-hover:scale-105">
                {/* Top Solid Lime Segment */}
                <div
                  className="w-full rounded-t-md bg-[#D4FF32] transition-all"
                  style={{ height: `${item.solidHeight * 1.6}px` }}
                />

                {/* Bottom Hatched / Striped Segment from reference */}
                <div
                  className="w-full rounded-b-md bar-hatched border-t border-[#D4FF32]/60 transition-all mt-0.5"
                  style={{ height: `${item.hatchedHeight * 1.6}px` }}
                />
              </div>

              {/* Tooltip on hover */}
              <div className="absolute -top-7 opacity-0 group-hover:opacity-100 transition-opacity bg-[#1B1D28] text-white text-[9px] font-bold px-2 py-0.5 rounded-md pointer-events-none whitespace-nowrap z-20 shadow-md">
                {item.totalLabel}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ── X-AXIS LABELS (Jan to Dec) ────────────────────────────── */}
      <div className="flex items-center pl-7 pt-2">
        <div className="flex-1 grid grid-cols-12 gap-1.5 sm:gap-2 text-center">
          {barData.map((item) => (
            <span key={item.month} className="text-[10px] font-medium text-gray-400">
              {item.month}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
};
