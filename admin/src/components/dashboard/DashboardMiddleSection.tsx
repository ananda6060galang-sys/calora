import React, { useState } from 'react';
import {
  RiPieChartFill,
  RiSparklingFill,
  RiArrowRightLine,
} from 'react-icons/ri';
import { Link } from 'react-router-dom';
import { useAdmin } from '../../context/AdminContext';

export const DashboardMiddleSection: React.FC = () => {
  const { stats } = useAdmin();
  const [activeRange, setActiveRange] = useState<'today' | '7d' | '30d'>('today');

  return (
    <div className="grid grid-cols-1 xl:grid-cols-12 gap-5 mb-6">
      {/* ── LEFT CARD: MACRO DISTRIBUTION & INTAKE (7 cols) ─────────── */}
      <div className="xl:col-span-7 bg-white dark:bg-[#181E19] rounded-2xl p-6 border border-[#EAECE8] dark:border-[#263226] shadow-xs flex flex-col justify-between transition-colors">
        {/* Header */}
        <div className="flex items-center justify-between mb-5">
          <div>
            <div className="flex items-center space-x-2">
              <RiPieChartFill className="w-4 h-4 text-[#16A34A] dark:text-[#3DDC84]" />
              <h3 className="text-base font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
                Macro Distribution &amp; Daily Intake
              </h3>
            </div>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
              Aggregate nutritional balance across active mobile user logs
            </p>
          </div>

          <div className="flex items-center space-x-1 p-1 rounded-xl bg-gray-100 dark:bg-[#202820] text-[11px] font-bold">
            <button
              onClick={() => setActiveRange('today')}
              className={`px-2.5 py-1 rounded-lg transition-all cursor-pointer ${
                activeRange === 'today'
                  ? 'bg-white dark:bg-[#181E19] text-[#111111] dark:text-[#F3F5EF] shadow-2xs font-extrabold'
                  : 'text-gray-500 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              Today
            </button>
            <button
              onClick={() => setActiveRange('7d')}
              className={`px-2.5 py-1 rounded-lg transition-all cursor-pointer ${
                activeRange === '7d'
                  ? 'bg-white dark:bg-[#181E19] text-[#111111] dark:text-[#F3F5EF] shadow-2xs font-extrabold'
                  : 'text-gray-500 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              7 Days
            </button>
          </div>
        </div>

        {/* Content: Donut on left, stats & categories on right */}
        <div className="flex flex-col sm:flex-row items-center sm:items-start justify-between gap-6">
          {/* Big Macro Donut Chart */}
          <div className="relative w-44 h-44 shrink-0 flex items-center justify-center">
            <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
              {/* Protein (28% - Coral #FF6B57) */}
              <circle
                cx="50"
                cy="50"
                r="38"
                fill="none"
                stroke="#FF6B57"
                strokeWidth="14"
                strokeDasharray="67 239"
                strokeDashoffset="0"
                className="transition-all duration-500 hover:opacity-90"
              />
              {/* Carbs (48% - Warm Amber #FFC24B) */}
              <circle
                cx="50"
                cy="50"
                r="38"
                fill="none"
                stroke="#FFC24B"
                strokeWidth="14"
                strokeDasharray="115 239"
                strokeDashoffset="-67"
                className="transition-all duration-500 hover:opacity-90"
              />
              {/* Fat (24% - Sky Blue #7C9CFF) */}
              <circle
                cx="50"
                cy="50"
                r="38"
                fill="none"
                stroke="#7C9CFF"
                strokeWidth="14"
                strokeDasharray="57 239"
                strokeDashoffset="-182"
                className="transition-all duration-500 hover:opacity-90"
              />
            </svg>

            {/* Donut Center Label: Total Calories */}
            <div className="absolute inset-0 flex flex-col items-center justify-center text-center select-none pointer-events-none">
              <span className="text-xl font-black text-[#111111] dark:text-[#F3F5EF] leading-none">
                28.4k
              </span>
              <span className="text-[10px] text-gray-500 dark:text-gray-400 font-semibold mt-1">
                kcal logged
              </span>
            </div>
          </div>

          {/* Right Macro Cards (2x2 Grid) */}
          <div className="flex-1 w-full grid grid-cols-2 gap-3">
            {/* Protein */}
            <div className="p-3 rounded-xl bg-gray-50/70 dark:bg-[#202820] border border-gray-100 dark:border-[#283528]">
              <div className="flex items-center space-x-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-[#FF6B57] shrink-0" />
                <span className="text-[11px] font-bold text-gray-600 dark:text-gray-300">
                  Protein
                </span>
              </div>
              <p className="text-lg font-black text-[#111111] dark:text-[#F3F5EF] mt-1.5">
                28%
              </p>
              <p className="text-[10px] text-gray-400 dark:text-gray-500">
                142g daily average
              </p>
            </div>

            {/* Carbs */}
            <div className="p-3 rounded-xl bg-gray-50/70 dark:bg-[#202820] border border-gray-100 dark:border-[#283528]">
              <div className="flex items-center space-x-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-[#FFC24B] shrink-0" />
                <span className="text-[11px] font-bold text-gray-600 dark:text-gray-300">
                  Carbs
                </span>
              </div>
              <p className="text-lg font-black text-[#111111] dark:text-[#F3F5EF] mt-1.5">
                48%
              </p>
              <p className="text-[10px] text-gray-400 dark:text-gray-500">
                245g daily average
              </p>
            </div>

            {/* Fat */}
            <div className="p-3 rounded-xl bg-gray-50/70 dark:bg-[#202820] border border-gray-100 dark:border-[#283528]">
              <div className="flex items-center space-x-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-[#7C9CFF] shrink-0" />
                <span className="text-[11px] font-bold text-gray-600 dark:text-gray-300">
                  Healthy Fat
                </span>
              </div>
              <p className="text-lg font-black text-[#111111] dark:text-[#F3F5EF] mt-1.5">
                24%
              </p>
              <p className="text-[10px] text-gray-400 dark:text-gray-500">
                54g daily average
              </p>
            </div>

            {/* Fiber / Compliance */}
            <div className="p-3 rounded-xl bg-gray-50/70 dark:bg-[#202820] border border-gray-100 dark:border-[#283528]">
              <div className="flex items-center space-x-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-[#8B7CFF] shrink-0" />
                <span className="text-[11px] font-bold text-gray-600 dark:text-gray-300">
                  Goal Met
                </span>
              </div>
              <p className="text-lg font-black text-[#111111] dark:text-[#F3F5EF] mt-1.5">
                86.4%
              </p>
              <p className="text-[10px] text-gray-400 dark:text-gray-500">
                Within calorie target
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* ── RIGHT CARD: LOGGING & SCANNER WAVE CHART (5 cols) ───────── */}
      <div className="xl:col-span-5 bg-white dark:bg-[#181E19] rounded-2xl p-6 border border-[#EAECE8] dark:border-[#263226] shadow-xs flex flex-col justify-between transition-colors">
        <div>
          {/* Header */}
          <div className="flex items-center justify-between mb-2">
            <div>
              <h3 className="text-sm font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
                Platform Activity &amp; Scans
              </h3>
              <p className="text-[11px] text-gray-400 dark:text-gray-500">
                Mobile food logs vs Gemini AI scanner detections
              </p>
            </div>
          </div>

          {/* Quick Stats Banner */}
          <div className="flex items-center space-x-4 py-2 text-xs">
            <div className="flex items-center space-x-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#16A34A] dark:bg-[#B8FF3B]" />
              <span className="font-extrabold text-[#111111] dark:text-[#F3F5EF]">2,840</span>
              <span className="text-gray-400 text-[11px]">Meal Logs</span>
            </div>
            <div className="flex items-center space-x-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#8B7CFF]" />
              <span className="font-extrabold text-[#111111] dark:text-[#F3F5EF]">1,120</span>
              <span className="text-gray-400 text-[11px]">AI Scans</span>
            </div>
          </div>

          {/* Wave Curve Chart */}
          <div className="w-full h-28 mt-2 relative">
            <svg viewBox="0 0 300 100" preserveAspectRatio="none" className="w-full h-full">
              <defs>
                {/* Green Gradient Fill */}
                <linearGradient id="caloraGreenGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#B8FF3B" stopOpacity="0.4" />
                  <stop offset="100%" stopColor="#B8FF3B" stopOpacity="0.0" />
                </linearGradient>
                {/* Lavender Gradient Fill */}
                <linearGradient id="caloraLavenderGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#8B7CFF" stopOpacity="0.3" />
                  <stop offset="100%" stopColor="#8B7CFF" stopOpacity="0.0" />
                </linearGradient>
              </defs>

              {/* Area 1: Meal logs */}
              <path
                d="M0,80 Q50,40 100,55 T200,25 T300,35 L300,100 L0,100 Z"
                fill="url(#caloraGreenGradient)"
              />
              {/* Stroke 1: Meal logs */}
              <path
                d="M0,80 Q50,40 100,55 T200,25 T300,35"
                fill="none"
                stroke="#16A34A"
                strokeWidth="2.5"
                className="dark:stroke-[#B8FF3B]"
              />

              {/* Stroke 2: AI Scanner */}
              <path
                d="M0,90 Q60,75 120,60 T220,50 T300,45"
                fill="none"
                stroke="#8B7CFF"
                strokeWidth="2"
                strokeDasharray="4 4"
              />
            </svg>
          </div>

          <div className="flex justify-between text-[10px] text-gray-400 mt-1 font-semibold">
            <span>Mon</span>
            <span>Tue</span>
            <span>Wed</span>
            <span>Thu</span>
            <span>Fri</span>
            <span>Sat</span>
            <span>Sun</span>
          </div>
        </div>

        {/* Action Card: Pending Moderation Spotlight */}
        <div className="mt-4 p-3.5 rounded-xl bg-gray-50/80 dark:bg-[#202820] border border-gray-100 dark:border-[#283528] flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 rounded-lg bg-[#B8FF3B] text-[#0C2417] flex items-center justify-center font-bold">
              <RiSparklingFill className="w-4 h-4" />
            </div>
            <div>
              <p className="text-xs font-bold text-[#111111] dark:text-[#F3F5EF]">
                AI Vision Verification
              </p>
              <p className="text-[10px] text-gray-400">
                {stats.pendingRequests} dishes queued for 1-click check
              </p>
            </div>
          </div>

          <Link
            to="/food-requests"
            className="px-3 py-1.5 rounded-lg bg-[#B8FF3B] text-[#0C2417] hover:brightness-105 active:scale-95 text-xs font-extrabold flex items-center space-x-1 cursor-pointer transition-all shadow-2xs"
          >
            <span>Review</span>
            <RiArrowRightLine className="w-3.5 h-3.5" />
          </Link>
        </div>
      </div>
    </div>
  );
};
