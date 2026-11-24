import React, { useState } from 'react';
import { useAdmin } from '../context/AdminContext';
import { useThemeLanguage } from '../context/ThemeLanguageContext';
import { AdminHeader } from '../components/layout/AdminHeader';
import { supabase } from '../lib/supabase';
import {
  ShieldCheck,
  Database,
  CheckCircle2,
  RotateCw,
  LogOut,
} from 'lucide-react';

export const Settings: React.FC = () => {
  const { user, logout } = useAdmin();
  const { t } = useThemeLanguage();
  const [isTesting, setIsTesting] = useState(false);
  const [dbStatus, setDbStatus] = useState<string | null>(null);

  const testSupabaseConnection = async () => {
    setIsTesting(true);
    setDbStatus(null);
    try {
      const { error } = await supabase.from('food_categories').select('count');
      if (error) {
        setDbStatus(`Supabase responded with: ${error.message}`);
      } else {
        setDbStatus('Successfully connected to Supabase PostgreSQL cluster.');
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Connection failed';
      setDbStatus(`Connection check: ${message}`);
    } finally {
      setIsTesting(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl animate-fade-in font-sans pb-12">
      {/* Header */}
      <AdminHeader
        title={t('systemSettings')}
        subtitle="Manage administrator profile and Supabase PostgreSQL backend integration"
        showSearch={false}
      />

      {/* Admin Profile Card */}
      <div className="p-6 bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] border border-[#EAEFE8] dark:border-[#212E23] shadow-xs space-y-4 transition-colors duration-200">
        <div className="flex items-center space-x-3">
          <div className="relative w-12 h-12 rounded-full bg-[#0B2114] flex items-center justify-center text-[#B8FF3B] overflow-hidden shrink-0 ring-1 ring-[#1E3B2A]">
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
            <ShieldCheck className="w-6 h-6 stroke-[1.8]" />
          </div>
          <div>
            <h3 className="text-base font-bold text-[#111111] dark:text-[#F3F5EF]">
              Active Administrator Profile
            </h3>
            <p className="text-sm text-stone-500 dark:text-stone-400 mt-0.5">
              Role permissions verified by PostgreSQL Row Level Security (RLS)
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-3 border-t border-[#F2F5F0] dark:border-[#202C22] text-sm">
          <div>
            <span className="text-xs font-semibold text-stone-500 dark:text-stone-400 uppercase tracking-wide block">Account Name</span>
            <span className="font-bold text-[#111111] dark:text-[#F3F5EF] text-base mt-0.5 block">
              {user?.name || 'Administrator'}
            </span>
          </div>
          <div>
            <span className="text-xs font-semibold text-stone-500 dark:text-stone-400 uppercase tracking-wide block">Email Address</span>
            <span className="font-bold text-[#111111] dark:text-[#F3F5EF] text-base mt-0.5 block">
              {user?.email || 'admin@calora.app'}
            </span>
          </div>
          <div>
            <span className="text-xs font-semibold text-stone-500 dark:text-stone-400 uppercase tracking-wide block">Console Role</span>
            <span className="inline-flex items-center px-3 py-1 mt-1 rounded-full text-xs font-bold bg-[#B8FF3B] text-[#0C2417]">
              Super Admin
            </span>
          </div>
          <div>
            <span className="text-xs font-semibold text-stone-500 dark:text-stone-400 uppercase tracking-wide block">Security Status</span>
            <span className="inline-flex items-center text-emerald-700 dark:text-emerald-400 font-semibold space-x-1.5 mt-1 text-sm">
              <CheckCircle2 className="w-4 h-4 stroke-[2]" />
              <span>Full CRUD Access</span>
            </span>
          </div>
        </div>

        <div className="pt-3 border-t border-[#F2F5F0] dark:border-[#202C22] flex justify-end">
          <button
            onClick={() => logout()}
            className="px-4.5 py-2.5 rounded-full text-sm font-semibold border border-rose-200 dark:border-rose-900/60 text-rose-600 dark:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/30 flex items-center space-x-1.5 transition-colors cursor-pointer"
          >
            <LogOut className="w-4 h-4 stroke-[1.8]" />
            <span>{t('logout')}</span>
          </button>
        </div>
      </div>

      {/* Backend Integration Diagnostics */}
      <div className="p-6 bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] border border-[#EAEFE8] dark:border-[#212E23] shadow-xs space-y-4 transition-colors duration-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-full bg-emerald-50 dark:bg-[#14331C] text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <Database className="w-5 h-5 stroke-[1.8]" />
            </div>
            <div>
              <h3 className="text-base font-bold text-[#111111] dark:text-[#F3F5EF]">
                Supabase PostgreSQL Backend
              </h3>
              <p className="text-sm text-stone-500 dark:text-stone-400 mt-0.5">
                Connected project: nutrition, workouts, profiles, and moderation queues
              </p>
            </div>
          </div>

          <button
            onClick={testSupabaseConnection}
            disabled={isTesting}
            className="px-4.5 py-2.5 rounded-full text-sm font-semibold border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-[#1E2A20] text-stone-700 dark:text-stone-200 flex items-center space-x-1.5 transition-colors cursor-pointer shadow-2xs"
          >
            <RotateCw className={`w-4 h-4 stroke-[1.8] ${isTesting ? 'animate-spin text-[#16A34A] dark:text-[#B8FF3B]' : ''}`} />
            <span>{isTesting ? 'Testing...' : 'Test Connection'}</span>
          </button>
        </div>

        {dbStatus && (
          <div
            className={`p-3 rounded-xl text-xs font-medium border ${
              dbStatus.includes('Successfully')
                ? 'bg-emerald-50 dark:bg-[#14331C]/60 text-emerald-800 dark:text-emerald-300 border-emerald-200 dark:border-[#234B2D]'
                : 'bg-amber-50 dark:bg-amber-950/40 text-amber-800 dark:text-amber-300 border-amber-200 dark:border-amber-800'
            }`}
          >
            {dbStatus}
          </div>
        )}
      </div>
    </div>
  );
};
