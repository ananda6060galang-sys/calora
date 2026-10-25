import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { PiDotsThreeBold, PiGaugeFill } from 'react-icons/pi';

export const RightPanelGauge: React.FC = () => {
  const { stats, requests } = useAdmin();

  // Compute live approval / moderation rate
  const totalDecided = stats.approvedRequests + stats.rejectedRequests;
  const resolutionRate =
    stats.totalRequests > 0
      ? Math.min(100, Math.max(10, Math.round((totalDecided / stats.totalRequests) * 100)))
      : 84;

  // Arc math on 180° semi-circle
  // Radius = 65, Arc length = PI * 65 = 204.2
  const totalLength = 204.2;
  const progressLength = (resolutionRate / 100) * totalLength;

  // Needle angle for percentage:
  // 0% -> 180°, 100% -> 0°
  const angleDeg = 180 - (180 * (resolutionRate / 100));
  const angleRad = (angleDeg * Math.PI) / 180;
  const needleLength = 48;
  const needleX = 90 + needleLength * Math.cos(angleRad);
  const needleY = 85 - needleLength * Math.sin(angleRad);

  return (
    <div className="bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs space-y-4 transition-colors duration-200">
      {/* ── HEADER ───────────────────────────────────────────────── */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <div className="w-5 h-5 rounded-md bg-[#0B2114] text-[#B8FF3B] flex items-center justify-center text-xs">
            <PiGaugeFill className="w-3 h-3" />
          </div>
          <div>
            <h4 className="text-xs font-black text-[#111111] dark:text-[#F3F5EF]">
              Moderation Pace
            </h4>
            <p className="text-[10px] text-gray-400 dark:text-gray-500">
              Queue turnaround efficiency
            </p>
          </div>
        </div>
        <button className="w-7 h-7 rounded-xl hover:bg-gray-100 dark:hover:bg-[#202820] flex items-center justify-center text-gray-400 dark:text-gray-300 transition-colors cursor-pointer">
          <PiDotsThreeBold className="w-4 h-4" />
        </button>
      </div>

      {/* ── SEMI-CIRCLE GAUGE METER ───────────────────────────────── */}
      <div className="flex flex-col items-center justify-center pt-2">
        <div className="relative w-44 h-26 flex items-center justify-center">
          <svg viewBox="0 0 180 100" className="w-full h-full overflow-visible">
            <defs>
              <linearGradient id="gaugeGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#1B4D2E" />
                <stop offset="60%" stopColor="#74D100" />
                <stop offset="100%" stopColor="#B8FF3B" />
              </linearGradient>
            </defs>

            {/* Background track arc (180 deg) */}
            <path
              d="M 25 85 A 65 65 0 0 1 155 85"
              fill="none"
              stroke="#F2F4F0"
              strokeWidth="11"
              strokeLinecap="round"
              className="dark:stroke-[#222D23]"
            />

            {/* Active progress arc */}
            <path
              d="M 25 85 A 65 65 0 0 1 155 85"
              fill="none"
              stroke="url(#gaugeGradient)"
              strokeWidth="11"
              strokeLinecap="round"
              strokeDasharray={`${progressLength} ${totalLength}`}
              className="transition-all duration-500"
            />

            {/* Sleek needle line */}
            <line
              x1="90"
              y1="85"
              x2={needleX}
              y2={needleY}
              stroke="#0C2417"
              strokeWidth="2.5"
              strokeLinecap="round"
              className="dark:stroke-[#B8FF3B] transition-all duration-500"
            />

            {/* Needle tip circle */}
            <circle
              cx={needleX}
              cy={needleY}
              r="3.5"
              fill="#0C2417"
              className="dark:fill-[#B8FF3B]"
            />

            {/* Center pivot hub */}
            <circle
              cx="90"
              cy="85"
              r="6"
              fill="#0C2417"
              stroke="#B8FF3B"
              strokeWidth="2"
            />
          </svg>

          {/* Center Readout */}
          <div className="absolute top-6 left-1/2 -translate-x-1/2 text-center pointer-events-none">
            <span className="text-2xl font-black text-[#111111] dark:text-[#F3F5EF] tracking-tight block">
              {resolutionRate}%
            </span>
            <span className="text-[9px] font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-wider block -mt-0.5">
              Turnaround
            </span>
          </div>
        </div>
      </div>

      {/* ── BREAKDOWN PROGRESS BARS ───────────────────────────────── */}
      <div className="space-y-2.5 pt-1 text-xs">
        {/* Approved submissions */}
        <div className="space-y-1">
          <div className="flex items-center justify-between text-[11px]">
            <span className="text-gray-600 dark:text-gray-300 font-medium">
              Approved into Catalog
            </span>
            <span className="font-extrabold text-[#111111] dark:text-[#F3F5EF]">
              {stats.approvedRequests} dishes
            </span>
          </div>
          <div className="w-full h-1.5 bg-gray-100 dark:bg-[#222D23] rounded-full overflow-hidden">
            <div
              className="h-full bg-[#16A34A] dark:bg-[#3DDC84] rounded-full transition-all duration-500"
              style={{
                width: `${
                  requests.length > 0
                    ? Math.round((stats.approvedRequests / requests.length) * 100)
                    : 70
                }%`,
              }}
            />
          </div>
        </div>

        {/* Pending submissions */}
        <div className="space-y-1">
          <div className="flex items-center justify-between text-[11px]">
            <span className="text-gray-600 dark:text-gray-300 font-medium">
              Pending in Queue
            </span>
            <span className="font-extrabold text-amber-600 dark:text-amber-400">
              {stats.pendingRequests} dishes
            </span>
          </div>
          <div className="w-full h-1.5 bg-gray-100 dark:bg-[#222D23] rounded-full overflow-hidden">
            <div
              className="h-full bg-amber-500 rounded-full transition-all duration-500"
              style={{
                width: `${
                  requests.length > 0
                    ? Math.round((stats.pendingRequests / requests.length) * 100)
                    : 25
                }%`,
              }}
            />
          </div>
        </div>

        {/* Rejected submissions */}
        <div className="space-y-1">
          <div className="flex items-center justify-between text-[11px]">
            <span className="text-gray-600 dark:text-gray-300 font-medium">
              Rejected / Filtered
            </span>
            <span className="font-extrabold text-red-500 dark:text-red-400">
              {stats.rejectedRequests} dishes
            </span>
          </div>
          <div className="w-full h-1.5 bg-gray-100 dark:bg-[#222D23] rounded-full overflow-hidden">
            <div
              className="h-full bg-red-400 rounded-full transition-all duration-500"
              style={{
                width: `${
                  requests.length > 0
                    ? Math.round((stats.rejectedRequests / requests.length) * 100)
                    : 5
                }%`,
              }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};
