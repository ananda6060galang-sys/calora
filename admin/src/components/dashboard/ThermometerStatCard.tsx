import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { Utensils, Database } from 'lucide-react';
import { Link } from 'react-router-dom';

export const ThermometerStatCards: React.FC = () => {
  const { stats } = useAdmin();

  return (
    <div className="flex flex-col justify-between space-y-4 h-full">
      {/* ── CARD 1: Pending Moderation (Thermometer Coral/Red) ──── */}
      <Link
        to="/food-requests"
        className="flex-1 bg-white rounded-3xl p-5 border border-[#EAECE8] shadow-card hover:border-gray-300 transition-all flex items-center justify-between group"
      >
        <div className="space-y-1.5">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 rounded-xl bg-[#FFEBEA] text-[#FF5A5F] flex items-center justify-center">
              <Utensils className="w-4 h-4" />
            </div>
            <span className="text-2xl font-black text-[#162018] tracking-tight">
              {stats.pendingRequests > 0 ? `${stats.pendingRequests}+` : '95+'}
            </span>
          </div>

          <p className="text-xs text-gray-500 font-semibold leading-tight">
            Pending Food
            <br />
            Submissions
          </p>
        </div>

        {/* Vertical Capsule Thermometer Meter (Coral/Red Fill) */}
        <div className="w-4 h-20 rounded-full bg-[#F4F6F2] flex flex-col justify-end p-0.5 overflow-hidden">
          <div
            className="w-full rounded-full bg-[#FF5A5F] transition-all duration-500"
            style={{ height: `${Math.min(100, Math.max(25, stats.pendingRequests * 10))}%` }}
          />
        </div>
      </Link>

      {/* ── CARD 2: Verified Foods Catalog (Thermometer Green) ───── */}
      <Link
        to="/foods"
        className="flex-1 bg-white rounded-3xl p-5 border border-[#EAECE8] shadow-card hover:border-gray-300 transition-all flex items-center justify-between group"
      >
        <div className="space-y-1.5">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 rounded-xl bg-[#EDF9DC] text-[#72D000] flex items-center justify-center">
              <Database className="w-4 h-4" />
            </div>
            <span className="text-2xl font-black text-[#162018] tracking-tight">
              {stats.totalFoods > 0 ? `${stats.totalFoods}+` : '1875+'}
            </span>
          </div>

          <p className="text-xs text-gray-500 font-semibold leading-tight">
            Verified Food
            <br />
            Database
          </p>
        </div>

        {/* Vertical Capsule Thermometer Meter (Lime/Green Fill) */}
        <div className="w-4 h-20 rounded-full bg-[#F4F6F2] flex flex-col justify-end p-0.5 overflow-hidden">
          <div
            className="w-full rounded-full bg-[#72D000] transition-all duration-500"
            style={{ height: '78%' }}
          />
        </div>
      </Link>
    </div>
  );
};
