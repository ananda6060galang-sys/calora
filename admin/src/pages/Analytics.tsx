import React from 'react';
import { ActivityChart } from '../components/dashboard/ActivityChart';
import { MacroDistributionChart } from '../components/dashboard/MacroDistributionChart';
import { useAdmin } from '../context/AdminContext';
import { useThemeLanguage } from '../context/ThemeLanguageContext';
import { AdminHeader } from '../components/layout/AdminHeader';
import {
  CheckCircle2,
  AlertCircle,
  BarChart3,
  Clock,
} from 'lucide-react';

export const Analytics: React.FC = () => {
  const { stats, requests } = useAdmin();
  const { t } = useThemeLanguage();

  const totalProcessed = stats.approvedRequests + stats.rejectedRequests;
  const approvalRate =
    totalProcessed > 0
      ? Math.round((stats.approvedRequests / totalProcessed) * 100)
      : 0;
  const rejectionRate =
    totalProcessed > 0
      ? Math.round((stats.rejectedRequests / totalProcessed) * 100)
      : 0;

  const todayStr = new Date().toISOString().slice(0, 10);
  const dailySubmissions = requests.filter(
    (r) => r.created_at && r.created_at.startsWith(todayStr)
  ).length;

  return (
    <div className="space-y-6 animate-fade-in font-sans pb-12">
      {/* Header */}
      <AdminHeader
        title={t('analytics')}
        subtitle={t('analyticsSubtitle')}
        showSearch={false}
      />

      {/* KPI Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5 sm:gap-4">
        {/* Card 1: Approval Rate */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-5.5 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-9 h-9 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-emerald-600 dark:text-emerald-400">
            <CheckCircle2 className="w-4 h-4 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {totalProcessed > 0 ? `${approvalRate}%` : '—'}
          </span>
          <span className="text-xs font-medium text-gray-500 dark:text-gray-400 block mt-1">
            {t('approvalRate')}
          </span>
        </div>

        {/* Card 2: Rejection Rate */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-5.5 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-9 h-9 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-red-500">
            <AlertCircle className="w-4 h-4 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {totalProcessed > 0 ? `${rejectionRate}%` : '—'}
          </span>
          <span className="text-xs font-medium text-gray-500 dark:text-gray-400 block mt-1">
            {t('rejectionRate')}
          </span>
        </div>

        {/* Card 3: Pending Queue */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-5.5 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-9 h-9 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#B8FF3B] text-[#0C2417]">
            <Clock className="w-4 h-4 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {stats.pendingRequests > 0 ? stats.pendingRequests : '0'}
          </span>
          <span className="text-xs font-medium text-gray-500 dark:text-gray-400 block mt-1">
            {t('pendingReview')}
          </span>
        </div>

        {/* Card 4: Daily Submissions */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-5.5 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-9 h-9 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-[#111111] dark:text-[#E2E8DF]">
            <BarChart3 className="w-4 h-4 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {dailySubmissions > 0 ? dailySubmissions : '0'}
          </span>
          <span className="text-xs font-medium text-gray-500 dark:text-gray-400 block mt-1">
            {t('dailySubmissions')}
          </span>
        </div>
      </div>

      {/* Main Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-8">
          <ActivityChart />
        </div>
        <div className="lg:col-span-4">
          <MacroDistributionChart />
        </div>
      </div>
    </div>
  );
};
