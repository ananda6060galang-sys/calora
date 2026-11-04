import React, { useState, useMemo } from 'react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';

export const ActivityChart: React.FC = () => {
  const { requests } = useAdmin();
  const { t, language } = useThemeLanguage();
  const [timeframe, setTimeframe] = useState<'7d' | '30d' | '1y'>('7d');

  const chartData = useMemo(() => {
    const now = new Date();

    if (timeframe === '7d') {
      const days: { name: string; dateStr: string; approved: number; pending: number; rejected: number }[] = [];
      const dayNames =
        language === 'id'
          ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
          : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

      for (let i = 6; i >= 0; i--) {
        const d = new Date(now);
        d.setDate(d.getDate() - i);
        const iso = d.toISOString().slice(0, 10);
        days.push({
          name: dayNames[d.getDay()],
          dateStr: iso,
          approved: 0,
          pending: 0,
          rejected: 0,
        });
      }

      requests.forEach((r) => {
        if (!r.created_at) return;
        const reqDate = r.created_at.slice(0, 10);
        const match = days.find((d) => d.dateStr === reqDate);
        if (match) {
          if (r.status === 'approved') match.approved++;
          else if (r.status === 'pending') match.pending++;
          else if (r.status === 'rejected') match.rejected++;
        }
      });

      return days;
    }

    if (timeframe === '30d') {
      const weekPrefix = language === 'id' ? 'Minggu' : 'Week';
      const weeks = [
        { name: `${weekPrefix} 1`, daysAgoStart: 28, daysAgoEnd: 21, approved: 0, pending: 0, rejected: 0 },
        { name: `${weekPrefix} 2`, daysAgoStart: 21, daysAgoEnd: 14, approved: 0, pending: 0, rejected: 0 },
        { name: `${weekPrefix} 3`, daysAgoStart: 14, daysAgoEnd: 7, approved: 0, pending: 0, rejected: 0 },
        { name: `${weekPrefix} 4`, daysAgoStart: 7, daysAgoEnd: 0, approved: 0, pending: 0, rejected: 0 },
      ];

      requests.forEach((r) => {
        if (!r.created_at) return;
        const diffDays = Math.floor((now.getTime() - new Date(r.created_at).getTime()) / (1000 * 60 * 60 * 24));
        const week = weeks.find((w) => diffDays >= w.daysAgoEnd && diffDays < w.daysAgoStart);
        if (week) {
          if (r.status === 'approved') week.approved++;
          else if (r.status === 'pending') week.pending++;
          else if (r.status === 'rejected') week.rejected++;
        }
      });

      return weeks;
    }

    // 1y quarters
    const quarterPrefix = language === 'id' ? 'K' : 'Q';
    const quarters = [
      { name: `${quarterPrefix}1`, quarterMonths: [0, 1, 2], approved: 0, pending: 0, rejected: 0 },
      { name: `${quarterPrefix}2`, quarterMonths: [3, 4, 5], approved: 0, pending: 0, rejected: 0 },
      { name: `${quarterPrefix}3`, quarterMonths: [6, 7, 8], approved: 0, pending: 0, rejected: 0 },
      { name: `${quarterPrefix}4`, quarterMonths: [9, 10, 11], approved: 0, pending: 0, rejected: 0 },
    ];

    requests.forEach((r) => {
      if (!r.created_at) return;
      const m = new Date(r.created_at).getMonth();
      const q = quarters.find((item) => item.quarterMonths.includes(m));
      if (q) {
        if (r.status === 'approved') q.approved++;
        else if (r.status === 'pending') q.pending++;
        else if (r.status === 'rejected') q.rejected++;
      }
    });

    return quarters;
  }, [requests, timeframe, language]);

  return (
    <div className="p-6 bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] border border-[#EAEFE8] dark:border-[#212E23] shadow-xs">
      {/* Header with Title & Timeframe Selector */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h3 className="text-base font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
            {t('activityChartTitle')}
          </h3>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
            {t('activityChartSubtitle')}
          </p>
        </div>

        <div className="flex items-center space-x-1 p-1 bg-[#EFF2EE] dark:bg-[#1A241E] rounded-full border border-gray-200 dark:border-gray-700 self-start">
          <button
            onClick={() => setTimeframe('7d')}
            className={`px-3 py-1 text-xs font-bold rounded-full transition-all cursor-pointer ${
              timeframe === '7d'
                ? 'bg-[#B8FF3B] text-[#0C2417] shadow-2xs'
                : 'text-gray-500 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            {t('timeframe7d')}
          </button>
          <button
            onClick={() => setTimeframe('30d')}
            className={`px-3 py-1 text-xs font-bold rounded-full transition-all cursor-pointer ${
              timeframe === '30d'
                ? 'bg-[#B8FF3B] text-[#0C2417] shadow-2xs'
                : 'text-gray-500 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            {t('timeframe30d')}
          </button>
          <button
            onClick={() => setTimeframe('1y')}
            className={`px-3 py-1 text-xs font-bold rounded-full transition-all cursor-pointer ${
              timeframe === '1y'
                ? 'bg-[#B8FF3B] text-[#0C2417] shadow-2xs'
                : 'text-gray-500 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            {t('timeframe1y')}
          </button>
        </div>
      </div>

      {/* Legend */}
      <div className="flex items-center space-x-5 text-xs mb-4">
        <div className="flex items-center space-x-2">
          <span className="w-2.5 h-2.5 rounded-full bg-calora-success" />
          <span className="text-gray-600 dark:text-calora-dark-muted font-medium">
            {t('approvedFoods')}
          </span>
        </div>
        <div className="flex items-center space-x-2">
          <span className="w-2.5 h-2.5 rounded-full bg-amber-500" />
          <span className="text-gray-600 dark:text-calora-dark-muted font-medium">
            {t('pendingReview')}
          </span>
        </div>
        <div className="flex items-center space-x-2">
          <span className="w-2.5 h-2.5 rounded-full bg-calora-danger" />
          <span className="text-gray-600 dark:text-calora-dark-muted font-medium">
            {t('rejectedStatus')}
          </span>
        </div>
      </div>

      {/* Recharts Area Chart */}
      <div className="h-64 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
            <defs>
              <linearGradient id="colorApproved" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#3DDC84" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#3DDC84" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="colorPending" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#FFB020" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#FFB020" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" opacity={0.5} />
            <XAxis
              dataKey="name"
              stroke="#9CA3AF"
              fontSize={11}
              tickLine={false}
              axisLine={false}
            />
            <YAxis stroke="#9CA3AF" fontSize={11} tickLine={false} axisLine={false} allowDecimals={false} />
            <Tooltip
              contentStyle={{
                backgroundColor: '#181E19',
                borderColor: '#303830',
                borderRadius: '12px',
                color: '#F3F5EF',
                fontSize: '12px',
              }}
              itemStyle={{ color: '#F3F5EF' }}
            />
            <Area
              type="monotone"
              dataKey="approved"
              stroke="#3DDC84"
              strokeWidth={2.5}
              fillOpacity={1}
              fill="url(#colorApproved)"
            />
            <Area
              type="monotone"
              dataKey="pending"
              stroke="#FFB020"
              strokeWidth={2.5}
              fillOpacity={1}
              fill="url(#colorPending)"
            />
            <Area
              type="monotone"
              dataKey="rejected"
              stroke="#FF5A5F"
              strokeWidth={1.8}
              strokeDasharray="4 4"
              fillOpacity={0}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};
