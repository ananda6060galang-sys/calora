import React, { useState } from 'react';
import { Outlet, Navigate } from 'react-router-dom';
import { useAdmin } from '../../context/AdminContext';
import { AdminSidebar } from './AdminSidebar';
import { RequestDetailModal } from '../modals/RequestDetailModal';
import { FoodFormModal } from '../modals/FoodFormModal';
import { ToastContainer } from '../ui/ToastContainer';
import { FoodRequest, Food } from '../../types';

export const AdminLayout: React.FC = () => {
  const { user, isLoading } = useAdmin();
  const [selectedRequest, setSelectedRequest] = useState<FoodRequest | null>(null);
  const [selectedFood, setSelectedFood] = useState<Food | null>(null);
  const [isRequestModalOpen, setIsRequestModalOpen] = useState<boolean>(false);
  const [isFoodModalOpen, setIsFoodModalOpen] = useState<boolean>(false);
  const [isMobileNavOpen, setIsMobileNavOpen] = useState<boolean>(false);

  const handleOpenRequestModal = (req: FoodRequest) => {
    setSelectedRequest(req);
    setIsRequestModalOpen(true);
  };

  const handleOpenFoodModal = () => {
    setSelectedFood(null);
    setIsFoodModalOpen(true);
  };

  const handleEditFood = (food: Food) => {
    setSelectedFood(food);
    setIsFoodModalOpen(true);
  };

  const handleToggleMobileNav = () => {
    setIsMobileNavOpen((prev) => !prev);
  };

  if (isLoading) {
    return (
      <div className="h-screen w-screen flex items-center justify-center bg-[#F8FAF6] dark:bg-[#0C120E]">
        <div className="flex flex-col items-center space-y-3">
          <div className="w-10 h-10 rounded-full border-2 border-[#B8FF3B] border-t-transparent animate-spin" />
          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400">Loading Calora Console...</p>
        </div>
      </div>
    );
  }

  // Auth gate
  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (user.role !== 'admin') {
    return <Navigate to="/access-denied" replace />;
  }

  return (
    <div className="h-screen w-screen overflow-hidden flex bg-[#F4F6F2] dark:bg-[#0B120C] text-[#111111] dark:text-[#F3F5EF] font-sans antialiased selection:bg-[#B8FF3B] selection:text-[#0C2417] transition-colors duration-200 p-0 md:p-3 lg:p-3.5 gap-0 md:gap-4 relative">
      {/* ── LEFT: REFINED CALORA FLOATING SIDEBAR (LOCKED) ── */}
      <AdminSidebar
        onOpenFoodModal={handleOpenFoodModal}
        isMobileOpen={isMobileNavOpen}
        onCloseMobile={() => setIsMobileNavOpen(false)}
      />

      {/* ── RIGHT: FLAT WARM OFF-WHITE CONTENT AREA (32px Page Padding, Max 1440px) ── */}
      <main className="flex-1 h-full overflow-y-auto min-w-0 flex flex-col p-6 sm:p-8 custom-scrollbar bg-transparent">
        <div className="w-full max-w-[1440px] mx-auto pb-12">
          <Outlet
            context={{
              handleOpenRequestModal,
              handleOpenFoodModal,
              handleEditFood,
              onToggleMobileMenu: handleToggleMobileNav,
            }}
          />
        </div>
      </main>

      {/* Global Modals & Toasts */}
      <RequestDetailModal
        request={selectedRequest}
        isOpen={isRequestModalOpen}
        onClose={() => setIsRequestModalOpen(false)}
      />

      <FoodFormModal
        isOpen={isFoodModalOpen}
        foodToEdit={selectedFood}
        onClose={() => {
          setIsFoodModalOpen(false);
          setSelectedFood(null);
        }}
      />

      <ToastContainer />
    </div>
  );
};
