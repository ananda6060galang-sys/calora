import React, { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  Gauge,
  Utensils,
  Shapes,
  Inbox,
  TrendingUp,
  Users,
  SlidersHorizontal,
  ChevronLeft,
  ChevronRight,
  SunMedium,
  Moon,
  X,
  LogOut,
} from 'lucide-react';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { useAdmin } from '../../context/AdminContext';
import fullLogoImg from '../../assets/full_logo.png';
import iconLogoImg from '../../assets/Icon_logo.png';

interface AdminSidebarProps {
  onOpenFoodModal?: () => void;
  isMobileOpen?: boolean;
  onCloseMobile?: () => void;
}

export const AdminSidebar: React.FC<AdminSidebarProps> = ({
  isMobileOpen = false,
  onCloseMobile,
}) => {
  const [isExpanded, setIsExpanded] = useState<boolean>(true);
  const { isDark, toggleTheme, language, setLanguage, t } = useThemeLanguage();
  const { user, stats, logout } = useAdmin();
  const navigate = useNavigate();

  const mainNavItems = [
    {
      to: '/dashboard',
      label: t('dashboard'),
      icon: Gauge,
      badge: null,
    },
    {
      to: '/foods',
      label: t('foodsCatalog'),
      icon: Utensils,
      badge: null,
    },
    {
      to: '/categories',
      label: t('taxonomy'),
      icon: Shapes,
      badge: null,
    },
    {
      to: '/food-requests',
      label: t('foodRequests'),
      icon: Inbox,
      badge: stats.pendingRequests > 0 ? stats.pendingRequests : null,
    },
    {
      to: '/analytics',
      label: t('analytics'),
      icon: TrendingUp,
      badge: null,
    },
    {
      to: '/users',
      label: t('userDirectory'),
      icon: Users,
      badge: null,
    },
    {
      to: '/settings',
      label: t('systemSettings'),
      icon: SlidersHorizontal,
      badge: null,
    },
  ];

  const handleNavClick = () => {
    if (onCloseMobile) {
      onCloseMobile();
    }
  };

  return (
    <>
      {/* ── MOBILE BACKDROP ────────────────────────────────────────── */}
      {isMobileOpen && (
        <div
          onClick={onCloseMobile}
          className="fixed inset-0 bg-black/60 z-40 backdrop-blur-xs md:hidden transition-opacity"
        />
      )}

      {/* ── SIDEBAR CONTAINER ──────────────────────────────────────── */}
      <aside
        className={`bg-[#0B0F0C] text-gray-300 flex flex-col justify-between py-5 select-none shrink-0 transition-all duration-300 ease-in-out h-screen z-50 border border-[#18261C] border-l-0 rounded-r-[32px] sm:rounded-r-[36px] rounded-l-none shadow-xl shadow-black/10 ${
          /* Mobile Drawer Positioning vs Desktop Sticky */
          isMobileOpen
            ? 'fixed top-0 left-0 w-[245px] px-4 shadow-2xl flex'
            : 'hidden md:flex sticky top-0'
        } ${
          !isMobileOpen && (isExpanded ? 'w-[230px] sm:w-[245px] px-4' : 'w-[76px] px-2.5 items-center')
        }`}
      >
        {/* ── COLLAPSE / EXPAND TOGGLE (Desktop Only) ──────────────── */}
        <button
          onClick={() => setIsExpanded(!isExpanded)}
          title={isExpanded ? t('collapseSidebar') : t('expandSidebar')}
          className="hidden md:flex absolute -right-3 top-7 w-6 h-6 rounded-full bg-[#0B0F0C] border border-[#1E3B2A] text-[#B8FF3B] hover:text-white items-center justify-center shadow-lg transition-all z-40 cursor-pointer hover:scale-110 active:scale-95"
        >
          {isExpanded ? (
            <ChevronLeft className="w-3.5 h-3.5 stroke-[2.2]" />
          ) : (
            <ChevronRight className="w-3.5 h-3.5 stroke-[2.2]" />
          )}
        </button>

        {/* ── CLOSE BUTTON (Mobile Drawer Only) ────────────────────── */}
        {isMobileOpen && (
          <button
            onClick={onCloseMobile}
            className="md:hidden absolute right-3 top-5 p-1 rounded-lg text-gray-400 hover:text-white cursor-pointer"
          >
            <X className="w-5 h-5 stroke-[2]" />
          </button>
        )}

        {/* ── TOP: LOGO ─────────────────────────────────────────────── */}
        <div className="w-full shrink-0">
          <div
            onClick={() => {
              navigate('/dashboard');
              handleNavClick();
            }}
            className={`flex items-center cursor-pointer transition-transform active:scale-95 ${
              isExpanded || isMobileOpen ? 'px-2 pb-2 justify-start' : 'justify-center pb-2'
            }`}
            title="Calora"
          >
            {isExpanded || isMobileOpen ? (
              <div className="h-9 flex items-center">
                <img
                  src={fullLogoImg}
                  alt="Calora"
                  className="h-8 w-auto object-contain"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = '/full_logo.png';
                  }}
                />
              </div>
            ) : (
              <div className="w-10 h-10 rounded-xl bg-[#121A15] border border-[#1E2E23] flex items-center justify-center p-2 shadow-inner hover:border-[#B8FF3B]/50 transition-colors">
                <img
                  src={iconLogoImg}
                  alt="Calora"
                  className="w-full h-full object-contain"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = '/Icon_logo.png';
                  }}
                />
              </div>
            )}
          </div>
        </div>

        {/* ── MIDDLE: NAV ───────────────────────────────────────────── */}
        <nav className="flex-1 w-full overflow-y-auto overflow-x-hidden space-y-1 py-4 custom-scrollbar">
          {mainNavItems.map((item) => {
            const Icon = item.icon;
            const expandedMode = isExpanded || isMobileOpen;

            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={handleNavClick}
                className={({ isActive }) =>
                  `relative flex items-center transition-all duration-200 group cursor-pointer ${
                    expandedMode
                      ? `px-4 py-2.5 rounded-full space-x-3 text-xs tracking-tight ${
                          isActive
                            ? 'bg-[#B8FF3B] text-[#0C2417] font-bold shadow-xs'
                            : 'text-gray-400 hover:text-white hover:bg-[#141C16] font-medium'
                        }`
                      : `justify-center w-10 h-10 mx-auto rounded-xl ${
                          isActive
                            ? 'bg-[#B8FF3B] text-[#0C2417] shadow-xs'
                            : 'text-gray-400 hover:text-white hover:bg-[#141C16]'
                        }`
                  }`
                }
                title={!expandedMode ? item.label : undefined}
              >
                {({ isActive }) => (
                  <>
                    <Icon
                      strokeWidth={1.8}
                      className={`w-[18px] h-[18px] shrink-0 transition-colors ${
                        isActive
                          ? 'text-[#0C2417]'
                          : 'text-gray-400 group-hover:text-white'
                      }`}
                    />

                    {expandedMode && (
                      <span className="truncate flex-1 font-medium">
                        {item.label}
                      </span>
                    )}

                    {item.badge !== null && item.badge !== undefined && (
                      <span
                        className={
                          expandedMode
                            ? `text-[10px] font-bold rounded-full px-1.5 py-0.2 shrink-0 ${
                                isActive
                                  ? 'bg-[#0C2417] text-[#B8FF3B]'
                                  : 'bg-[#B8FF3B] text-[#0C2417]'
                              }`
                            : `absolute top-1.5 right-1.5 w-2 h-2 rounded-full p-0 pointer-events-none ${
                                isActive
                                  ? 'bg-[#0C2417] ring-1 ring-[#0C2417]'
                                  : 'bg-[#B8FF3B] ring-2 ring-[#0B0F0C]'
                              }`
                        }
                      >
                        {expandedMode ? item.badge : null}
                      </span>
                    )}
                  </>
                )}
              </NavLink>
            );
          })}
        </nav>

        {/* ── BOTTOM: CONTROLS + PROFILE ────────────────────────────── */}
        <div className="w-full pt-3 border-t border-[#152419] shrink-0 space-y-3">
          {/* Language + Theme toggles (Clean Apple-like segmented pill) */}
          {isExpanded || isMobileOpen ? (
            <div className="flex items-center gap-2 px-1">
              {/* Language: segmented pill */}
              <div className="flex-1 h-8 rounded-lg bg-[#141C16] p-0.5 flex border border-[#1C281F]">
                <button
                  onClick={() => setLanguage('en')}
                  className={`flex-1 rounded-md text-[11px] font-semibold transition-all duration-200 cursor-pointer ${
                    language === 'en'
                      ? 'bg-[#1E2E23] text-white shadow-xs'
                      : 'text-gray-500 hover:text-gray-300'
                  }`}
                >
                  EN
                </button>
                <button
                  onClick={() => setLanguage('id')}
                  className={`flex-1 rounded-md text-[11px] font-semibold transition-all duration-200 cursor-pointer ${
                    language === 'id'
                      ? 'bg-[#1E2E23] text-white shadow-xs'
                      : 'text-gray-500 hover:text-gray-300'
                  }`}
                >
                  ID
                </button>
              </div>

              {/* Theme toggle */}
              <button
                onClick={toggleTheme}
                title={isDark ? t('switchToLight') : t('switchToDark')}
                className="w-8 h-8 rounded-lg bg-[#141C16] border border-[#1C281F] flex items-center justify-center text-gray-400 hover:text-white transition-colors cursor-pointer shrink-0"
              >
                {isDark ? (
                  <SunMedium className="w-4 h-4 text-[#B8FF3B]" strokeWidth={1.8} />
                ) : (
                  <Moon className="w-3.5 h-3.5" strokeWidth={1.8} />
                )}
              </button>
            </div>
          ) : (
            <div className="flex flex-col items-center gap-2">
              <button
                onClick={() => setLanguage(language === 'en' ? 'id' : 'en')}
                title={language === 'en' ? 'Ganti ke Bahasa Indonesia' : 'Switch to English'}
                className="w-10 h-8 rounded-lg bg-[#141C16] border border-[#1C281F] flex items-center justify-center text-[10px] font-bold text-gray-400 hover:text-white transition-colors cursor-pointer uppercase"
              >
                {language}
              </button>
              <button
                onClick={toggleTheme}
                title={isDark ? t('switchToLight') : t('switchToDark')}
                className="w-10 h-8 rounded-lg bg-[#141C16] border border-[#1C281F] flex items-center justify-center text-gray-400 hover:text-white transition-colors cursor-pointer"
              >
                {isDark ? (
                  <SunMedium className="w-4 h-4 text-[#B8FF3B]" strokeWidth={1.8} />
                ) : (
                  <Moon className="w-3.5 h-3.5" strokeWidth={1.8} />
                )}
              </button>
            </div>
          )}

          {/* Admin profile and Log Out */}
          <div className={`flex ${isExpanded || isMobileOpen ? 'items-center gap-1.5' : 'flex-col items-center gap-2 w-full'}`}>
            <div
              onClick={() => {
                navigate('/settings');
                handleNavClick();
              }}
              className={`flex items-center cursor-pointer p-1.5 rounded-xl hover:bg-[#141C16] transition-colors ${
                isExpanded || isMobileOpen ? 'flex-1 space-x-2.5 overflow-hidden' : 'w-full justify-center'
              }`}
              title={user?.name || 'Admin'}
            >
              <div className="relative w-8 h-8 min-w-[32px] min-h-[32px] rounded-full overflow-hidden ring-1 ring-white/20 shrink-0 aspect-square shadow-xs bg-[#1B281E] flex items-center justify-center text-xs font-bold text-[#B8FF3B]">
                {user?.avatar_url ? (
                  <img
                    src={user.avatar_url}
                    alt={user.name || 'Admin'}
                    className="w-full h-full object-cover rounded-full absolute inset-0"
                    onError={(e) => {
                      (e.currentTarget as HTMLElement).style.display = 'none';
                    }}
                  />
                ) : null}
                <span>{user?.name?.[0]?.toUpperCase() || 'A'}</span>
                <span className="w-2 h-2 rounded-full bg-[#B8FF3B] absolute bottom-0 right-0 ring-1 ring-[#0B0F0C] z-10" />
              </div>

              {(isExpanded || isMobileOpen) && (
                <div className="overflow-hidden flex-1">
                  <h4 className="text-xs font-bold text-white truncate leading-tight">
                    {user?.name || 'Admin'}
                  </h4>
                  <p className="text-[10px] text-gray-400 truncate mt-0.5">
                    {user?.email || 'admin@calora.app'}
                  </p>
                </div>
              )}
            </div>

            {/* Logout button */}
            <button
              onClick={async (e) => {
                e.stopPropagation();
                await logout();
              }}
              title={t('logout')}
              aria-label={t('logout')}
              className={`h-8 rounded-xl flex items-center justify-center text-gray-400 hover:text-rose-400 hover:bg-rose-500/10 border border-transparent hover:border-rose-500/20 transition-all cursor-pointer shrink-0 ${
                isExpanded || isMobileOpen ? 'px-2.5 space-x-1.5' : 'w-8 h-8 mx-auto'
              }`}
            >
              <LogOut className="w-3.5 h-3.5 stroke-[1.8]" />
              {(isExpanded || isMobileOpen) && (
                <span className="text-[11px] font-semibold">{t('logout')}</span>
              )}
            </button>
          </div>
        </div>
      </aside>
    </>
  );
};
