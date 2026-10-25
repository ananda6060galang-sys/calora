import React from 'react';
import {
  RiUserAddFill,
  RiRestaurantFill,
  RiCheckboxCircleFill,
  RiSparklingFill,
  RiAwardFill,
  RiShieldCheckFill,
  RiArrowRightLine,
} from 'react-icons/ri';
import { Link } from 'react-router-dom';

export const DashboardRightPanel: React.FC = () => {

  const moderationEvents = [
    {
      id: 'e1',
      icon: RiRestaurantFill,
      iconColor: 'text-[#FF6B57]',
      bg: 'bg-[#FF6B57]/15',
      title: 'Darrell submitted Sate Ayam Madura',
      desc: '48g Protein • 520 kcal • Awaiting review',
      time: '5m ago',
    },
    {
      id: 'e2',
      icon: RiSparklingFill,
      iconColor: 'text-[#16A34A] dark:text-[#3DDC84]',
      bg: 'bg-emerald-500/15',
      title: 'AI Scanner verified Nasi Padang',
      desc: 'Gemini 2.5 Flash • 98.4% confidence score',
      time: '18m ago',
    },
    {
      id: 'e3',
      icon: RiCheckboxCircleFill,
      iconColor: 'text-[#16A34A] dark:text-[#B8FF3B]',
      bg: 'bg-[#B8FF3B]/20',
      title: 'Galang verified Ayam Bakar Taliwang',
      desc: 'Published to public Indonesian foods catalog',
      time: '42m ago',
    },
    {
      id: 'e4',
      icon: RiUserAddFill,
      iconColor: 'text-[#8B7CFF]',
      bg: 'bg-[#8B7CFF]/15',
      title: '14 New mobile users registered',
      desc: 'Onboarding completed with BMR & targets',
      time: '2h ago',
    },
  ];

  const topContributors = [
    {
      id: 'u1',
      name: 'Darrell Steward',
      role: 'Gold Contributor',
      avatar: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=80&auto=format&fit=crop&q=80',
      submissions: 14,
      badge: '🥇',
      badgeColor: 'text-amber-500',
    },
    {
      id: 'u2',
      name: 'Courtney Henry',
      role: 'Silver Contributor',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&auto=format&fit=crop&q=80',
      submissions: 9,
      badge: '🥈',
      badgeColor: 'text-gray-400',
    },
    {
      id: 'u3',
      name: 'Bella Deviant',
      role: 'Bronze Contributor',
      avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&auto=format&fit=crop&q=80',
      submissions: 7,
      badge: '🥉',
      badgeColor: 'text-amber-700',
    },
    {
      id: 'u4',
      name: 'Wade Warren',
      role: 'Active Logger',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80&auto=format&fit=crop&q=80',
      submissions: 5,
      badge: '✦',
      badgeColor: 'text-[#8B7CFF]',
    },
  ];

  return (
    <aside className="w-full xl:w-[320px] shrink-0 space-y-5">
      {/* ── SECTION 1: LIVE MODERATION STREAM ───────────────────────── */}
      <div className="bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs transition-colors">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
            Live Moderation Feed
          </h3>
          <span className="w-2 h-2 rounded-full bg-[#16A34A] dark:bg-[#B8FF3B] animate-pulse" />
        </div>

        <div className="space-y-3.5">
          {moderationEvents.map((evt) => {
            const Icon = evt.icon;
            return (
              <div key={evt.id} className="flex items-start space-x-3 group">
                <div
                  className={`w-8 h-8 rounded-xl ${evt.bg} ${evt.iconColor} flex items-center justify-center shrink-0 mt-0.5`}
                >
                  <Icon className="w-4 h-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-bold text-[#111111] dark:text-[#F3F5EF] leading-snug group-hover:text-[#16A34A] dark:group-hover:text-[#B8FF3B] transition-colors">
                    {evt.title}
                  </p>
                  <p className="text-[10px] text-gray-400 truncate mt-0.5">
                    {evt.desc}
                  </p>
                  <span className="text-[9px] text-gray-400 font-semibold block mt-1">
                    {evt.time}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* ── SECTION 2: TOP COMMUNITY FOOD CONTRIBUTORS ──────────────── */}
      <div className="bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs transition-colors">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center space-x-1.5">
            <RiAwardFill className="w-4 h-4 text-amber-500" />
            <h3 className="text-sm font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
              Top Contributors
            </h3>
          </div>
          <Link
            to="/users"
            className="text-[11px] font-bold text-[#16A34A] dark:text-[#B8FF3B] hover:underline"
          >
            Directory
          </Link>
        </div>

        <div className="space-y-2.5">
          {topContributors.map((c) => (
            <div
              key={c.id}
              className="flex items-center justify-between p-2.5 rounded-xl bg-gray-50/70 dark:bg-[#202820] border border-gray-100 dark:border-[#283528] hover:border-gray-200 dark:hover:border-gray-600 transition-all"
            >
              <div className="flex items-center space-x-2.5 min-w-0">
                <div className="relative w-8 h-8 rounded-full overflow-hidden shrink-0 border border-gray-200 dark:border-gray-700">
                  <img
                    src={c.avatar}
                    alt={c.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="truncate">
                  <div className="flex items-center space-x-1.5">
                    <p className="text-xs font-bold text-[#111111] dark:text-[#F3F5EF] truncate">
                      {c.name}
                    </p>
                    <span className="text-xs">{c.badge}</span>
                  </div>
                  <p className="text-[10px] text-gray-400 truncate">{c.role}</p>
                </div>
              </div>

              <div className="text-right shrink-0 pl-2">
                <span className="text-xs font-black text-[#111111] dark:text-[#F3F5EF]">
                  {c.submissions}
                </span>
                <span className="text-[10px] text-gray-400 block -mt-0.5">
                  dishes
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ── SECTION 3: SYSTEM SECURITY & AI SCANNER HEALTH ───────────── */}
      <div className="bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs transition-colors">
        <div className="flex items-center space-x-2 mb-3">
          <RiShieldCheckFill className="w-4 h-4 text-[#16A34A] dark:text-[#3DDC84]" />
          <h3 className="text-xs font-extrabold text-[#111111] dark:text-[#F3F5EF] uppercase tracking-wider">
            System &amp; RLS Status
          </h3>
        </div>

        <div className="space-y-2.5 text-xs">
          <div className="flex items-center justify-between text-gray-500 dark:text-gray-400">
            <span>Supabase Postgres</span>
            <span className="font-bold text-[#16A34A] dark:text-[#3DDC84] flex items-center space-x-1">
              <span className="w-1.5 h-1.5 rounded-full bg-[#16A34A] dark:bg-[#3DDC84]" />
              <span>RLS Active</span>
            </span>
          </div>

          <div className="flex items-center justify-between text-gray-500 dark:text-gray-400">
            <span>Gemini 2.5 Flash</span>
            <span className="font-bold text-[#16A34A] dark:text-[#3DDC84] flex items-center space-x-1">
              <span className="w-1.5 h-1.5 rounded-full bg-[#16A34A] dark:bg-[#3DDC84]" />
              <span>Online (22ms)</span>
            </span>
          </div>

          <div className="flex items-center justify-between text-gray-500 dark:text-gray-400">
            <span>Moderation SLA</span>
            <span className="font-bold text-[#111111] dark:text-[#F3F5EF]">
              100% (&lt; 24h)
            </span>
          </div>
        </div>

        <div className="mt-4 pt-3 border-t border-gray-100 dark:border-[#222D23]">
          <Link
            to="/settings"
            className="w-full py-2 px-3 rounded-xl bg-gray-100 dark:bg-[#202820] hover:bg-gray-200 dark:hover:bg-[#283528] text-gray-700 dark:text-gray-300 text-xs font-bold flex items-center justify-center space-x-1.5 transition-colors"
          >
            <span>Configure System</span>
            <RiArrowRightLine className="w-3.5 h-3.5" />
          </Link>
        </div>
      </div>
    </aside>
  );
};
