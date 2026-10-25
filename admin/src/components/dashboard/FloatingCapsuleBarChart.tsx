import React, { useState } from 'react';

interface MonthBarData {
  month: string;
  capsules: {
    top: number; // percentage from top
    height: number; // percentage height
    color: string; // hex or tailwind class
    label: string;
  }[];
}

export const FloatingCapsuleBarChart: React.FC = () => {
  const [selectedRange, setSelectedRange] = useState('1 day');

  const ranges = ['1 day', '1 Week', '1 Month', '1 Year', '5 Years', 'All'];

  // 12 months data matching the floating capsule positions and colors in the reference
  const monthsData: MonthBarData[] = [
    {
      month: 'Jan',
      capsules: [{ top: 40, height: 45, color: '#F0F2ED', label: '140 Logs' }],
    },
    {
      month: 'Feb',
      capsules: [{ top: 30, height: 40, color: '#F0F2ED', label: '160 Logs' }],
    },
    {
      month: 'Mar',
      capsules: [{ top: 45, height: 50, color: '#72D000', label: '290 Approved' }],
    },
    {
      month: 'Apr',
      capsules: [{ top: 55, height: 35, color: '#F0F2ED', label: '120 Logs' }],
    },
    {
      month: 'May',
      capsules: [{ top: 38, height: 48, color: '#253528', label: '240 Audited' }],
    },
    {
      month: 'Jun',
      capsules: [{ top: 50, height: 35, color: '#FFB020', label: '180 Pending' }],
    },
    {
      month: 'Jul',
      capsules: [{ top: 60, height: 30, color: '#F0F2ED', label: '110 Logs' }],
    },
    {
      month: 'Aug',
      capsules: [{ top: 48, height: 42, color: '#D4F5A6', label: '210 AI Scanned' }],
    },
    {
      month: 'Sep',
      capsules: [{ top: 32, height: 32, color: '#72D000', label: '340 Approved' }],
    },
    {
      month: 'Oct',
      capsules: [{ top: 35, height: 45, color: '#253528', label: '260 Verified' }],
    },
    {
      month: 'Nov',
      capsules: [{ top: 45, height: 45, color: '#F0F2ED', label: '150 Logs' }],
    },
    {
      month: 'Dec',
      capsules: [{ top: 52, height: 38, color: '#F0F2ED', label: '130 Logs' }],
    },
  ];

  return (
    <div className="bg-white rounded-3xl p-6 border border-[#EAECE8] shadow-card space-y-6">
      {/* ── HEADER & LEGEND (Matching reference) ─────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <h3 className="text-xl font-black text-[#162018] tracking-tight">
          487 Submissions
        </h3>

        {/* Legend dots from reference image */}
        <div className="flex items-center space-x-4 text-xs font-semibold text-gray-500">
          <div className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#72D000]" />
            <span className="text-[#162018]">AI Recommendation</span>
          </div>
          <div className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#253528]" />
            <span>Approved</span>
          </div>
          <div className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#FF5A5F]" />
            <span>Cancelled</span>
          </div>
        </div>
      </div>

      {/* ── 12-MONTH FLOATING CAPSULE BARS ──────────────────────── */}
      <div className="grid grid-cols-12 gap-2 sm:gap-3 items-end h-52 pt-4 px-2">
        {monthsData.map((item) => (
          <div key={item.month} className="flex flex-col items-center h-full justify-between group relative">
            {/* Capsule Bar Track */}
            <div className="w-6 sm:w-8 h-40 relative rounded-full bg-transparent flex justify-center">
              {item.capsules.map((capsule, cIdx) => (
                <div
                  key={cIdx}
                  className="absolute w-full rounded-2xl capsule-bar shadow-xs cursor-pointer"
                  style={{
                    top: `${capsule.top}%`,
                    height: `${capsule.height}%`,
                    backgroundColor: capsule.color,
                  }}
                  title={`${item.month}: ${capsule.label}`}
                />
              ))}
            </div>

            {/* Month Label */}
            <span className="text-[11px] font-semibold text-gray-400 mt-2 group-hover:text-[#162018] transition-colors">
              {item.month}
            </span>

            {/* Hover Tooltip */}
            <div className="absolute -top-6 opacity-0 group-hover:opacity-100 transition-opacity bg-[#162018] text-white text-[9px] font-bold px-2 py-0.5 rounded-md pointer-events-none whitespace-nowrap z-20 shadow-md">
              {item.capsules[0]?.label}
            </div>
          </div>
        ))}
      </div>

      {/* ── BOTTOM SEGMENTED CONTROL (Pill bar from reference) ───── */}
      <div className="pt-2 flex justify-center">
        <div className="inline-flex items-center p-1 rounded-full border border-[#EAECE8] bg-[#F9FAF8] space-x-1 shadow-xs">
          {ranges.map((range) => {
            const isActive = selectedRange === range;
            return (
              <button
                key={range}
                onClick={() => setSelectedRange(range)}
                className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all ${
                  isActive
                    ? 'bg-[#162018] text-white shadow-sm'
                    : 'text-gray-400 hover:text-[#162018]'
                }`}
              >
                {range}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
};
