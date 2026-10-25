import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { Link } from 'react-router-dom';
import {
  Apple,
  Layers,
  Clock,
  CheckCircle2,
  Ban,
  TrendingUp,
} from 'lucide-react';

export const DashboardStatCards: React.FC = () => {
  const { stats, requests } = useAdmin();
  const { t } = useThemeLanguage();

  const formatCount = (val: number): string => {
    if (!val || val <= 0) return '—';
    if (val >= 1000) {
      return `${(val / 1000).toFixed(1)}K`;
    }
    return val.toLocaleString();
  };

  // Count submissions made today
  const todayStr = new Date().toISOString().slice(0, 10);
  const dailySubmissions = requests.filter(
    (r) => r.created_at && r.created_at.startsWith(todayStr)
  ).length;

  const cards = [
    {
      label: t('totalFoods'),
      value: formatCount(stats.totalFoods),
      icon: Apple,
      iconBg: 'bg-[#F2F5F0] dark:bg-[#1C261F] text-[#111111] dark:text-[#E2E8DF]',
      to: '/foods',
    },
    {
      label: t('totalCategories'),
      value: stats.totalCategories > 0 ? stats.totalCategories.toString() : '—',
      icon: Layers,
      iconBg: 'bg-[#F2F5F0] dark:bg-[#1C261F] text-[#111111] dark:text-[#E2E8DF]',
      to: '/categories',
    },
    {
      label: t('pendingRequests'),
      value: stats.pendingRequests > 0 ? stats.pendingRequests.toString() : '—',
      icon: Clock,
      iconBg: 'bg-[#B8FF3B] text-[#0C2417]',
      to: '/food-requests',
    },
    {
      label: t('approvedRequests'),
      value: formatCount(stats.approvedRequests),
      icon: CheckCircle2,
      iconBg: 'bg-[#F2F5F0] dark:bg-[#1C261F] text-[#111111] dark:text-[#E2E8DF]',
      to: '/food-requests',
    },
    {
      label: t('rejectedRequests'),
      value: stats.rejectedRequests > 0 ? stats.rejectedRequests.toString() : '—',
      icon: Ban,
      iconBg: 'bg-[#F2F5F0] dark:bg-[#1C261F] text-[#111111] dark:text-[#E2E8DF]',
      to: '/food-requests',
    },
    {
      label: t('dailySubmissions'),
      value: dailySubmissions > 0 ? dailySubmissions.toString() : '—',
      icon: TrendingUp,
      iconBg: 'bg-[#F2F5F0] dark:bg-[#1C261F] text-[#111111] dark:text-[#E2E8DF]',
      to: '/food-requests',
    },
  ];

  return (
    <section className="space-y-3">
      {/* Section Header */}
      <div>
        <h2 className="text-base sm:text-lg font-bold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
          {t('quickStats')}
        </h2>
        <p className="text-xs text-gray-500 dark:text-gray-400">
          {t('quickStatsSubtitle')}
        </p>
      </div>

      {/* 6 Metric Cards Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-6 gap-3 sm:gap-4">
        {cards.map((card) => {
          const Icon = card.icon;
          return (
            <Link
              key={card.label}
              to={card.to}
              className="bg-white dark:bg-[#141C17] rounded-2xl p-4 border border-[#E9EFE8] dark:border-[#212E23] shadow-xs hover:border-gray-300 dark:hover:border-gray-600 transition-all group flex flex-col items-center justify-center text-center cursor-pointer"
            >
              {/* Icon badge */}
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center text-xs shrink-0 mb-2 transition-transform group-hover:scale-105 ${card.iconBg}`}
              >
                <Icon className="w-4 h-4" strokeWidth={1.8} />
              </div>

              {/* Number first */}
              <span className="text-xl sm:text-2xl font-bold text-[#111111] dark:text-[#F3F5EF] tracking-tight block">
                {card.value}
              </span>

              {/* Label second */}
              <span className="text-[11px] font-medium text-gray-500 dark:text-gray-400 truncate max-w-full block mt-0.5">
                {card.label}
              </span>
            </Link>
          );
        })}
      </div>
    </section>
  );
};
