import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { FoodRequest } from '../../types';
import { Link } from 'react-router-dom';
import { Minus } from 'lucide-react';

interface PendingFoodRequestsWidgetProps {
  onOpenRequestModal: (req: FoodRequest) => void;
}

export const PendingFoodRequestsWidget: React.FC<PendingFoodRequestsWidgetProps> = ({
  onOpenRequestModal,
}) => {
  const { requests } = useAdmin();
  const { t } = useThemeLanguage();

  const pendingList = requests.filter((r) => r.status === 'pending');
  const displayItems = pendingList.slice(0, 4);

  const formatDate = (iso: string): string => {
    try {
      return new Date(iso).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' });
    } catch {
      return '';
    }
  };

  return (
    <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col justify-between transition-colors duration-200 h-full">
      <div>
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm sm:text-base font-bold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
            {t('pendingFoodRequests')}
          </h3>

          <Link
            to="/food-requests"
            title={t('viewAll')}
            className="text-gray-400 hover:text-gray-600 dark:hover:text-white p-1 rounded-md transition-colors"
          >
            <Minus className="w-3.5 h-3.5 stroke-[2]" />
          </Link>
        </div>

        {/* Requests List */}
        {displayItems.length === 0 ? (
          <div className="py-6 text-center text-sm text-gray-400 dark:text-gray-500">
            {t('noPendingRequests') || 'No pending requests'}
          </div>
        ) : (
          <div className="space-y-3">
            {displayItems.map((item) => (
              <div
                key={item.id}
                className="flex items-center justify-between py-2.5 border-b border-[#F4F7F2] dark:border-[#1F2B21] last:border-none group"
              >
                {/* Details */}
                <div className="overflow-hidden pr-3">
                  <h4 className="text-xs sm:text-sm font-semibold text-[#111111] dark:text-[#F3F5EF] truncate group-hover:text-[#16A34A] dark:group-hover:text-[#B8FF3B] transition-colors">
                    {item.food_name}
                  </h4>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate mt-0.5">
                    {item.category || 'General'}{item.created_at ? ` • ${formatDate(item.created_at)}` : ''}
                  </p>
                </div>

                {/* Review Action (Pill button matching reference) */}
                <button
                  onClick={() => onOpenRequestModal(item)}
                  className="px-4 py-1.5 rounded-full border border-gray-200 dark:border-gray-700 bg-white dark:bg-[#1A241E] hover:bg-gray-50 dark:hover:bg-[#223026] text-[#111111] dark:text-white text-xs font-semibold transition-all shadow-2xs cursor-pointer shrink-0 hover:border-gray-400 active:scale-95"
                >
                  {t('review')}
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="pt-4 mt-2 border-t border-[#F4F7F2] dark:border-[#1F2B21]">
        <Link
          to="/food-requests"
          className="text-xs font-semibold text-[#16A34A] dark:text-[#B8FF3B] hover:underline flex items-center justify-between"
        >
          <span>{t('viewAll')}</span>
          <span className="text-[11px] font-semibold bg-[#EBF7EA] dark:bg-[#152B1E] px-3 py-0.5 rounded-full text-[#16A34A] dark:text-[#B8FF3B]">
            {pendingList.length} {t('pending').toLowerCase()}
          </span>
        </Link>
      </div>
    </div>
  );
};
