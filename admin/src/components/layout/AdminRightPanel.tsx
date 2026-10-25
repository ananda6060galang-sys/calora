import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { FoodRequest } from '../../types';
import {
  ChevronRight,
  ChevronDown,
  ChevronLeft,
  Utensils,
  Sparkles,
  ShieldCheck,
  Star,
  Activity,
} from 'lucide-react';
import { Link } from 'react-router-dom';

interface AdminRightPanelProps {
  onOpenRequestModal: (req: FoodRequest) => void;
  onOpenFoodModal: () => void;
}

export const AdminRightPanel: React.FC<AdminRightPanelProps> = ({
  onOpenRequestModal,
  onOpenFoodModal,
}) => {
  const { user, urgentRequests } = useAdmin();

  // 7-day strip matching reference (Mon 12, Tue 13 [active with green pill and dot], Wed 14...)
  const today = new Date();
  const currentDay = today.getDate();
  const currentWeekday = today.getDay(); // 0 = Sun, 1 = Mon ...
  const mondayOffset = currentWeekday === 0 ? -6 : 1 - currentWeekday;
  const monday = new Date(today);
  monday.setDate(today.getDate() + mondayOffset);

  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const weekDates = days.map((dayName, index) => {
    const d = new Date(monday);
    d.setDate(monday.getDate() + index);
    return {
      dayName,
      dateNumber: d.getDate(),
      isToday: d.getDate() === currentDay && d.getMonth() === today.getMonth(),
    };
  });

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  return (
    <aside className="w-80 bg-[#1B241E] text-white flex flex-col h-screen sticky top-0 select-none overflow-y-auto p-6 space-y-6 z-20 shrink-0">
      {/* ── 1. ADMIN PROFILE (Exact match to reference) ─────────────── */}
      <div className="flex items-center space-x-3.5">
        <div className="relative">
          <div className="w-12 h-12 rounded-full bg-gradient-to-tr from-[#72D000] to-[#B8FF3B] text-[#111111] font-black text-base flex items-center justify-center ring-2 ring-white/20 shadow-md">
            {user?.name?.[0] || 'G'}
          </div>
          <span className="w-3 h-3 rounded-full bg-[#72D000] absolute bottom-0 right-0 ring-2 ring-[#1B241E]" />
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-center space-x-1.5 cursor-pointer">
            <h4 className="text-sm font-bold text-white truncate">
              {user?.name || 'Galang Wicaksono'}
            </h4>
            <ChevronDown className="w-3.5 h-3.5 text-gray-400 shrink-0" />
          </div>

          <div className="flex items-center space-x-1.5 mt-1.5">
            <span className="inline-flex items-center space-x-1 px-2 py-0.5 text-[10px] font-bold bg-[#72D000]/20 text-[#72D000] rounded-full">
              <ShieldCheck className="w-3 h-3 text-[#72D000]" />
              <span>Super Admin</span>
            </span>
            <span className="inline-flex items-center space-x-1 px-2 py-0.5 text-[10px] font-bold bg-amber-400/20 text-amber-300 rounded-full">
              <Star className="w-3 h-3 fill-amber-300 text-amber-300" />
              <span>PRO</span>
            </span>
          </div>
        </div>
      </div>

      {/* ── 2. CALENDAR STRIP (Exact match to reference) ──────────── */}
      <div className="space-y-3 pt-2">
        <div className="flex items-center justify-between">
          <h5 className="text-xs font-bold text-white">
            {monthNames[today.getMonth()]} {today.getFullYear()}
          </h5>
          <div className="flex items-center space-x-2 text-gray-400">
            <button className="p-1 hover:text-white transition-colors">
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
            <button className="p-1 hover:text-white transition-colors">
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* 7-day pill columns */}
        <div className="grid grid-cols-7 gap-1 text-center items-end">
          {weekDates.map((item, i) => (
            <div
              key={i}
              className={`flex flex-col items-center justify-between py-2 rounded-2xl transition-all ${
                item.isToday
                  ? 'bg-[#72D000] text-[#111111] font-black shadow-md h-16'
                  : 'text-gray-400 hover:text-white h-14'
              }`}
            >
              <span className={`text-[10px] font-semibold ${item.isToday ? 'text-[#111111]' : 'text-gray-400'}`}>
                {item.dayName}
              </span>
              <span className={`text-xs ${item.isToday ? 'font-black text-[#111111]' : 'font-medium text-white'}`}>
                {item.dateNumber}
              </span>
              {/* White dot beneath active day */}
              {item.isToday ? (
                <span className="w-1.5 h-1.5 rounded-full bg-[#111111]" />
              ) : (
                <span className="w-1.5 h-1.5" />
              )}
            </div>
          ))}
        </div>
      </div>

      {/* ── 3. URGENT SUBMISSIONS (3 Rounded Pill Cards) ──────────── */}
      <div className="space-y-3 pt-2">
        <div className="flex items-center justify-between">
          <h5 className="text-xs font-bold text-white">Pending Submissions</h5>
          <Link
            to="/food-requests"
            className="text-[11px] font-semibold text-[#72D000] hover:underline"
          >
            See All
          </Link>
        </div>

        <div className="space-y-2">
          {urgentRequests.slice(0, 3).map((req) => (
            <button
              key={req.id}
              onClick={() => onOpenRequestModal(req)}
              className="w-full text-left p-3.5 rounded-2xl bg-[#252F28] hover:bg-[#2D3830] transition-all flex items-center justify-between group"
            >
              <div className="flex items-center space-x-3 overflow-hidden">
                <div className="w-9 h-9 rounded-xl bg-[#1B241E] text-[#72D000] flex items-center justify-center shrink-0">
                  <Utensils className="w-4 h-4" />
                </div>
                <div className="overflow-hidden">
                  <p className="text-xs font-bold text-white truncate group-hover:text-[#72D000] transition-colors">
                    {req.food_name}
                  </p>
                  <p className="text-[10px] text-gray-400 truncate">
                    {req.calories} kcal • {req.protein_g}g Protein
                  </p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-400 group-hover:text-white shrink-0 ml-2" />
            </button>
          ))}
        </div>
      </div>

      {/* ── 4. BOTTOM PROMO CARD (Nutritional AI Core) ─────────────── */}
      <div className="p-5 rounded-3xl bg-[#252F28] relative overflow-hidden space-y-4">
        {/* Subtle decorative geometric backdrop */}
        <div className="flex items-center space-x-2 text-[10px] font-bold text-gray-400 uppercase tracking-wider">
          <Sparkles className="w-3.5 h-3.5 text-[#72D000]" />
          <span>Calora Pro Engine</span>
        </div>

        <div>
          <h4 className="text-base font-extrabold text-white leading-tight">
            Nutritional AI Core
          </h4>
          <p className="text-[11px] text-gray-400 mt-1 leading-relaxed">
            Multi-modal vision and automated calorie moderation online.
          </p>
        </div>

        <button
          onClick={onOpenFoodModal}
          className="w-full py-3 rounded-full bg-[#72D000] hover:brightness-105 active:scale-98 text-[#111111] font-black text-xs shadow-md transition-all flex items-center justify-center space-x-2"
        >
          <Activity className="w-4 h-4 text-[#111111]" />
          <span>Add Verified Food</span>
        </button>
      </div>
    </aside>
  );
};
