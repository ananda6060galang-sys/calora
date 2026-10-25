import React, { useState, useMemo } from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';

interface MonthlyData {
  month: string;
  submitted: number;
  approved: number;
}

const MONTH_ABBR_EN = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const MONTH_ABBR_ID = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

export const FoodRequestActivityChart: React.FC = () => {
  const { requests } = useAdmin();
  const { isDark, t, language } = useThemeLanguage();
  const [hoveredMonth, setHoveredMonth] = useState<string | null>(null);

  const monthAbbr = useMemo(
    () => (language === 'id' ? MONTH_ABBR_ID : MONTH_ABBR_EN),
    [language]
  );

  // Build real monthly data from requests
  const data: MonthlyData[] = useMemo(() => {
    const buckets: Record<string, { submitted: number; approved: number }> = {};
    monthAbbr.forEach((m) => (buckets[m] = { submitted: 0, approved: 0 }));

    requests.forEach((r) => {
      if (!r.created_at) return;
      const monthIdx = new Date(r.created_at).getMonth();
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

  const maxVal = Math.max(...data.map((d) => Math.max(d.submitted, d.approved)), 1);
  const hasData = requests.length > 0;

  // Find peak submission month for badge
  const peakMonth = data.reduce(
    (best, cur) => (cur.submitted > best.submitted ? cur : best),
    data[0]
  );

  return (
    <div className="bg-white dark:bg-[#141C17] rounded-2xl p-5 sm:p-6 border border-[#E9EFE8] dark:border-[#212E23] shadow-xs transition-colors duration-200 h-full flex flex-col justify-between">
      {/* Header & Legend */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
        <h3 className="text-sm sm:text-base font-bold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
          {t('foodRequestActivity')}
        </h3>

        <div className="flex items-center space-x-4 text-xs font-medium">
          <div className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#B8FF3B]" />
            <span className="text-gray-700 dark:text-gray-200">
              {t('submittedRequests')}
            </span>
          </div>

          <div className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#E0E7DD] dark:bg-[#2A3B2E]" />
            <span className="text-gray-500 dark:text-gray-400">
              {t('approvedFoods')}
            </span>
          </div>
        </div>
      </div>

      {!hasData ? (
        <div className="flex-1 flex items-center justify-center text-sm text-gray-400 dark:text-gray-500 py-10">
          {t('noActivityYet') || 'No activity yet'}
        </div>
      ) : (
        <>
          {/* Bar Chart Area */}
          <div className="flex items-stretch h-56 select-none relative pt-4">
            {/* Y-Axis scale */}
            <div className="flex flex-col justify-between text-[10px] font-semibold text-gray-400 dark:text-gray-500 pr-3 pb-6 shrink-0 text-right">
              <span>{maxVal}</span>
              <span>{Math.round(maxVal * 0.75)}</span>
              <span>{Math.round(maxVal * 0.5)}</span>
              <span>{Math.round(maxVal * 0.25)}</span>
              <span>0</span>
            </div>

            {/* Columns Container */}
            <div className="flex-1 relative flex flex-col justify-end pb-6 border-b border-[#F2F5F0] dark:border-[#222E24]">
              {/* Subtle horizontal grid guide lines */}
              <div className="absolute inset-0 flex flex-col justify-between pointer-events-none pb-6">
                <div className="w-full border-b border-[#F4F7F2] dark:border-[#1F2B21] border-dashed" />
                <div className="w-full border-b border-[#F4F7F2] dark:border-[#1F2B21] border-dashed" />
                <div className="w-full border-b border-[#F4F7F2] dark:border-[#1F2B21] border-dashed" />
                <div className="w-full border-b border-[#F4F7F2] dark:border-[#1F2B21] border-dashed" />
              </div>

              {/* Bars */}
              <div className="relative z-10 w-full h-full flex items-end justify-between px-1">
                {data.map((item) => {
                  const isPeak = item.month === peakMonth.month && peakMonth.submitted > 0;
                  const isHovered = hoveredMonth === item.month;
                  const submittedHeight = `${(item.submitted / maxVal) * 100}%`;
                  const approvedHeight = `${(item.approved / maxVal) * 100}%`;

                  return (
                    <div
                      key={item.month}
                      onMouseEnter={() => setHoveredMonth(item.month)}
                      onMouseLeave={() => setHoveredMonth(null)}
                      className="flex-1 flex flex-col items-center justify-end h-full relative group cursor-pointer"
                    >
                      {/* Floating Peak Badge */}
                      {isPeak && (
                        <div className="absolute -top-3 left-1/2 -translate-x-1/2 z-20 flex flex-col items-center pointer-events-none">
                          <span className="px-2 py-0.5 rounded-full bg-[#B8FF3B] text-[#0C2417] text-[10px] font-bold shadow-xs tracking-tight">
                            {peakMonth.submitted}
                          </span>
                          <span className="w-1 h-1 rounded-full bg-[#0C2417] dark:bg-[#B8FF3B] mt-0.5" />
                        </div>
                      )}

                      {/* Hover tooltip for other months */}
                      {isHovered && !isPeak && item.submitted > 0 && (
                        <div className="absolute -top-6 left-1/2 -translate-x-1/2 z-20 px-2 py-0.5 rounded-md bg-[#0B0F0C] text-white text-[10px] font-medium shadow-md whitespace-nowrap pointer-events-none">
                          {item.submitted} / {item.approved}
                        </div>
                      )}

                      {/* Bars pair */}
                      <div className="flex items-end justify-center space-x-1 w-full max-w-[28px] h-full">
                        {/* Submitted Requests Bar (Lime) */}
                        <div
                          style={{ height: submittedHeight || '2px' }}
                          className={`w-1.5 sm:w-2 rounded-t-full transition-all duration-200 ${
                            isPeak
                              ? 'bg-[#A6F226]'
                              : 'bg-[#B8FF3B] group-hover:brightness-105'
                          }`}
                        />

                        {/* Approved Foods Bar (Soft Grey / Muted) */}
                        <div
                          style={{ height: approvedHeight || '2px' }}
                          className={`w-1.5 sm:w-2 rounded-t-full transition-all duration-200 ${
                            isDark
                              ? 'bg-[#253628] group-hover:bg-[#324836]'
                              : 'bg-[#E3E9E0] group-hover:bg-[#D5DDD1]'
                          }`}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* X-Axis Month Labels */}
          <div className="flex justify-between pl-8 pr-1 pt-2 text-[10px] font-semibold text-gray-400 dark:text-gray-500">
            {data.map((item) => (
              <span
                key={item.month}
                className={`flex-1 text-center transition-colors ${
                  item.month === peakMonth.month && peakMonth.submitted > 0
                    ? 'text-[#111111] dark:text-white font-bold'
                    : ''
                }`}
              >
                {item.month}
              </span>
            ))}
          </div>
        </>
      )}
    </div>
  );
};
