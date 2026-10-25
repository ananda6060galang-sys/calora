import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { ArrowUp, MoreHorizontal, Utensils, Database, Target, Users } from 'lucide-react';
import { Link } from 'react-router-dom';

export const ProdexMetricCards: React.FC = () => {
  const { stats } = useAdmin();

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
      {/* ── CARD 1: FEATURED DARK NAVY CARD (From reference) ─────── */}
      <Link
        to="/food-requests"
        className="bg-[#1B1D28] text-white rounded-2xl p-5 relative overflow-hidden shadow-xs hover:shadow-md transition-all group block"
      >
        {/* Top title and lime ... button */}
        <div className="flex items-center justify-between mb-4">
          <span className="text-xs text-gray-300 font-medium">Pending Moderation</span>
          <div className="w-6 h-5 rounded-md bg-[#D4FF32] flex items-center justify-center text-[#111111]">
            <MoreHorizontal className="w-3.5 h-3.5 stroke-[3]" />
          </div>
        </div>

        {/* Main metric */}
        <div className="flex items-baseline space-x-1.5 mb-3">
          <span className="text-2xl font-extrabold tracking-tight text-white">
            {stats.pendingRequests > 0 ? stats.pendingRequests : '12'}
          </span>
          <span className="text-[10px] font-bold text-gray-400">PENDING</span>
        </div>

        {/* Bottom percentage badge */}
        <div className="flex items-center space-x-1 text-[11px] font-bold text-[#D4FF32]">
          <div className="w-4 h-4 rounded-full bg-[#D4FF32]/20 flex items-center justify-center">
            <ArrowUp className="w-2.5 h-2.5 stroke-[3]" />
          </div>
          <span>35.7%</span>
        </div>

        {/* Watermark Graphic on bottom-right */}
        <div className="absolute right-3 bottom-2 text-white/5 pointer-events-none group-hover:scale-110 transition-transform">
          <Utensils className="w-16 h-16 stroke-[1]" />
        </div>
      </Link>

      {/* ── CARD 2: VERIFIED FOODS (White Card from reference) ───── */}
      <Link
        to="/foods"
        className="bg-white rounded-2xl p-5 border border-[#E8EAE6] relative overflow-hidden shadow-xs hover:shadow-md transition-all group block"
      >
        <div className="flex items-center justify-between mb-4">
          <span className="text-xs text-gray-500 font-medium">Verified Foods</span>
          <div className="w-6 h-5 rounded-md bg-[#F4F5F7] flex items-center justify-center text-gray-400">
            <MoreHorizontal className="w-3.5 h-3.5 stroke-[2]" />
          </div>
        </div>

        <div className="flex items-baseline space-x-1.5 mb-3">
          <span className="text-2xl font-extrabold tracking-tight text-[#1A1C29]">
            {stats.totalFoods > 0 ? stats.totalFoods.toLocaleString() : '1,875'}
          </span>
          <span className="text-[10px] font-bold text-gray-400">ITEMS</span>
        </div>

        <div className="flex items-center space-x-1 text-[11px] font-bold text-gray-700">
          <div className="w-4 h-4 rounded-full bg-gray-100 flex items-center justify-center">
            <ArrowUp className="w-2.5 h-2.5 stroke-[3]" />
          </div>
          <span>45.2%</span>
        </div>

        <div className="absolute right-3 bottom-2 text-gray-200/60 pointer-events-none group-hover:scale-110 transition-transform">
          <Database className="w-16 h-16 stroke-[1]" />
        </div>
      </Link>

      {/* ── CARD 3: LOGGED MEALS (White Card from reference) ─────── */}
      <div className="bg-white rounded-2xl p-5 border border-[#E8EAE6] relative overflow-hidden shadow-xs hover:shadow-md transition-all group">
        <div className="flex items-center justify-between mb-4">
          <span className="text-xs text-gray-500 font-medium">Daily Logged Meals</span>
          <div className="w-6 h-5 rounded-md bg-[#F4F5F7] flex items-center justify-center text-gray-400">
            <MoreHorizontal className="w-3.5 h-3.5 stroke-[2]" />
          </div>
        </div>

        <div className="flex items-baseline space-x-1.5 mb-3">
          <span className="text-2xl font-extrabold tracking-tight text-[#1A1C29]">
            9,254
          </span>
          <span className="text-[10px] font-bold text-gray-400">MEALS</span>
        </div>

        <div className="flex items-center space-x-1 text-[11px] font-bold text-gray-700">
          <div className="w-4 h-4 rounded-full bg-gray-100 flex items-center justify-center">
            <ArrowUp className="w-2.5 h-2.5 stroke-[3]" />
          </div>
          <span>25.7%</span>
        </div>

        <div className="absolute right-3 bottom-2 text-gray-200/60 pointer-events-none group-hover:scale-110 transition-transform">
          <Target className="w-16 h-16 stroke-[1]" />
        </div>
      </div>

      {/* ── CARD 4: ACTIVE MEMBERS (White Card from reference) ────── */}
      <Link
        to="/users"
        className="bg-white rounded-2xl p-5 border border-[#E8EAE6] relative overflow-hidden shadow-xs hover:shadow-md transition-all group block"
      >
        <div className="flex items-center justify-between mb-4">
          <span className="text-xs text-gray-500 font-medium">Active Members</span>
          <div className="w-6 h-5 rounded-md bg-[#F4F5F7] flex items-center justify-center text-gray-400">
            <MoreHorizontal className="w-3.5 h-3.5 stroke-[2]" />
          </div>
        </div>

        <div className="flex items-baseline space-x-1.5 mb-3">
          <span className="text-2xl font-extrabold tracking-tight text-[#1A1C29]">
            17,000
          </span>
          <span className="text-[10px] font-bold text-gray-400">USERS</span>
        </div>

        <div className="flex items-center space-x-1 text-[11px] font-bold text-gray-700">
          <div className="w-4 h-4 rounded-full bg-gray-100 flex items-center justify-center">
            <ArrowUp className="w-2.5 h-2.5 stroke-[3]" />
          </div>
          <span>50.7%</span>
        </div>

        <div className="absolute right-3 bottom-2 text-gray-200/60 pointer-events-none group-hover:scale-110 transition-transform">
          <Users className="w-16 h-16 stroke-[1]" />
        </div>
      </Link>
    </div>
  );
};
