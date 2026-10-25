import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import {
  PiSunDimFill,
  PiMoonStarsFill,
  PiTranslateBold,
  PiArrowClockwiseBold,
  PiPlusBold,
} from 'react-icons/pi';

interface GreenHeaderProps {
  onOpenFoodModal: () => void;
}

export const GreenHeader: React.FC<GreenHeaderProps> = ({ onOpenFoodModal }) => {
  const { refreshAll, isLoading, stats } = useAdmin();
  const { isDark, toggleTheme, language, setLanguage, t } = useThemeLanguage();

  return (
    <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-5 border-b border-[#EAECE8] dark:border-[#222D23] mb-6 transition-colors">
      {/* ── BREADCRUMB / TITLE ──────────────────────────────────────── */}
      <div className="flex items-center space-x-2 text-xs">
        <span className="text-gray-500 dark:text-gray-400 font-medium">
          Calora Console
        </span>
        <span className="text-gray-300 dark:text-gray-600">/</span>
        <span className="text-[#111111] dark:text-[#F3F5EF] font-bold">
          {t('dashboard')}
        </span>

        {stats.pendingRequests > 0 && (
          <span className="ml-2 px-2 py-0.5 rounded-md text-[10px] font-bold bg-amber-100 dark:bg-amber-950/60 text-amber-800 dark:text-amber-400 border border-amber-200 dark:border-amber-800">
            {stats.pendingRequests} to review
          </span>
        )}
      </div>

      {/* ── HEADER ACTIONS (GEN Z PHOSPHOR ICONS) ──────────────────── */}
      <div className="flex items-center space-x-2 self-end sm:self-auto">
        {/* Quick Theme Toggle */}
        <button
          onClick={toggleTheme}
          title={isDark ? t('switchToLight') : t('switchToDark')}
          className="w-8 h-8 rounded-xl bg-white dark:bg-[#181E19] hover:bg-gray-100 dark:hover:bg-[#222D23] border border-[#EAECE8] dark:border-[#263226] flex items-center justify-center text-gray-600 dark:text-gray-400 hover:text-[#111111] dark:hover:text-white transition-colors cursor-pointer shadow-2xs"
        >
          {isDark ? (
            <PiSunDimFill className="w-4 h-4 text-[#B8FF3B]" />
          ) : (
            <PiMoonStarsFill className="w-4 h-4 text-gray-700" />
          )}
        </button>

        {/* Language Switch */}
        <button
          onClick={() => setLanguage(language === 'en' ? 'id' : 'en')}
          title={language === 'en' ? 'Switch to Indonesian' : 'Switch to English'}
          className="px-2.5 h-8 rounded-xl bg-white dark:bg-[#181E19] hover:bg-gray-100 dark:hover:bg-[#222D23] border border-[#EAECE8] dark:border-[#263226] flex items-center space-x-1.5 text-gray-600 dark:text-gray-400 hover:text-[#111111] dark:hover:text-[#B8FF3B] transition-colors cursor-pointer shadow-2xs text-xs font-bold"
        >
          <PiTranslateBold className="w-3.5 h-3.5" />
          <span className="uppercase text-[11px] font-extrabold">{language}</span>
        </button>

        {/* Sync Data */}
        <button
          onClick={() => refreshAll()}
          title={t('syncData')}
          className="w-8 h-8 rounded-xl bg-white dark:bg-[#181E19] hover:bg-gray-100 dark:hover:bg-[#222D23] border border-[#EAECE8] dark:border-[#263226] flex items-center justify-center text-gray-600 dark:text-gray-400 hover:text-[#111111] dark:hover:text-white transition-colors cursor-pointer shadow-2xs"
        >
          <PiArrowClockwiseBold className={`w-4 h-4 ${isLoading ? 'animate-spin text-[#16A34A] dark:text-[#B8FF3B]' : ''}`} />
        </button>

        {/* Add Food Button */}
        <button
          onClick={onOpenFoodModal}
          className="px-3.5 py-1.5 rounded-xl bg-[#B8FF3B] hover:brightness-105 active:scale-95 text-[#0C2417] text-xs font-bold flex items-center space-x-1.5 transition-all shadow-xs cursor-pointer ml-1"
        >
          <PiPlusBold className="w-3.5 h-3.5 text-[#0C2417]" />
          <span>{t('addFood')}</span>
        </button>
      </div>
    </header>
  );
};
