import React, { useState, useEffect } from 'react';
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
  SunMedium,
  Moon,
  X,
  LogOut,
} from 'lucide-react';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { useAdmin } from '../../context/AdminContext';
import iconLogoImg from '../../assets/Icon_logo.png';
import fullLogoImg from '../../assets/full_logo.png';

interface AdminSidebarProps {
  onOpenFoodModal?: () => void;
  isMobileOpen?: boolean;
  onCloseMobile?: () => void;
}

export const AdminSidebar: React.FC<AdminSidebarProps> = ({
  isMobileOpen = false,
  onCloseMobile,
}) => {
  // Remember collapsed/expanded state across reloads via localStorage
  const [isExpanded, setIsExpanded] = useState<boolean>(() => {
    try {
      const saved = localStorage.getItem('calora_admin_sidebar_expanded');
      return saved !== null ? saved === 'true' : true;
    } catch {
      return true;
    }
  });

  const { isDark, toggleTheme, language, setLanguage, t } = useThemeLanguage();
  const { user, stats, logout } = useAdmin();
  const navigate = useNavigate();

  const handleToggleExpand = () => {
    setIsExpanded((prev) => {
      const next = !prev;
      try {
        localStorage.setItem('calora_admin_sidebar_expanded', String(next));
      } catch {
        // ignore
      }
      return next;
    });
  };

  // Keyboard shortcut Ctrl/Cmd + B to toggle sidebar
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'b') {
        e.preventDefault();
        handleToggleExpand();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

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

  const isWide = isExpanded || isMobileOpen;

  return (
    <>
      {/* ── MOBILE BACKDROP ────────────────────────────────────────── */}
      {isMobileOpen && (
        <div
          onClick={onCloseMobile}
          className="fixed inset-0 bg-black/60 z-40 backdrop-blur-xs md:hidden transition-opacity duration-300"
          aria-hidden="true"
        />
      )}

      {/* ── PREMIUM CALORA FLOATING SIDEBAR CONTAINER ──────────────── */}
      <aside
        className={`bg-[#0B120C] text-gray-300 flex flex-col justify-between py-6 select-none shrink-0 transition-[width,padding] duration-350 ease-[cubic-bezier(0.22,1,0.36,1)] h-full z-50 relative border border-white/[0.08] shadow-[0_20px_45px_rgba(0,0,0,0.25)] md:rounded-[28px] ${
          isMobileOpen
            ? 'fixed top-0 left-0 bottom-0 w-[265px] px-4 shadow-2xl flex z-50 bg-[#0B120C] rounded-none border-r border-white/10'
            : 'hidden md:flex'
        } ${
          !isMobileOpen && (isExpanded ? 'w-[250px] lg:w-[260px] px-4' : 'w-[80px] px-2.5 items-center')
        }`}
      >
        {/* ── COLLAPSE / EXPAND TOGGLE WITH ROTATING CHEVRON (Desktop Only) ── */}
        <button
          onClick={handleToggleExpand}
          aria-expanded={isExpanded}
          aria-label={isExpanded ? t('collapseSidebar') : t('expandSidebar')}
          title={`${isExpanded ? t('collapseSidebar') : t('expandSidebar')} (Ctrl+B)`}
          className="hidden md:flex absolute -right-3.5 top-8 w-7 h-7 rounded-full bg-[#152018] border border-white/15 text-gray-300 hover:text-[#B8FF3B] hover:border-[#B8FF3B]/50 items-center justify-center shadow-lg transition-all duration-300 z-50 cursor-pointer active:scale-95 focus-visible:ring-2 focus-visible:ring-[#B8FF3B] focus-visible:outline-none"
        >
          <ChevronLeft
            className={`w-3.5 h-3.5 stroke-[2.2] transition-transform duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] ${
              !isExpanded ? 'rotate-180' : 'rotate-0'
            }`}
          />
        </button>

        {/* ── CLOSE BUTTON (Mobile Drawer Only) ────────────────────── */}
        {isMobileOpen && (
          <button
            onClick={onCloseMobile}
            aria-label="Close navigation"
            className="md:hidden absolute right-3.5 top-5 p-1.5 rounded-full text-gray-400 hover:text-white hover:bg-white/[0.05] cursor-pointer focus-visible:ring-2 focus-visible:ring-[#B8FF3B]"
          >
            <X className="w-5 h-5 stroke-[2]" />
          </button>
        )}

        {/* ── TOP: BRAND LOGO (Smooth Crossfade Between Full & Icon-Only) ── */}
        <div className="w-full shrink-0">
          <div
            onClick={() => {
              navigate('/dashboard');
              handleNavClick();
            }}
            className={`relative h-10 w-full flex items-center cursor-pointer transition-transform active:scale-95 mb-8 ${
              isWide ? 'px-3.5 justify-start' : 'justify-center'
            }`}
            title="Calora"
          >
            {/* FULL LOGO (Visible when expanded, smooth crossfade + scale/slide, aligned with nav items) */}
            <div
              className={`absolute left-3.5 top-1/2 -translate-y-1/2 h-8 flex items-center transition-all duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] ${
                isWide
                  ? 'opacity-100 scale-100 translate-x-0 pointer-events-auto'
                  : 'opacity-0 scale-95 -translate-x-3 pointer-events-none'
              }`}
            >
              <img
                src={fullLogoImg}
                alt="Calora Logo"
                className="h-7 w-auto object-contain select-none"
                onError={(e) => {
                  (e.target as HTMLImageElement).src = '/full_logo.png';
                }}
              />
            </div>

            {/* ICON-ONLY LOGO (Visible when collapsed, centered, clean direct icon without outline) */}
            <div
              className={`absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-8 h-8 flex items-center justify-center transition-all duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] ${
                !isWide
                  ? 'opacity-100 scale-100 pointer-events-auto'
                  : 'opacity-0 scale-85 pointer-events-none'
              }`}
            >
              <img
                src={iconLogoImg}
                alt="Calora Icon"
                className="w-7 h-7 object-contain select-none"
                onError={(e) => {
                  (e.target as HTMLImageElement).src = '/Icon_logo.png';
                }}
              />
            </div>
          </div>
        </div>

        {/* ── MIDDLE: NAV ITEMS (44px Height, Lime Active Pill, Hover Nudge, Tooltips) ── */}
        <nav
          className={`flex-1 w-full space-y-1.5 py-1 ${
            isWide ? 'overflow-y-auto overflow-x-hidden custom-scrollbar' : 'overflow-visible'
          }`}
          aria-label="Main Navigation"
        >
          {mainNavItems.map((item) => {
            const Icon = item.icon;

            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={handleNavClick}
                className={({ isActive }) =>
                  `relative flex items-center h-11 transition-all duration-200 group cursor-pointer active:scale-[0.98] focus-visible:ring-2 focus-visible:ring-[#B8FF3B] focus-visible:outline-none ${
                    isWide
                      ? `px-3.5 rounded-full space-x-3 text-sm font-medium ${
                          isActive
                            ? 'bg-[#B8FF3B] text-black font-semibold shadow-[0_2px_12px_rgba(184,255,59,0.3)]'
                            : 'text-gray-300 hover:text-white hover:bg-white/[0.05]'
                        }`
                      : `justify-center w-11 mx-auto rounded-full ${
                          isActive
                            ? 'bg-[#B8FF3B] text-black font-semibold shadow-[0_2px_12px_rgba(184,255,59,0.3)]'
                            : 'text-gray-300 hover:text-white hover:bg-white/[0.05]'
                        }`
                  }`
                }
              >
                {({ isActive }) => (
                  <>
                    <Icon
                      strokeWidth={1.8}
                      className={`w-[18px] h-[18px] shrink-0 transition-transform duration-200 group-hover:scale-105 ${
                        isActive
                          ? 'text-black'
                          : 'text-gray-400 group-hover:text-white'
                      }`}
                    />

                    {/* Nav Item Label (Slides and Fades Smoothly) */}
                    {isWide && (
                      <span className="truncate flex-1 tracking-tight text-[14px] transition-all duration-200 whitespace-nowrap overflow-hidden">
                        {item.label}
                      </span>
                    )}

                    {/* Notification Badge in Expanded Mode */}
                    {isWide && item.badge !== null && item.badge !== undefined && (
                      <span
                        className={`text-[10px] font-bold rounded-full px-2 py-0.5 shrink-0 transition-transform duration-200 ${
                          isActive
                            ? 'bg-black text-[#B8FF3B]'
                            : 'bg-[#B8FF3B] text-black shadow-xs'
                        }`}
                      >
                        {item.badge}
                      </span>
                    )}

                    {/* Mini Indicator Dot in Collapsed Mode */}
                    {!isWide && item.badge !== null && item.badge !== undefined && (
                      <span
                        className="absolute top-1.5 right-1.5 w-2.5 h-2.5 rounded-full p-0 pointer-events-none bg-[#B8FF3B] ring-2 ring-[#0B120C] shadow-xs animate-pulse"
                        aria-label={`${item.badge} notifications`}
                      />
                    )}

                    {/* Collapsed Mode Tooltip on Hover/Focus (Positioned to the Right, Never Clipped) */}
                    {!isWide && (
                      <div
                        role="tooltip"
                        className="absolute left-full ml-3 px-3 py-1.5 rounded-xl bg-[#141C16] text-white text-xs font-semibold whitespace-nowrap shadow-xl border border-white/10 opacity-0 -translate-x-1 pointer-events-none group-hover:opacity-100 group-hover:translate-x-0 group-focus-visible:opacity-100 group-focus-visible:translate-x-0 transition-all duration-200 z-50 flex items-center space-x-1.5"
                      >
                        <span>{item.label}</span>
                        {item.badge !== null && item.badge !== undefined && (
                          <span className="px-1.5 py-0.5 rounded-full bg-[#B8FF3B] text-black text-[10px] font-bold">
                            {item.badge}
                          </span>
                        )}
                      </div>
                    )}
                  </>
                )}
              </NavLink>
            );
          })}
        </nav>

        {/* ── BOTTOM: GROUPED FOOTER CONTROLS ────────────────────────── */}
        <div className="w-full pt-4 border-t border-white/[0.06] shrink-0 space-y-3.5">
          {/* Controls in Expanded Mode (Horizontal Row) vs Collapsed Mode (Vertical Stack) */}
          {isWide ? (
            <div className="flex items-center justify-between px-1">
              {/* Language Switcher Pill (EN | ID) */}
              <div className="h-8 rounded-full bg-[#152017] p-1 flex border border-white/[0.06] w-28">
                <button
                  onClick={() => setLanguage('en')}
                  aria-label="Switch to English"
                  className={`flex-1 rounded-full text-[11px] font-semibold transition-all duration-200 cursor-pointer focus-visible:ring-1 focus-visible:ring-[#B8FF3B] ${
                    language === 'en'
                      ? 'bg-[#253628] text-white shadow-xs'
                      : 'text-gray-400 hover:text-gray-200'
                  }`}
                >
                  EN
                </button>
                <button
                  onClick={() => setLanguage('id')}
                  aria-label="Switch to Bahasa Indonesia"
                  className={`flex-1 rounded-full text-[11px] font-semibold transition-all duration-200 cursor-pointer focus-visible:ring-1 focus-visible:ring-[#B8FF3B] ${
                    language === 'id'
                      ? 'bg-[#253628] text-white shadow-xs'
                      : 'text-gray-400 hover:text-gray-200'
                  }`}
                >
                  ID
                </button>
              </div>

              {/* Theme Toggle Button */}
              <button
                onClick={toggleTheme}
                title={isDark ? t('switchToLight') : t('switchToDark')}
                aria-label={isDark ? t('switchToLight') : t('switchToDark')}
                className="w-8 h-8 rounded-full bg-[#152017] border border-white/[0.06] flex items-center justify-center text-gray-400 hover:text-white transition-colors cursor-pointer shrink-0 focus-visible:ring-2 focus-visible:ring-[#B8FF3B] active:scale-95"
              >
                {isDark ? (
                  <SunMedium className="w-3.5 h-3.5 text-[#B8FF3B]" strokeWidth={1.8} />
                ) : (
                  <Moon className="w-3.5 h-3.5" strokeWidth={1.8} />
                )}
              </button>
            </div>
          ) : (
            <div className="flex flex-col items-center gap-2 relative">
              {/* Collapsed Language Toggle Button */}
              <button
                onClick={() => setLanguage(language === 'en' ? 'id' : 'en')}
                title={`Language: ${language.toUpperCase()} (Click to toggle)`}
                aria-label={`Language: ${language.toUpperCase()}`}
                className="w-8 h-8 rounded-full bg-[#152017] border border-white/[0.06] flex items-center justify-center text-gray-300 hover:text-[#B8FF3B] hover:border-[#B8FF3B]/40 text-[10px] font-bold uppercase transition-colors cursor-pointer group focus-visible:ring-2 focus-visible:ring-[#B8FF3B] active:scale-95"
              >
                <span>{language}</span>
                <div
                  role="tooltip"
                  className="absolute left-full ml-3 px-2.5 py-1 rounded-lg bg-[#141C16] text-white text-xs font-semibold whitespace-nowrap shadow-xl border border-white/10 opacity-0 -translate-x-1 pointer-events-none group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-200 z-50"
                >
                  {language === 'en' ? 'Switch to Bahasa Indonesia' : 'Switch to English'}
                </div>
              </button>

              {/* Collapsed Theme Toggle Button */}
              <button
                onClick={toggleTheme}
                title={isDark ? t('switchToLight') : t('switchToDark')}
                aria-label={isDark ? t('switchToLight') : t('switchToDark')}
                className="w-8 h-8 rounded-full bg-[#152017] border border-white/[0.06] flex items-center justify-center text-gray-400 hover:text-white hover:border-[#B8FF3B]/40 transition-colors cursor-pointer group focus-visible:ring-2 focus-visible:ring-[#B8FF3B] active:scale-95"
              >
                {isDark ? (
                  <SunMedium className="w-3.5 h-3.5 text-[#B8FF3B]" strokeWidth={1.8} />
                ) : (
                  <Moon className="w-3.5 h-3.5" strokeWidth={1.8} />
                )}
                <div
                  role="tooltip"
                  className="absolute left-full ml-3 px-2.5 py-1 rounded-lg bg-[#141C16] text-white text-xs font-semibold whitespace-nowrap shadow-xl border border-white/10 opacity-0 -translate-x-1 pointer-events-none group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-200 z-50"
                >
                  {isDark ? t('switchToLight') : t('switchToDark')}
                </div>
              </button>
            </div>
          )}

          {/* User Profile Block & Logout Action */}
          <div
            className={`flex ${
              isWide ? 'items-center justify-between gap-2' : 'flex-col items-center gap-2 w-full'
            }`}
          >
            {/* User Info Clickable Pill */}
            <div
              onClick={() => {
                navigate('/settings');
                handleNavClick();
              }}
              aria-label="User Settings"
              className={`flex items-center cursor-pointer p-1 rounded-full hover:bg-white/[0.04] transition-colors group relative ${
                isWide ? 'flex-1 space-x-2.5 overflow-hidden' : 'w-full justify-center'
              }`}
              title={user?.name || 'Calora Admin'}
            >
              <div className="w-8 h-8 rounded-full bg-[#182B1D] border border-[#2D4A33] text-[#B8FF3B] font-bold flex items-center justify-center text-xs shrink-0 shadow-xs group-hover:border-[#B8FF3B]/50 transition-colors">
                {user?.name?.[0]?.toUpperCase() || 'C'}
              </div>

              {isWide && (
                <div className="overflow-hidden flex-1">
                  <h4 className="text-xs font-semibold text-white truncate leading-tight group-hover:text-[#B8FF3B] transition-colors">
                    {user?.name || 'Calora Admin'}
                  </h4>
                  <p className="text-[10px] text-gray-400 truncate mt-0.5">
                    {user?.email || 'admin@calora.app'}
                  </p>
                </div>
              )}

              {/* Tooltip in Collapsed Mode */}
              {!isWide && (
                <div
                  role="tooltip"
                  className="absolute left-full ml-3 px-3 py-1.5 rounded-xl bg-[#141C16] text-white text-xs font-semibold whitespace-nowrap shadow-xl border border-white/10 opacity-0 -translate-x-1 pointer-events-none group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-200 z-50"
                >
                  {user?.name || 'Calora Admin'} ({user?.email || 'admin@calora.app'})
                </div>
              )}
            </div>

            {/* Logout Action Button */}
            <button
              onClick={async (e) => {
                e.stopPropagation();
                await logout();
              }}
              title={t('logout')}
              aria-label={t('logout')}
              className={`h-8 rounded-full flex items-center justify-center text-gray-400 hover:text-rose-400 hover:bg-rose-500/10 transition-all cursor-pointer shrink-0 group relative focus-visible:ring-2 focus-visible:ring-rose-500 active:scale-95 ${
                isWide ? 'px-2.5 space-x-1 text-xs' : 'w-8 h-8 mx-auto'
              }`}
            >
              <LogOut className="w-3.5 h-3.5 stroke-[1.8]" />
              {isWide && (
                <span className="text-[11px] font-medium">{t('logout')}</span>
              )}

              {/* Tooltip in Collapsed Mode */}
              {!isWide && (
                <div
                  role="tooltip"
                  className="absolute left-full ml-3 px-2.5 py-1 rounded-lg bg-[#141C16] text-rose-300 text-xs font-semibold whitespace-nowrap shadow-xl border border-white/10 opacity-0 -translate-x-1 pointer-events-none group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-200 z-50"
                >
                  {t('logout')}
                </div>
              )}
            </button>
          </div>
        </div>
      </aside>
    </>
  );
};
