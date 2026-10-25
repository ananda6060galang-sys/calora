import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { formatTimeAgo } from '../../lib/utils';
import { PiDotsThreeBold, PiPulseFill } from 'react-icons/pi';

export const RightPanelActivity: React.FC = () => {
  const { activities } = useAdmin();
  const { t } = useThemeLanguage();

  const userAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100&auto=format&fit=crop&q=80',
  ];

  return (
    <div className="bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs space-y-3 transition-colors duration-200">
      {/* ── HEADER ───────────────────────────────────────────────── */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <div className="w-5 h-5 rounded-md bg-[#0B2114] text-[#B8FF3B] flex items-center justify-center text-xs">
            <PiPulseFill className="w-3 h-3" />
          </div>
          <div>
            <h4 className="text-xs font-black text-[#111111] dark:text-[#F3F5EF]">
              Recent Activity
            </h4>
            <p className="text-[10px] text-gray-400 dark:text-gray-500">
              Audit moderation log
            </p>
          </div>
        </div>
        <button className="w-7 h-7 rounded-xl hover:bg-gray-100 dark:hover:bg-[#202820] flex items-center justify-center text-gray-400 dark:text-gray-300 transition-colors cursor-pointer">
          <PiDotsThreeBold className="w-4 h-4" />
        </button>
      </div>

      <div className="flex items-center justify-between text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider pt-1">
        <span>{t('today')}</span>
        <span>Live</span>
      </div>

      {/* ── ACTIVITY LIST ────────────────────────────────────────── */}
      <div className="space-y-3 pt-1">
        {activities.length === 0 ? (
          <p className="text-xs text-gray-400 py-4 text-center">No recent activity logs.</p>
        ) : (
          activities.slice(0, 4).map((act, idx) => (
            <div key={act.id} className="flex items-start space-x-2.5">
              <img
                src={userAvatars[idx % userAvatars.length]}
                alt="User"
                className="w-7 h-7 rounded-full object-cover shrink-0 ring-1 ring-gray-200 dark:ring-gray-700"
              />
              <div className="overflow-hidden flex-1">
                <p className="text-xs font-bold text-[#111111] dark:text-[#F3F5EF] truncate leading-tight">
                  {act.title}
                </p>
                <p className="text-[11px] text-gray-500 dark:text-gray-400 line-clamp-1 mt-0.5 leading-tight">
                  {act.description}
                </p>
                <p className="text-[10px] text-gray-400 dark:text-gray-500 mt-0.5">
                  {formatTimeAgo(act.timestamp)}
                </p>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
