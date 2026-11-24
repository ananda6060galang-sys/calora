import React from 'react';
import { useOutletContext } from 'react-router-dom';
import { useAdmin } from '../context/AdminContext';
import { useThemeLanguage } from '../context/ThemeLanguageContext';
import { ModerationQueueTable } from '../components/dashboard/ModerationQueueTable';
import { FoodRequest } from '../types';
import { AdminHeader } from '../components/layout/AdminHeader';
import {
  Clock,
  CheckCircle2,
  XCircle,
  BarChart3,
  Plus,
} from 'lucide-react';

interface OutletContextType {
  handleOpenRequestModal: (req: FoodRequest) => void;
  handleOpenFoodModal: () => void;
}

export const FoodRequests: React.FC = () => {
  const { handleOpenRequestModal, handleOpenFoodModal } =
    useOutletContext<OutletContextType>();
  const { stats } = useAdmin();
  const { t } = useThemeLanguage();

  const resolutionRate =
    stats.totalRequests > 0
      ? Math.round(
          ((stats.approvedRequests + stats.rejectedRequests) /
            stats.totalRequests) *
            100
        )
      : 100;

  return (
    <div className="space-y-6 animate-fade-in font-sans pb-12">
      {/* ── HEADER ─────────────────────────────────────────────────── */}
      <AdminHeader
        title={t('requestsPageTitle')}
        subtitle={t('requestsPageSubtitle')}
        actionLabel={t('addFoodManually')}
        onAction={handleOpenFoodModal}
        actionIcon={Plus}
        showSearch={false}
      />

      {/* ── 4 STAT CARDS ────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5 sm:gap-4">
        {/* Card 1: Pending */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#B8FF3B] text-[#0C2417]">
            <Clock className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {stats.pendingRequests}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('pendingTab')}
          </span>
        </div>

        {/* Card 2: Approved */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-emerald-600 dark:text-emerald-400">
            <CheckCircle2 className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {stats.approvedRequests}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('approvedTab')}
          </span>
        </div>

        {/* Card 3: Rejected */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-red-500">
            <XCircle className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {stats.rejectedRequests}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('rejectedTab')}
          </span>
        </div>

        {/* Card 4: Resolution Rate */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-[#111111] dark:text-[#E2E8DF]">
            <BarChart3 className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {resolutionRate}%
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('resolutionRate')}
          </span>
        </div>
      </div>

      {/* ── MODERATION QUEUE TABLE ─────────────────────────────────── */}
      <ModerationQueueTable
        onOpenRequestModal={handleOpenRequestModal}
        isFullPage={true}
      />
    </div>
  );
};
