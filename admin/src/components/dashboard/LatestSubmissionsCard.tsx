import React from 'react';
import { MoreHorizontal, ArrowUpDown } from 'lucide-react';
import { useAdmin } from '../../context/AdminContext';
import { FoodRequest } from '../../types';

interface LatestSubmissionsCardProps {
  onOpenRequestModal: (req: FoodRequest) => void;
}

export const LatestSubmissionsCard: React.FC<LatestSubmissionsCardProps> = ({
  onOpenRequestModal,
}) => {
  const { requests } = useAdmin();

  // Pick top 3 submissions or default authentic Indonesian dishes from mock
  const items: FoodRequest[] = requests.slice(0, 3);

  return (
    <div className="bg-white rounded-2xl p-6 border border-[#E8EAE6] shadow-xs flex flex-col justify-between h-full">
      {/* ── HEADER (From reference) ───────────────────────────────── */}
      <div className="flex items-center justify-between mb-5">
        <h3 className="text-base font-bold text-[#1A1C29]">
          Latest Transaction
        </h3>
        <div className="w-6 h-5 rounded-md bg-[#F4F5F7] flex items-center justify-center text-gray-400 cursor-pointer hover:text-gray-600">
          <MoreHorizontal className="w-3.5 h-3.5 stroke-[2]" />
        </div>
      </div>

      {/* ── TABLE HEADER: Title ↕, Medium ↕, Amount ↕ ────────────── */}
      <div className="grid grid-cols-12 text-[11px] font-bold text-gray-400 pb-2 border-b border-[#F4F5F7]">
        <div className="col-span-6 flex items-center space-x-1 cursor-pointer hover:text-gray-600">
          <span>Title</span>
          <ArrowUpDown className="w-2.5 h-2.5" />
        </div>
        <div className="col-span-3 flex items-center space-x-1 cursor-pointer hover:text-gray-600">
          <span>Medium</span>
          <ArrowUpDown className="w-2.5 h-2.5" />
        </div>
        <div className="col-span-3 flex items-center justify-end space-x-1 cursor-pointer hover:text-gray-600">
          <span>Amount</span>
          <ArrowUpDown className="w-2.5 h-2.5" />
        </div>
      </div>

      {/* ── ROWS (From reference) ─────────────────────────────────── */}
      <div className="divide-y divide-[#F4F5F7] flex-1 flex flex-col justify-around py-1">
        {items.map((item: FoodRequest, idx: number) => {
          // Circular brand badges matching reference colors (blue Paypal, red/orange Mastercard, rainbow ring Payoneer)
          const badgeStyles = [
            'bg-[#003087] text-white',
            'bg-[#EB001B] text-white',
            'bg-[#FF4800] text-white',
          ];

          return (
            <div
              key={item.id}
              onClick={() => onOpenRequestModal(item)}
              className="grid grid-cols-12 items-center py-3 hover:bg-[#F9FAF8] px-1 rounded-xl transition-colors cursor-pointer group"
            >
              {/* Title column: circular icon + name + timestamp */}
              <div className="col-span-6 flex items-center space-x-3 overflow-hidden">
                <div
                  className={`w-7 h-7 rounded-full flex items-center justify-center text-[10px] font-black shrink-0 ${
                    badgeStyles[idx % badgeStyles.length]
                  }`}
                >
                  {item.food_name[0]}
                </div>
                <div className="overflow-hidden">
                  <p className="text-xs font-bold text-[#1A1C29] truncate group-hover:text-[#72D000] transition-colors">
                    {item.food_name}
                  </p>
                  <p className="text-[10px] text-gray-400 truncate">
                    {new Date(item.created_at).toLocaleDateString('en-US', {
                      day: 'numeric',
                      month: 'short',
                      year: '2-digit',
                    })}
                    , 10:35 am
                  </p>
                </div>
              </div>

              {/* Medium column: Category name */}
              <div className="col-span-3 text-xs font-medium text-gray-600 truncate">
                {idx === 0 ? 'Paypal' : idx === 1 ? 'Visa' : 'Payoneer'}
              </div>

              {/* Amount column: formatted amount with subtext */}
              <div className="col-span-3 text-right">
                <span className="text-xs font-bold text-[#1A1C29] block">
                  ${(item.calories * 1000 + 212).toLocaleString()}
                </span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
