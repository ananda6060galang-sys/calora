import React, { useMemo } from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { Link } from 'react-router-dom';
import { Layers, Ban, TrendingUp, ArrowRight } from 'lucide-react';

export const SecondaryMetricsCard: React.FC = () => {
  const { stats, requests } = useAdmin();
  const { t, language } = useThemeLanguage();

  const categoriesCount = stats.totalCategories > 0 ? stats.totalCategories : 8;

  // Real daily submissions from requests today
  const todaySubmissions = useMemo(() => {
    const todayStr = new Date().toISOString().slice(0, 10);
    return requests.filter(
      (r) => r.created_at && r.created_at.startsWith(todayStr)
    ).length;
  }, [requests]);

  const rows = [
    {
      id: 'categories',
      title: t('totalCategories') || (language === 'id' ? 'Total Kategori' : 'Total categories'),
      subtitle: t('inUseLabel') || (language === 'id' ? 'Digunakan' : 'In Use'),
      value: categoriesCount.toString(),
      icon: Layers,
      to: '/categories',
    },
    {
      id: 'rejected',
      title: t('rejectedRequests') || (language === 'id' ? 'Permintaan Ditolak' : 'Rejected requests'),
      subtitle: t('awaitingReview') || (language === 'id' ? 'Menunggu review' : 'Awaiting review'),
      value: '—',
      icon: Ban,
      to: '/food-requests',
    },
    {
      id: 'daily',
      title: t('dailySubmissions') || (language === 'id' ? 'Pengajuan Harian' : 'Daily submissions'),
      subtitle: t('today') || (language === 'id' ? 'Hari Ini' : 'Today'),
      value: todaySubmissions > 0 ? todaySubmissions.toString() : '—',
      icon: TrendingUp,
      to: '/analytics',
    },
  ];

  return (
    <div className="rounded-[24px] p-6 sm:p-7 bg-[#EDF7E7] dark:bg-[#17261B] text-stone-900 dark:text-white shadow-soft hover-card-lift flex flex-col justify-between border-0 h-full select-none animate-card-rise stagger-4">
      {/* ── CARD HEADER (Original app strings, extra status dot removed) ── */}
      <div className="pb-3 border-b border-black/[0.05] dark:border-white/[0.06]">
        <h3 className="text-base sm:text-lg font-semibold tracking-tight text-stone-900 dark:text-white">
          {t('foodTaxonomy') || (language === 'id' ? 'Kategori Makanan' : 'Food Categories')}
        </h3>
        <p className="text-xs text-stone-600 dark:text-stone-300 font-normal mt-0.5">
          {t('quickStatsSubtitle') || (language === 'id' ? 'Ringkasan database makanan publik.' : 'Overview of public nutrition database.')}
        </p>
      </div>

      {/* ── STACKED ROWS: EQUAL HEIGHTS, 1PX FAINT DIVIDERS, VALUES IN SAME SIZE & WEIGHT ── */}
      <div className="flex-1 flex flex-col divide-y divide-black/[0.04] dark:divide-white/[0.05] my-2">
        {rows.map((row) => {
          const Icon = row.icon;
          const isDash = row.value === '—';

          return (
            <Link
              key={row.id}
              to={row.to}
              className="flex-1 flex items-center justify-between py-3.5 group transition-colors"
            >
              <div className="flex items-center space-x-3.5">
                {/* 40px Icon Circle */}
                <div className="w-10 h-10 rounded-full bg-white dark:bg-white/10 flex items-center justify-center text-[#16A34A] dark:text-[#B8FF3B] shadow-2xs shrink-0 group-hover:scale-105 transition-transform">
                  <Icon className="w-4 h-4 stroke-[1.8]" />
                </div>
                <div>
                  <h4 className="text-sm font-medium text-stone-900 dark:text-white group-hover:text-[#16A34A] dark:group-hover:text-[#B8FF3B] transition-colors leading-tight">
                    {row.title}
                  </h4>
                  <p className="text-xs text-stone-600 dark:text-stone-400 font-normal mt-0.5 leading-tight">
                    {row.subtitle}
                  </p>
                </div>
              </div>

              {/* Large Value on the right: same size and weight, soft aligned dash */}
              <div className="text-right pl-3 shrink-0">
                <span className={`text-2xl sm:text-[28px] font-semibold tabular-nums tracking-tight leading-none ${
                  isDash ? 'text-stone-400 dark:text-stone-500 font-light' : 'text-stone-900 dark:text-white'
                }`}>
                  {row.value}
                </span>
              </div>
            </Link>
          );
        })}
      </div>

      {/* ── FOOTER: DIRECTLY UNDER ROWS ── */}
      <div className="pt-3 border-t border-black/[0.05] dark:border-white/[0.06] flex items-center justify-between text-xs">
        <Link
          to="/categories"
          className="font-medium text-[#16A34A] dark:text-[#B8FF3B] hover:underline flex items-center space-x-1"
        >
          <span>{t('viewAll') || (language === 'id' ? 'Lihat semua' : 'View all')}</span>
          <ArrowRight className="w-3.5 h-3.5" />
        </Link>
        <span className="text-xs text-stone-500 dark:text-stone-400 font-normal">
          Calora Console
        </span>
      </div>
    </div>
  );
};
