import React from 'react';
import { useOutletContext } from 'react-router-dom';
import { AdminHeader } from '../components/layout/AdminHeader';
import { DashboardStatCards } from '../components/dashboard/DashboardStatCards';
import { FoodRequestActivityChart } from '../components/dashboard/FoodRequestActivityChart';
import { SecondaryMetricsCard } from '../components/dashboard/SecondaryMetricsCard';
import { DarkModerationQueueCard } from '../components/dashboard/DarkModerationQueueCard';
import { PublicFoodDatabaseTable } from '../components/dashboard/PublicFoodDatabaseTable';
import { useThemeLanguage } from '../context/ThemeLanguageContext';
import { FoodRequest, Food } from '../types';

interface OutletContextType {
  handleOpenRequestModal: (req: FoodRequest) => void;
  handleOpenFoodModal: () => void;
  handleEditFood?: (food: Food) => void;
}

export const Dashboard: React.FC = () => {
  const { handleOpenRequestModal, handleOpenFoodModal, handleEditFood } =
    useOutletContext<OutletContextType>();
  const { t } = useThemeLanguage();

  return (
    <div className="w-full animate-fade-in pb-12">
      {/* ── ROW 0: TOP HEADER (Quiet 16-18px label, 32px gap below) ── */}
      <AdminHeader
        title={t('consoleTitle') || 'Dashboard'}
        actionLabel={t('addFood') || 'Tambah Makanan'}
        onAction={handleOpenFoodModal}
        searchPlaceholder={t('searchPlaceholder')}
      />

      {/* ── ROW 1: GREETING + PAGE TITLE + 3 EQUAL KPI CARDS (28px Padding, Shared Baseline) ── */}
      <DashboardStatCards />

      {/* ── ROW 2: 8 COLS (Activity Chart) + 4 COLS (Pale Lime-Mint Metric Card) ── */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-stretch mb-6 sm:mb-7">
        {/* Left: Food Request Activity Chart with single soft track per month & floating tooltip (8 cols) */}
        <div className="xl:col-span-8 flex flex-col">
          <FoodRequestActivityChart />
        </div>

        {/* Right: Secondary Metrics Pale Mint Card (4 cols, height matches chart) */}
        <div className="xl:col-span-4 flex flex-col">
          <SecondaryMetricsCard />
        </div>
      </div>

      {/* ── ROW 3: 8 COLS (Public Food Database Table) + 4 COLS (Dark Moderation Queue Card) ── */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-stretch">
        {/* Left: Public Food Database Table (8 cols) */}
        <div className="xl:col-span-8 flex flex-col">
          <PublicFoodDatabaseTable
            onOpenFoodModal={handleOpenFoodModal}
            onEditFood={handleEditFood}
          />
        </div>

        {/* Right: Dark Moderation Queue Card matching table height (4 cols) */}
        <div className="xl:col-span-4 flex flex-col">
          <DarkModerationQueueCard
            onOpenRequestModal={handleOpenRequestModal}
          />
        </div>
      </div>
    </div>
  );
};
