import React from 'react';
import { useOutletContext } from 'react-router-dom';
import { AdminHeader } from '../components/layout/AdminHeader';
import { DashboardStatCards } from '../components/dashboard/DashboardStatCards';
import { FoodRequestActivityChart } from '../components/dashboard/FoodRequestActivityChart';
import { PendingFoodRequestsWidget } from '../components/dashboard/PendingFoodRequestsWidget';
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
    <div className="w-full space-y-6 animate-fade-in pb-12">
      {/* Top Header */}
      <AdminHeader
        title={t('consoleTitle')}
        actionLabel={t('addFood')}
        onAction={handleOpenFoodModal}
        searchPlaceholder={t('searchPlaceholder')}
      />

      {/* 1. Quick Stats (6 Cards Row matching Figma) */}
      <DashboardStatCards />

      {/* 2. Middle Section: Activity Chart & Pending Requests */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-stretch">
        {/* Left: Food Request Activity Dual Bar Chart (8 cols) */}
        <div className="xl:col-span-8 flex flex-col">
          <FoodRequestActivityChart />
        </div>

        {/* Right: Pending Food Requests Review List (4 cols) */}
        <div className="xl:col-span-4 flex flex-col">
          <PendingFoodRequestsWidget
            onOpenRequestModal={handleOpenRequestModal}
          />
        </div>
      </div>

      {/* 3. Bottom Section: Public Food Database */}
      <PublicFoodDatabaseTable
        onOpenFoodModal={handleOpenFoodModal}
        onEditFood={handleEditFood}
      />
    </div>
  );
};
