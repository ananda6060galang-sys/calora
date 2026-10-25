import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import {
  PiClockFill,
  PiCheckCircleFill,
  PiForkKnifeFill,
  PiUsersThreeFill,
} from 'react-icons/pi';
import { Link } from 'react-router-dom';

export const DashboardKpis: React.FC = () => {
  const { requests, foods, users } = useAdmin();
  const { t } = useThemeLanguage();

  const pendingCount = requests.filter((r) => r.status === 'pending').length;
  const approvedCount = requests.filter((r) => r.status === 'approved').length;
  const totalFoodsCount = foods.length;
  const totalUsersCount = users.length;

  const kpis = [
    {
      label: t('pendingTab'),
      value: pendingCount,
      unit: 'dishes',
      description: pendingCount > 0 ? 'Awaiting verification' : 'Queue is clear',
      tag: pendingCount > 0 ? 'Action required' : 'Up to date',
      tagColor:
        pendingCount > 0
          ? 'bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-400 border border-amber-200 dark:border-amber-800'
          : 'bg-emerald-100 text-emerald-800 dark:bg-[#14331C] dark:text-[#3DDC84] border border-emerald-200 dark:border-[#234B2D]',
      icon: PiClockFill,
      iconColor: pendingCount > 0 ? 'text-amber-500' : 'text-emerald-500',
      iconBg: pendingCount > 0 ? 'bg-amber-50 dark:bg-amber-950/30' : 'bg-emerald-50 dark:bg-[#14331C]',
      to: '/food-requests',
    },
    {
      label: t('approvedTab'),
      value: approvedCount,
      unit: 'submissions',
      description: 'Accepted into database',
      tag: `${requests.length > 0 ? Math.round((approvedCount / requests.length) * 100) : 100}% approval rate`,
      tagColor:
        'bg-emerald-50 text-emerald-700 dark:bg-[#14331C] dark:text-[#3DDC84] border border-emerald-200 dark:border-[#234B2D]',
      icon: PiCheckCircleFill,
      iconColor: 'text-[#16A34A] dark:text-[#3DDC84]',
      iconBg: 'bg-emerald-50 dark:bg-[#14331C]',
      to: '/food-requests',
    },
    {
      label: t('verifiedFoods'),
      value: totalFoodsCount,
      unit: 'items',
      description: 'Public calorie database',
      tag: 'Catalog active',
      tagColor:
        'bg-gray-100 text-gray-700 dark:bg-[#202820] dark:text-gray-300 border border-gray-200 dark:border-[#2D382D]',
      icon: PiForkKnifeFill,
      iconColor: 'text-[#16A34A] dark:text-[#B8FF3B]',
      iconBg: 'bg-[#B8FF3B]/15',
      to: '/foods',
    },
    {
      label: t('activeUsers'),
      value: totalUsersCount,
      unit: 'members',
      description: 'Registered mobile accounts',
      tag: `${users.filter((u) => u.role === 'admin').length} admins`,
      tagColor:
        'bg-gray-100 text-gray-700 dark:bg-[#202820] dark:text-gray-300 border border-gray-200 dark:border-[#2D382D]',
      icon: PiUsersThreeFill,
      iconColor: 'text-[#8B7CFF]',
      iconBg: 'bg-[#8B7CFF]/15',
      to: '/users',
    },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {kpis.map((kpi, idx) => {
        const Icon = kpi.icon;
        return (
          <Link
            key={idx}
            to={kpi.to}
            className="p-5 bg-white dark:bg-[#181E19] rounded-2xl border border-[#EAECE8] dark:border-[#263226] shadow-xs hover:border-gray-300 dark:hover:border-gray-600 transition-all block group cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-gray-500 dark:text-gray-400">
                {kpi.label}
              </span>
              <div
                className={`w-8 h-8 rounded-xl ${kpi.iconBg} ${kpi.iconColor} flex items-center justify-center`}
              >
                <Icon className="w-4 h-4" />
              </div>
            </div>

            <div className="flex items-baseline space-x-2 mt-3">
              <span className="text-3xl font-black text-[#111111] dark:text-[#F3F5EF] tracking-tight">
                {kpi.value}
              </span>
              <span className="text-xs font-semibold text-gray-400 dark:text-gray-500">
                {kpi.unit}
              </span>
            </div>

            <div className="flex items-center justify-between mt-3 pt-3 border-t border-gray-100 dark:border-[#222D23] text-[11px]">
              <span className="text-gray-500 dark:text-gray-400 truncate">
                {kpi.description}
              </span>
              <span
                className={`px-2 py-0.5 rounded-md text-[10px] font-bold ${kpi.tagColor} shrink-0 ml-1`}
              >
                {kpi.tag}
              </span>
            </div>
          </Link>
        );
      })}
    </div>
  );
};
