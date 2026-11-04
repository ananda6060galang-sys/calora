import React, { useState, useMemo } from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { getLocaleMonthAbbr } from '../../lib/utils';
import { Activity } from 'lucide-react';

interface MonthlyData {
  month: string;
  submitted: number;
  approved: number;
}

export const FoodRequestActivityChart: React.FC = () => {
  const { requests } = useAdmin();
  const { t, language } = useThemeLanguage();
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  // Month abbreviations according to active locale
  const monthAbbr = useMemo(() => getLocaleMonthAbbr(language), [language]);

  // Build real monthly data from requests
  const data: MonthlyData[] = useMemo(() => {
    const buckets: Record<string, { submitted: number; approved: number }> = {};
    monthAbbr.forEach((m) => (buckets[m] = { submitted: 0, approved: 0 }));

    requests.forEach((r) => {
      if (!r.created_at) return;
      const d = new Date(r.created_at);
      if (isNaN(d.getTime())) return;
      const monthIdx = d.getMonth();
      const key = monthAbbr[monthIdx];
      if (key && buckets[key]) {
        buckets[key].submitted += 1;
        if (r.status === 'approved') {
          buckets[key].approved += 1;
        }
      }
    });

    return monthAbbr.map((month) => ({ month, ...buckets[month] }));
  }, [requests, monthAbbr]);

  // Clean, unique integer ticks with compact top headroom to avoid 40% blank space
  const { chartMax, yTicks } = useMemo(() => {
    const rawMax = Math.max(...data.map((d) => Math.max(d.submitted, d.approved)), 1);

    if (rawMax <= 3) {
      const top = 3;
      return { chartMax: top, yTicks: [3, 2, 1, 0] };
    }

    if (rawMax <= 4) {
      return { chartMax: 4, yTicks: [4, 3, 2, 1, 0] };
    }

    const step = Math.ceil(rawMax / 4);
    const top = step * 4;
    return { chartMax: top, yTicks: [top, top - step, top - 2 * step, top - 3 * step, 0] };
  }, [data]);

  const hasAnyActivity = useMemo(() => {
    return data.some((d) => d.submitted > 0 || d.approved > 0);
  }, [data]);

  // Find peak submission month
  const peakIndex = useMemo(() => {
    let bestIdx = 0;
    let bestVal = -1;
    data.forEach((item, idx) => {
      if (item.submitted > bestVal) {
        bestVal = item.submitted;
        bestIdx = idx;
      }
    });
    return bestVal > 0 ? bestIdx : -1;
  }, [data]);

  const activeIndex = hoveredIndex !== null ? hoveredIndex : (peakIndex !== -1 ? peakIndex : null);
  const activeItem = activeIndex !== null ? data[activeIndex] : null;
  const activeValue = activeItem ? Math.max(activeItem.submitted, activeItem.approved) : 0;

  // Clamped horizontal position for floating tooltip pill to prevent clipping & legend overlap
  const tooltipLeftPercent = useMemo(() => {
    if (activeIndex === null) return 50;
    const rawPct = ((activeIndex + 0.5) / data.length) * 100;
    // Clamp between 15% and 68% so it never overlaps the top-right legend or card edges
    return Math.max(15, Math.min(68, rawPct));
  }, [activeIndex, data.length]);

  return (
    <div className="rounded-[24px] p-6 sm:p-7 bg-white dark:bg-[#141C16] shadow-soft hover-card-lift border-0 h-full flex flex-col justify-between select-none animate-card-rise stagger-3 relative">
      {/* ── HEADER & LEGEND WITH SMALL DOTS (Image B Match) ─────────── */}
      <div className="flex flex-col sm:flex-row sm:items-baseline justify-between gap-3 mb-5">
        <div>
          <h3 className="text-base sm:text-lg font-semibold text-stone-900 dark:text-white tracking-tight">
            {t('foodRequestActivity') || (language === 'id' ? 'Aktivitas Permintaan Makanan' : 'Food Request Activity')}
          </h3>
          <p className="text-xs text-stone-500 dark:text-stone-400 mt-0.5 font-normal">
            {language === 'id'
              ? 'Aktivitas pengajuan komunitas vs makanan terverifikasi'
              : 'Community submission activity vs verified foods'}
          </p>
        </div>

        {/* Legend top-right with small dots (Comfortably clear of tooltip) */}
        <div className="flex items-center space-x-5 text-xs self-start sm:self-auto font-normal shrink-0">
          <div className="flex items-center space-x-1.5">
            <span className="w-2 h-2 rounded-full bg-[#B8FF3B] shrink-0" />
            <span className="text-stone-700 dark:text-stone-300">
              {t('submittedRequests') || (language === 'id' ? 'Diajukan' : 'Submitted')}
            </span>
          </div>
          <div className="flex items-center space-x-1.5">
            <span className="w-2 h-2 rounded-full bg-[#18261B] dark:bg-[#3D5643] shrink-0" />
            <span className="text-stone-500 dark:text-stone-400">
              {t('approvedFoods') || (language === 'id' ? 'Disetujui' : 'Approved')}
            </span>
          </div>
        </div>
      </div>

      {!hasAnyActivity && requests.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center py-12 text-center">
          <Activity className="w-6 h-6 text-stone-400 mb-2" />
          <p className="text-xs text-stone-500">
            {language === 'id' ? 'Belum ada data aktivitas pengajuan' : 'No submission activity recorded yet'}
          </p>
        </div>
      ) : (
        <div className="flex-1 flex flex-col justify-end pt-2">
          {/* Chart Canvas Area with Y-Axis */}
          <div className="flex items-stretch h-56 sm:h-60 select-none relative">
            {/* Y-Axis numbers (clean integer ticks, no axis line) */}
            <div className="flex flex-col justify-between text-xs text-stone-400 dark:text-stone-500 pr-3 pb-6 shrink-0 text-right tabular-nums font-normal pt-7">
              {yTicks.map((tick) => (
                <span key={tick}>{tick}</span>
              ))}
            </div>

            {/* Soft Sunken Tinted Plot Area (Matching Reference Shaded Plot Container) */}
            <div className="flex-1 relative bg-[#F8FAF6]/90 dark:bg-white/[0.02] rounded-2xl px-2 sm:px-4 pt-8 pb-6 flex flex-col justify-end overflow-visible">
              {/* Horizontal faint dashed guide lines at integer ticks only */}
              <div className="absolute inset-0 pt-8 pb-6 px-2 sm:px-4 flex flex-col justify-between pointer-events-none">
                {yTicks.map((tick) => (
                  <div
                    key={tick}
                    className="w-full border-b border-stone-200/50 dark:border-white/[0.04] border-dashed"
                  />
                ))}
              </div>

              {/* Single dashed reference line through highlighted value like the reference (82.6 CCI line) */}
              {activeValue > 0 && (
                <div
                  style={{ bottom: `${(activeValue / chartMax) * 100}%` }}
                  className="absolute left-2 right-2 sm:left-4 sm:right-4 border-b border-stone-800/40 dark:border-[#B8FF3B]/50 border-dashed pointer-events-none z-10 transition-all duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none"
                />
              )}

              {/* Dark Tooltip Pill Positioned cleanly ABOVE the plot area, clamped inside card, never overlapping legend */}
              {activeItem && (activeItem.submitted > 0 || activeItem.approved > 0) && (
                <div
                  style={{ left: `${tooltipLeftPercent}%` }}
                  className="absolute -top-7 -translate-x-1/2 z-20 pointer-events-none transition-all duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] whitespace-nowrap motion-reduce:transition-none"
                >
                  <div className="px-3.5 py-1 rounded-full bg-[#0B120C] text-white text-xs font-semibold shadow-xl border border-white/10 flex items-center space-x-1.5">
                    <span className="text-[#B8FF3B] font-bold">{activeItem.month}:</span>
                    <span>{activeItem.submitted} {language === 'id' ? 'diajukan' : 'submitted'}</span>
                    <span className="text-white/30">•</span>
                    <span className="text-stone-300">{activeItem.approved} {language === 'id' ? 'disetujui' : 'approved'}</span>
                  </div>
                  {/* Subtle downward pointer */}
                  <div className="w-2 h-2 rotate-45 bg-[#0B120C] mx-auto -mt-1 border-r border-b border-white/10" />
                </div>
              )}

              {/* 12 Evenly Spaced Columns with ONE Wide Soft Track per Month (14-16px wide, rounded 8px) */}
              <div className="relative z-10 w-full h-full flex items-end justify-between">
                {data.map((item, idx) => {
                  const isSelected = idx === activeIndex;
                  const submittedPercent = Math.min(100, Math.max(0, (item.submitted / chartMax) * 100));
                  const approvedPercent = Math.min(100, Math.max(0, (item.approved / chartMax) * 100));

                  return (
                    <div
                      key={item.month}
                      onMouseEnter={() => setHoveredIndex(idx)}
                      onMouseLeave={() => setHoveredIndex(null)}
                      className="flex-1 flex flex-col items-center justify-end h-full relative cursor-pointer group py-0.5"
                    >
                      {/* ONE wide soft track per month (14-16px wide, full height, rounded 8px) */}
                      <div
                        className={`w-3.5 sm:w-4 h-full rounded-[8px] relative flex flex-col justify-end overflow-hidden transition-all duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] ${
                          isSelected
                            ? 'bg-[#0B120C] dark:bg-[#162319] shadow-[0_0_12px_rgba(184,255,59,0.35)]'
                            : 'bg-[#EDF2EB] dark:bg-[#1A251D]'
                        }`}
                      >
                        {/* 1. Submitted value: Highlighted column is a DARK COLUMN like W4 in reference; other months are LIME */}
                        {submittedPercent > 0 && (
                          <div
                            style={{ height: `${submittedPercent}%` }}
                            className={`w-full rounded-[8px] transition-all duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none ${
                              isSelected
                                ? 'bg-[#0B120C] dark:bg-[#1B291D] border-t-2 border-[#B8FF3B]'
                                : 'bg-[#B8FF3B]'
                            }`}
                          />
                        )}

                        {/* 2. Approved as a narrower dark green-black bar overlaid inside the same slot */}
                        {approvedPercent > 0 && (
                          <div
                            style={{ height: `${approvedPercent}%` }}
                            className={`absolute bottom-0 left-1/2 -translate-x-1/2 w-[8px] sm:w-[9px] rounded-t-[4px] transition-all duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none ${
                              isSelected
                                ? 'bg-[#18261B] dark:bg-[#344C3A]'
                                : 'bg-[#18261B] dark:bg-[#344C3A]'
                            }`}
                          />
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* X-Axis Month Labels in sentence case (12px muted, locale-aware EN/ID) */}
          <div className="flex justify-between pl-7 sm:pl-8 pr-2 sm:pr-4 pt-3 text-stone-400 dark:text-stone-500 tabular-nums">
            {data.map((item, idx) => (
              <span
                key={item.month}
                className={`flex-1 text-center transition-colors text-[10px] sm:text-[12px] tracking-tight sm:tracking-normal ${
                  idx === activeIndex
                    ? 'text-stone-900 dark:text-white font-semibold'
                    : 'hover:text-stone-700 dark:hover:text-gray-300 font-normal'
                }`}
              >
                {item.month}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
