import React from 'react';
import { useOutletContext } from 'react-router-dom';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import {
  Menu,
  Search,
  X,
  RotateCw,
  Bell,
  Plus,
  ChevronDown,
} from 'lucide-react';

interface AdminHeaderProps {
  title?: string;
  subtitle?: string;
  actionLabel?: string;
  onAction?: () => void;
  actionIcon?: React.ComponentType<{ className?: string }>;
  showSearch?: boolean;
  onSearchChange?: (val: string) => void;
  searchValue?: string;
  searchPlaceholder?: string;
  onToggleMobileMenu?: () => void;
}

export const AdminHeader: React.FC<AdminHeaderProps> = ({
  title,
  actionLabel,
  onAction,
  actionIcon: ActionIcon = Plus,
  showSearch = true,
  onSearchChange,
  searchValue,
  searchPlaceholder,
  onToggleMobileMenu,
}) => {
  const { searchQuery, setSearchQuery, stats, isLoading, refreshAll } = useAdmin();
  const { t } = useThemeLanguage();

  // Try to get onToggleMobileMenu from outlet context if not explicitly passed as prop
  const outletCtx = useOutletContext<{ onToggleMobileMenu?: () => void } | null>();
  const toggleMobileNav = onToggleMobileMenu || outletCtx?.onToggleMobileMenu;

  const currentSearch = searchValue !== undefined ? searchValue : searchQuery;
  const handleSearch = (val: string) => {
    if (onSearchChange) {
      onSearchChange(val);
    } else {
      setSearchQuery(val);
    }
  };

  return (
    <header className="w-full flex flex-col md:flex-row md:items-center justify-between gap-3 sm:gap-4 pb-4 border-b border-[#EAECE8] dark:border-[#222D23] mb-6 transition-colors">
      {/* ── LEFT: MOBILE MENU TOGGLE + TITLE ──────────────────────── */}
      <div className="flex items-center space-x-2 shrink-0">
        {/* Mobile Hamburger Button */}
        {toggleMobileNav && (
          <button
            onClick={toggleMobileNav}
            title="Open menu"
            aria-label="Open menu"
            className="md:hidden p-1.5 rounded-lg text-gray-600 dark:text-gray-300 hover:text-[#111111] dark:hover:text-white hover:bg-gray-100 dark:hover:bg-[#1E2E23] cursor-pointer transition-colors"
          >
            <Menu className="w-5 h-5 stroke-[1.8]" />
          </button>
        )}

        <div className="flex items-center space-x-1.5 cursor-pointer group">
          <h1 className="text-base sm:text-lg font-bold text-[#111111] dark:text-[#F3F5EF] tracking-tight group-hover:text-[#16A34A] dark:group-hover:text-[#B8FF3B] transition-colors">
            {title || t('consoleTitle')}
          </h1>
          <ChevronDown className="w-3.5 h-3.5 text-gray-400 group-hover:text-gray-600 dark:group-hover:text-gray-300 transition-colors stroke-[2]" />
        </div>
      </div>

      {/* ── CENTER: SEARCH BAR ───────────────────────────────────── */}
      {showSearch && (
        <div className="relative flex-1 max-w-md mx-0 md:mx-4">
          <Search className="w-3.5 h-3.5 text-gray-400 absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none stroke-[1.8]" />
          <input
            type="text"
            value={currentSearch}
            onChange={(e) => handleSearch(e.target.value)}
            placeholder={searchPlaceholder || t('searchPlaceholder')}
            className="w-full bg-[#F4F6F3] dark:bg-[#181E19] border border-[#E5EAE3] dark:border-[#263226] text-xs text-[#111111] dark:text-[#F3F5EF] placeholder-gray-400 rounded-full pl-9 pr-14 py-2 focus:outline-none focus:border-[#B8FF3B] focus:ring-1 focus:ring-[#B8FF3B] transition-all"
          />
          {currentSearch ? (
            <button
              onClick={() => handleSearch('')}
              aria-label="Clear search"
              className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 cursor-pointer"
            >
              <X className="w-3.5 h-3.5 stroke-[2]" />
            </button>
          ) : (
            <span className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[10px] text-gray-400 font-mono bg-white dark:bg-[#202820] px-1.5 py-0.2 rounded border border-gray-200 dark:border-gray-700 pointer-events-none">
              ⌘K
            </span>
          )}
        </div>
      )}

      {/* ── RIGHT: SYNC + NOTIFICATION + CTA ─────────────────────── */}
      <div className="flex items-center space-x-2 self-end md:self-auto shrink-0">
        {/* Sync Data */}
        <button
          onClick={() => refreshAll()}
          title={t('syncData')}
          aria-label={t('syncData')}
          className="w-8 h-8 rounded-full bg-white dark:bg-[#181E19] hover:bg-gray-50 dark:hover:bg-[#222D23] border border-[#EAECE8] dark:border-[#263226] flex items-center justify-center text-gray-600 dark:text-gray-400 hover:text-[#111111] dark:hover:text-white transition-colors shadow-2xs cursor-pointer"
        >
          <RotateCw className={`w-3.5 h-3.5 stroke-[1.8] ${isLoading ? 'animate-spin text-[#16A34A] dark:text-[#B8FF3B]' : ''}`} />
        </button>

        {/* Notification Bell */}
        <div className="relative">
          <button
            title="Notifications"
            aria-label="Notifications"
            className="w-8 h-8 rounded-full bg-white dark:bg-[#181E19] hover:bg-gray-50 dark:hover:bg-[#222D23] border border-[#EAECE8] dark:border-[#263226] flex items-center justify-center text-gray-600 dark:text-gray-400 hover:text-[#111111] dark:hover:text-white transition-colors shadow-2xs cursor-pointer"
          >
            <Bell className="w-3.5 h-3.5 stroke-[1.8]" />
          </button>
          {stats.pendingRequests > 0 && (
            <span className="absolute -top-1 -right-1 w-3.5 h-3.5 rounded-full bg-[#FF5A5F] text-white text-[8px] font-black flex items-center justify-center shadow-xs pointer-events-none">
              {stats.pendingRequests > 9 ? '9+' : stats.pendingRequests}
            </span>
          )}
        </div>

        {/* Primary CTA */}
        {actionLabel && onAction && (
          <button
            onClick={onAction}
            className="h-8 px-3.5 rounded-full border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#202820] hover:bg-gray-50 dark:hover:bg-[#283528] text-[#111111] dark:text-white text-xs font-bold flex items-center space-x-1.5 shadow-2xs transition-all cursor-pointer ml-1 active:scale-95"
          >
            <span>{actionLabel}</span>
            <ActionIcon className="w-3.5 h-3.5 text-[#111111] dark:text-[#B8FF3B]" />
          </button>
        )}
      </div>
    </header>
  );
};
