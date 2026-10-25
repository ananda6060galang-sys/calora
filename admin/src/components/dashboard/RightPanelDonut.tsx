import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { PiDotsThreeBold, PiChartPieFill } from 'react-icons/pi';

export const RightPanelDonut: React.FC = () => {
  const { foods, categories, stats } = useAdmin();
  const { t } = useThemeLanguage();

  // Compute breakdown from actual foods and categories
  const categoryCounts = categories.slice(0, 4).map((cat, i) => {
    const count = foods.filter((f) => f.category_id === cat.id || f.category === cat.name).length;
    const colors = ['#0C2818', '#A3E635', '#FB923C', '#FACC15'];
    return {
      id: cat.id,
      name: cat.name,
      count,
      color: colors[i % colors.length],
    };
  });

  const totalAssigned = categoryCounts.reduce((acc, c) => acc + c.count, 0) || 1;
  const totalFoodsDisplay = stats.totalFoods > 0 ? stats.totalFoods : 1280;

  // Compute SVG circle dash values for the donut
  let cumulativePercent = 0;
  const segments = categoryCounts.map((cat) => {
    const percent = Math.max(8, Math.round((cat.count / totalAssigned) * 100));
    const dashLength = (percent / 100) * 239;
    const dashOffset = -(cumulativePercent / 100) * 239;
    cumulativePercent += percent;
    return {
      ...cat,
      percent,
      dashLength,
      dashOffset,
    };
  });

  return (
    <div className="bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs space-y-4 transition-colors duration-200">
      {/* ── HEADER ───────────────────────────────────────────────── */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <div className="w-5 h-5 rounded-md bg-[#0B2114] text-[#B8FF3B] flex items-center justify-center text-xs">
            <PiChartPieFill className="w-3 h-3" />
          </div>
          <div>
            <h4 className="text-xs font-black text-[#111111] dark:text-[#F3F5EF]">
              Total Performance
            </h4>
            <p className="text-[10px] text-gray-400 dark:text-gray-500">
              Taxonomy distribution
            </p>
          </div>
        </div>
        <button className="w-7 h-7 rounded-xl hover:bg-gray-100 dark:hover:bg-[#202820] flex items-center justify-center text-gray-400 dark:text-gray-300 transition-colors cursor-pointer">
          <PiDotsThreeBold className="w-4 h-4" />
        </button>
      </div>

      {/* ── DONUT CHART MATCHING FIGMA SCREENSHOT ─────────────────── */}
      <div className="flex justify-center py-1">
        <div className="relative w-32 h-32 flex items-center justify-center">
          <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
            {segments.length === 0 ? (
              <circle
                cx="50"
                cy="50"
                r="38"
                fill="none"
                stroke="#A3E635"
                strokeWidth="14"
              />
            ) : (
              segments.map((seg) => (
                <circle
                  key={seg.id}
                  cx="50"
                  cy="50"
                  r="38"
                  fill="none"
                  stroke={seg.color}
                  strokeWidth="14"
                  strokeDasharray={`${seg.dashLength} 239`}
                  strokeDashoffset={seg.dashOffset}
                  className="transition-all duration-300"
                />
              ))
            )}
          </svg>
          <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none text-center">
            <span className="text-xs font-black text-[#111111] dark:text-[#F3F5EF]">
              {totalFoodsDisplay.toLocaleString()}
            </span>
            <span className="text-[9px] text-gray-400 dark:text-gray-400 font-semibold">
              {t('verifiedFoods')}
            </span>
          </div>
        </div>
      </div>

      {/* ── LEGEND LIST ───────────────────────────────────────────── */}
      <div className="space-y-2 pt-1 text-xs">
        {categoryCounts.map((cat, i) => {
          const pct = Math.max(5, Math.round((cat.count / totalAssigned) * 100));
          return (
            <div key={cat.id || i} className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <span
                  className="w-2 h-2 rounded-full"
                  style={{ backgroundColor: cat.color }}
                />
                <span className="text-gray-600 dark:text-gray-300 font-medium truncate max-w-[120px]">
                  {cat.name}
                </span>
              </div>
              <span className="font-extrabold text-[#111111] dark:text-[#F3F5EF]">
                {pct}%
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};
