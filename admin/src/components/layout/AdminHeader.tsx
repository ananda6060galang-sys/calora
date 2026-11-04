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
    <header className="w-full h-14 sm:h-16 flex items-center justify-between gap-4 mb-8 transition-colors select-none">
      {/* ── LEFT: QUIET 16-18PX MEDIUM LABEL (Matching Reference) ──── */}
      <div className="flex items-center space-x-3 shrink-0">
        {toggleMobileNav && (
          <button
            onClick={toggleMobileNav}
            title="Open menu"
            aria-label="Open menu"
            className="md:hidden p-2 rounded-full text-stone-600 dark:text-gray-400 hover:text-stone-900 dark:hover:text-white hover:bg-black/5 dark:hover:bg-white/5 cursor-pointer transition-colors"
          >
            <Menu className="w-5 h-5 stroke-[1.8]" />
          </button>
        )}

        <div className="flex items-center space-x-2 cursor-pointer group">
          <span className="text-[16px] sm:text-[18px] font-medium text-stone-600 dark:text-stone-300 tracking-normal">
            {title || 'Calora Admin'}
          </span>
          <ChevronDown className="w-4 h-4 text-stone-400 group-hover:text-stone-700 dark:group-hover:text-stone-300 transition-colors" />
        </div>
      </div>

      {/* ── CENTER: ROUNDED SEARCH (Soft Fill, No Heavy Border) ────── */}
      {showSearch && (
        <div className="relative flex-1 max-w-sm mx-2 md:mx-6">
          <Search className="w-4 h-4 text-stone-400 dark:text-gray-500 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none stroke-[1.8]" />
          <input
            type="text"
            value={currentSearch}
            onChange={(e) => handleSearch(e.target.value)}
            placeholder={searchPlaceholder || t('searchPlaceholder')}
            className="w-full bg-white dark:bg-[#141C16] border-0 text-xs text-stone-900 dark:text-white placeholder-stone-400 dark:placeholder-gray-500 rounded-full pl-10 pr-8 py-2.5 shadow-soft focus:outline-none focus:ring-2 focus:ring-[#B8FF3B]/50 transition-all"
          />
          {currentSearch && (
            <button
              onClick={() => handleSearch('')}
              aria-label="Clear search"
              className="absolute right-3 top-1/2 -translate-y-1/2 text-stone-400 hover:text-stone-700 dark:hover:text-white cursor-pointer"
            >
              <X className="w-3.5 h-3.5 stroke-[2]" />
            </button>
          )}
        </div>
      )}

      {/* ── RIGHT: 40PX CIRCLES & PRIMARY DARK PILL BUTTON ──────────── */}
      <div className="flex items-center space-x-2.5 shrink-0">
        {/* Sync Data Circle */}
        <button
          onClick={() => refreshAll()}
          title={t('syncData')}
          aria-label={t('syncData')}
          className="w-10 h-10 rounded-full bg-white dark:bg-[#141C16] hover:bg-stone-50 dark:hover:bg-white/[0.04] flex items-center justify-center text-stone-600 dark:text-gray-300 hover:text-stone-900 dark:hover:text-white transition-all shadow-soft cursor-pointer active:scale-95 border-0"
        >
          <RotateCw className={`w-4 h-4 stroke-[1.8] ${isLoading ? 'animate-spin text-[#16A34A] dark:text-[#B8FF3B]' : ''}`} />
        </button>

        {/* Notification Bell Circle */}
        <div className="relative">
          <button
            title="Notifications"
            aria-label="Notifications"
            className="w-10 h-10 rounded-full bg-white dark:bg-[#141C16] hover:bg-stone-50 dark:hover:bg-white/[0.04] flex items-center justify-center text-stone-600 dark:text-gray-300 hover:text-stone-900 dark:hover:text-white transition-all shadow-soft cursor-pointer active:scale-95 border-0"
          >
            <Bell className="w-4 h-4 stroke-[1.8]" />
          </button>
          {stats.pendingRequests > 0 && (
            <span className="absolute -top-0.5 -right-0.5 w-4 h-4 rounded-full bg-[#E53935] text-white text-[10px] font-bold flex items-center justify-center pointer-events-none ring-2 ring-white dark:ring-[#0B120C]">
              {stats.pendingRequests > 9 ? '9+' : stats.pendingRequests}
            </span>
          )}
        </div>

        {/* Primary CTA: Add Food (Dark Pill with Lime Plus Icon) */}
        {actionLabel && onAction && (
          <button
            onClick={onAction}
            className="h-10 px-5 rounded-full bg-[#0B120C] hover:bg-[#162118] dark:bg-[#17221A] dark:hover:bg-[#1F2F23] text-white text-xs font-semibold tracking-normal flex items-center space-x-1.5 transition-all shadow-soft cursor-pointer active:scale-95 border-0"
          >
            <ActionIcon className="w-3.5 h-3.5 text-[#B8FF3B] stroke-[2.5]" />
            <span className="font-semibold text-white">{actionLabel}</span>
          </button>
        )}
      </div>
    </header>
  );
};
