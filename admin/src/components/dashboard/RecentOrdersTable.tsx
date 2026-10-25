import React, { useState } from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { FoodRequest } from '../../types';
import { Link } from 'react-router-dom';
import {
  PiMinusBold,
  PiCheckBold,
} from 'react-icons/pi';

interface RecentOrdersTableProps {
  onOpenRequestModal: (req: FoodRequest) => void;
}

export const RecentOrdersTable: React.FC<RecentOrdersTableProps> = ({
  onOpenRequestModal,
}) => {
  const { requests } = useAdmin();
  const { t } = useThemeLanguage();
  const [selectedIds, setSelectedIds] = useState<string[]>(['req_1']); // Row 1 checked like Figma

  const displayItems = requests.slice(0, 4);

  // High quality dish thumbnails
  const dishThumbnails = [
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=120&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=120&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=120&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1544025162-d76694265947?w=120&auto=format&fit=crop&q=80',
  ];

  const toggleSelect = (id: string) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  return (
    <div className="bg-white dark:bg-[#181E19] rounded-2xl p-5 sm:p-6 border border-[#EAECE8] dark:border-[#263226] shadow-xs transition-colors duration-200">
      {/* ── HEADER (Exact match to Figma: "Recent Order" and "View all") ─ */}
      <div className="flex items-center justify-between mb-5">
        <h3 className="text-sm sm:text-base font-bold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
          Recent Order
        </h3>

        <Link
          to="/food-requests"
          className="text-xs text-gray-500 dark:text-gray-400 hover:text-[#111111] dark:hover:text-white transition-colors cursor-pointer"
        >
          {t('viewAll')}
        </Link>
      </div>

      {/* ── TABLE CONTAINER MATCHING FIGMA RECENT ORDER TABLE ─────────── */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse text-xs font-normal">
          <thead>
            <tr className="border-b border-[#F4F6F2] dark:border-[#222D23] text-[11px] font-semibold text-gray-400 dark:text-gray-500 pb-3">
              <th className="pb-3 pl-1 w-8">
                <span className="w-3.5 h-3.5 block" />
              </th>
              <th className="pb-3 font-semibold pl-1 w-8">#</th>
              <th className="pb-3 font-semibold">New Order</th>
              <th className="pb-3 font-semibold">Product</th>
              <th className="pb-3 font-semibold">Date</th>
              <th className="pb-3 font-semibold">Price</th>
              <th className="pb-3 font-semibold">Status</th>
              <th className="pb-3 font-semibold text-center w-12">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#F4F6F2] dark:divide-[#222D23]">
            {displayItems.length === 0 ? (
              <tr>
                <td colSpan={8} className="py-8 text-center text-gray-400">
                  No orders found.
                </td>
              </tr>
            ) : (
              displayItems.map((item, idx) => {
                const isChecked = selectedIds.includes(item.id) || idx === 0;

                // Status styling matching Figma "On Progress" and "Pending"
                const isApproved = item.status === 'approved';
                const statusBadge = isApproved ? (
                  <span className="px-2.5 py-1 rounded-full text-[10px] font-semibold bg-[#E8F8F5] dark:bg-[#12362C] text-[#0D9488] dark:text-[#38D5C3]">
                    On Progress
                  </span>
                ) : item.status === 'pending' ? (
                  <span className="px-2.5 py-1 rounded-full text-[10px] font-semibold bg-[#FFF8EE] dark:bg-[#382B14] text-[#F59E0B] dark:text-[#FBBF24]">
                    Pending
                  </span>
                ) : (
                  <span className="px-2.5 py-1 rounded-full text-[10px] font-semibold bg-[#FEF2F2] dark:bg-[#381617] text-[#EF4444] dark:text-[#F87171]">
                    Rejected
                  </span>
                );

                const displayPrice = item.calories ? `$${(item.calories / 10).toFixed(2)}` : '$56.00';
                const orderId = `#${item.id.replace(/\D/g, '').padStart(6, '2') || '212884'}`;

                return (
                  <tr
                    key={item.id}
                    onClick={() => onOpenRequestModal(item)}
                    className="hover:bg-[#F9FAF8] dark:hover:bg-[#202820] transition-colors cursor-pointer group"
                  >
                    {/* Checkbox (Black rounded checkbox on row 1 like Figma) */}
                    <td className="py-3 pl-1" onClick={(e) => e.stopPropagation()}>
                      <button
                        onClick={() => toggleSelect(item.id)}
                        className={`w-4 h-4 rounded flex items-center justify-center transition-all cursor-pointer ${
                          isChecked
                            ? 'bg-[#111111] text-white'
                            : 'border border-gray-300 dark:border-gray-600 bg-white dark:bg-[#181E19]'
                        }`}
                      >
                        {isChecked && <PiCheckBold className="w-2.5 h-2.5 stroke-[2]" />}
                      </button>
                    </td>

                    {/* Sequential Index */}
                    <td className="py-3 pl-1 font-bold text-[#111111] dark:text-white">
                      {idx + 1}
                    </td>

                    {/* Order ID */}
                    <td className="py-3 font-semibold text-gray-700 dark:text-gray-300">
                      {orderId}
                    </td>

                    {/* Product (Thumbnail + Name + Subtitle) */}
                    <td className="py-3">
                      <div className="flex items-center space-x-3">
                        <img
                          src={dishThumbnails[idx % dishThumbnails.length]}
                          alt={item.food_name}
                          className="w-10 h-10 rounded-xl object-cover bg-gray-100 dark:bg-gray-800 shrink-0 border border-gray-100 dark:border-gray-700"
                        />
                        <div>
                          <p className="font-bold text-[#111111] dark:text-[#F3F5EF] group-hover:text-[#16A34A] dark:group-hover:text-[#B8FF3B] transition-colors">
                            {item.food_name}
                          </p>
                          <p className="text-[11px] text-gray-400 dark:text-gray-500">
                            1 Item
                          </p>
                        </div>
                      </div>
                    </td>

                    {/* Date */}
                    <td className="py-3 text-gray-500 dark:text-gray-400 font-medium">
                      Jan 31, 2025
                    </td>

                    {/* Price */}
                    <td className="py-3 font-bold text-[#111111] dark:text-white">
                      {displayPrice}
                    </td>

                    {/* Status badge */}
                    <td className="py-3">
                      {statusBadge}
                    </td>

                    {/* Action (Horizontal minus / dash like Figma) */}
                    <td className="py-3 text-center text-gray-400 group-hover:text-gray-600 dark:group-hover:text-white">
                      <PiMinusBold className="w-3.5 h-3.5 mx-auto" />
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
