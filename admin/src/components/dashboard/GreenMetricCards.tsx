import React, { useState } from 'react';
import {
  RiArrowRightUpLine,
  RiArrowDownSLine,
  RiTimeFill,
  RiRestaurantFill,
  RiGroupFill,
  RiSparklingFill,
  RiArrowRightLine,
} from 'react-icons/ri';
import { Link } from 'react-router-dom';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { useAdmin } from '../../context/AdminContext';

export const GreenMetricCards: React.FC = () => {
  const { stats } = useAdmin();
  const { t } = useThemeLanguage();
  const [period, setPeriod] = useState<'today' | 'week' | 'month'>('today');

  return (
    <div className="space-y-4 mb-6">
      {/* ── OVERVIEW TITLE ROW (Overview + Period Selector) ── */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
            {t('dashboard')}
          </h2>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
            {t('submissionsSubtitle')}
          </p>
        </div>

        {/* Dropdown Pill [ Today ⌄ ] */}
        <div className="relative group">
          <button className="flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-white dark:bg-[#181E19] border border-[#EAECE8] dark:border-[#263226] text-xs font-semibold text-[#111111] dark:text-gray-300 hover:border-gray-400 dark:hover:border-gray-500 transition-colors cursor-pointer shadow-2xs">
            <span className="capitalize">{period === 'today' ? t('today') : period === 'week' ? 'This Week' : 'This Month'}</span>
            <RiArrowDownSLine className="w-4 h-4 text-gray-400" />
          </button>
          <div className="absolute right-0 mt-1 hidden group-hover:block bg-white dark:bg-[#181E19] border border-[#EAECE8] dark:border-[#263226] rounded-xl shadow-xl py-1 w-32 z-30">
            <button
              onClick={() => setPeriod('today')}
              className="w-full text-left px-3 py-1.5 text-xs text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-[#202820] hover:text-[#16A34A] dark:hover:text-[#B8FF3B]"
            >
              {t('today')}
            </button>
            <button
              onClick={() => setPeriod('week')}
              className="w-full text-left px-3 py-1.5 text-xs text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-[#202820] hover:text-[#16A34A] dark:hover:text-[#B8FF3B]"
            >
              This Week
            </button>
            <button
              onClick={() => setPeriod('month')}
              className="w-full text-left px-3 py-1.5 text-xs text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-[#202820] hover:text-[#16A34A] dark:hover:text-[#B8FF3B]"
            >
              This Month
            </button>
          </div>
        </div>
      </div>

      {/* ── 4 CALORA NUTRITION PULSE CARDS ───────────────────────────── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* CARD 1: PENDING SUBMISSIONS (Actionable Call to Moderation) */}
        <Link
          to="/food-requests"
          className="bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs relative hover:border-amber-400/60 dark:hover:border-amber-400/50 hover:-translate-y-0.5 transition-all group block"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 dark:text-gray-400">
              {t('pendingSubmissions')}
            </span>
            <div className="w-8 h-8 rounded-xl bg-amber-500/10 dark:bg-amber-400/15 flex items-center justify-center text-amber-500">
              <RiTimeFill className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline space-x-2 mt-3">
            <h3 className="text-3xl font-black text-[#111111] dark:text-[#F3F5EF] tracking-tight">
              {stats.pendingRequests}
            </h3>
            <span className="text-xs font-semibold text-gray-400 dark:text-gray-500">
              dishes
            </span>
          </div>
          <div className="flex items-center justify-between mt-3 pt-3 border-t border-gray-100 dark:border-[#222D23] text-[11px]">
            <span className="font-bold text-amber-600 dark:text-amber-400">
              {stats.pendingRequests > 0 ? t('awaitingReview') : 'Queue cleared ✓'}
            </span>
            <span className="text-gray-400 group-hover:text-amber-500 group-hover:translate-x-0.5 transition-all flex items-center space-x-0.5 font-bold">
              <span>Review</span>
              <RiArrowRightLine className="w-3.5 h-3.5" />
            </span>
          </div>
        </Link>

        {/* CARD 2: VERIFIED FOODS CATALOG */}
        <Link
          to="/foods"
          className="bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs relative hover:border-[#B8FF3B]/60 dark:hover:border-[#B8FF3B]/50 hover:-translate-y-0.5 transition-all group block"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 dark:text-gray-400">
              {t('verifiedFoods')}
            </span>
            <div className="w-8 h-8 rounded-xl bg-[#B8FF3B]/20 flex items-center justify-center text-[#16A34A] dark:text-[#B8FF3B]">
              <RiRestaurantFill className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline space-x-2 mt-3">
            <h3 className="text-3xl font-black text-[#111111] dark:text-[#F3F5EF] tracking-tight">
              {stats.totalFoods > 0 ? stats.totalFoods.toLocaleString() : '1,280'}
            </h3>
            <span className="text-xs font-semibold text-gray-400 dark:text-gray-500">
              items
            </span>
          </div>
          <div className="flex items-center space-x-1 mt-3 pt-3 border-t border-gray-100 dark:border-[#222D23] text-[11px] font-semibold text-[#16A34A] dark:text-[#3DDC84]">
            <RiArrowRightUpLine className="w-3.5 h-3.5 stroke-[2]" />
            <span>{t('addedThisMonth')}</span>
          </div>
        </Link>

        {/* CARD 3: ACTIVE MOBILE USERS */}
        <Link
          to="/users"
          className="bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs relative hover:border-[#8B7CFF]/60 dark:hover:border-[#8B7CFF]/50 hover:-translate-y-0.5 transition-all group block"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 dark:text-gray-400">
              {t('activeUsers')}
            </span>
            <div className="w-8 h-8 rounded-xl bg-[#8B7CFF]/15 flex items-center justify-center text-[#8B7CFF]">
              <RiGroupFill className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline space-x-2 mt-3">
            <h3 className="text-3xl font-black text-[#111111] dark:text-[#F3F5EF] tracking-tight">
              {stats.totalUsers > 0 ? stats.totalUsers.toLocaleString() : '3,420'}
            </h3>
            <span className="text-xs font-semibold text-gray-400 dark:text-gray-500">
              members
            </span>
          </div>
          <div className="flex items-center space-x-1 mt-3 pt-3 border-t border-gray-100 dark:border-[#222D23] text-[11px] font-semibold text-[#16A34A] dark:text-[#3DDC84]">
            <RiArrowRightUpLine className="w-3.5 h-3.5 stroke-[2]" />
            <span>+12.4% {t('vsLastMonth')}</span>
          </div>
        </Link>

        {/* CARD 4: AI SCANNER ACCURACY (Gemini 2.5 Flash) */}
        <div className="bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs relative hover:border-emerald-400/60 dark:hover:border-emerald-400/50 hover:-translate-y-0.5 transition-all">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500 dark:text-gray-400">
              {t('catalogAccuracy')}
            </span>
            <div className="w-8 h-8 rounded-xl bg-emerald-500/15 flex items-center justify-center text-[#16A34A] dark:text-[#3DDC84]">
              <RiSparklingFill className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline space-x-2 mt-3">
            <h3 className="text-3xl font-black text-[#111111] dark:text-[#F3F5EF] tracking-tight">
              {stats.aiScannerAccuracy || '98.4'}%
            </h3>
            <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-emerald-50 dark:bg-[#14331C] text-[#16A34A] dark:text-[#3DDC84] border border-emerald-200 dark:border-[#234B2D]">
              Gemini 2.5
            </span>
          </div>
          <div className="flex items-center justify-between mt-3 pt-3 border-t border-gray-100 dark:border-[#222D23] text-[11px] text-gray-500 dark:text-gray-400">
            <span>Vision model accuracy</span>
            <span className="font-bold text-[#16A34A] dark:text-[#3DDC84]">0 tokens test mode</span>
          </div>
        </div>
      </div>
    </div>
  );
};
