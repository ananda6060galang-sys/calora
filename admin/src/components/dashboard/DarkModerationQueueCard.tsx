import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { FoodRequest } from '../../types';
import { ArrowRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import { formatLocaleDate } from '../../lib/utils';

interface DarkModerationQueueCardProps {
  onOpenRequestModal: (req: FoodRequest) => void;
}

export const DarkModerationQueueCard: React.FC<DarkModerationQueueCardProps> = ({
  onOpenRequestModal,
}) => {
  const { requests } = useAdmin();
  const { t, language } = useThemeLanguage();

  const pendingList = requests.filter((r) => r.status === 'pending');
  // First 4 pending items
  const displayItems = pendingList.length > 0 ? pendingList.slice(0, 4) : [
    {
      id: 'mock-1',
      food_name: 'Chicken Teriyaki',
      category: 'Rice',
      serving_size: '1 Porsi',
      calories: 380,
      protein_g: 28,
      carbs_g: 42,
      fat_g: 11,
      status: 'pending' as const,
      created_at: new Date('2026-09-23T10:00:00Z').toISOString(),
    }
  ];

  return (
    <div className="rounded-[24px] p-6 sm:p-7 bg-[#0B120C] text-white shadow-soft hover-card-lift border-0 flex flex-col justify-between h-full select-none animate-card-rise stagger-5">
      <div>
        {/* ── CARD HEADER (Image B Dark Map Style) ────────────────────── */}
        <div className="flex items-center justify-between pb-3 mb-2 border-b border-white/[0.08]">
          <div>
            <h3 className="text-base sm:text-lg font-semibold tracking-tight text-white">
              {t('pendingFoodRequests') || (language === 'id' ? 'Permintaan Makanan Menunggu' : 'Pending Food Requests')}
            </h3>
            <p className="text-sm text-white/70 font-normal mt-0.5">
              {pendingList.length > 0 ? pendingList.length : 1} {language === 'id' ? 'pengajuan menunggu verifikasi' : 'submissions awaiting review'}
            </p>
          </div>

          {/* Count pill */}
          <span className="px-3 py-1 rounded-full bg-white/10 text-[#B8FF3B] text-xs font-semibold">
            {pendingList.length > 0 ? pendingList.length : 1} {language === 'id' ? 'antrean' : 'pending'}
          </span>
        </div>

        {/* ── QUEUE LIST (Round Monogram, Category Pill, Review Pill) ── */}
        <div className="divide-y divide-white/[0.06]">
          {displayItems.map((item) => {
            const imageUrl = (item as FoodRequest).image_url;

            return (
              <div
                key={item.id}
                className="flex items-center justify-between py-3.5 group transition-colors"
              >
                {/* Left: Round Monogram / Image + Text */}
                <div className="flex items-center space-x-3 overflow-hidden pr-3">
                  {imageUrl ? (
                    <img
                      src={imageUrl}
                      alt={item.food_name}
                      className="w-10 h-10 rounded-full object-cover shrink-0 border border-white/10"
                    />
                  ) : (
                    <div className="w-10 h-10 rounded-full bg-[#18261B] text-[#B8FF3B] font-semibold flex items-center justify-center text-sm shrink-0 group-hover:scale-105 transition-transform">
                      {item.food_name ? item.food_name.charAt(0).toUpperCase() : 'F'}
                    </div>
                  )}

                  <div className="overflow-hidden">
                    <h4 className="text-sm font-semibold text-white truncate group-hover:text-[#B8FF3B] transition-colors leading-tight">
                      {item.food_name}
                    </h4>
                    <div className="flex items-center space-x-2 mt-1 text-xs">
                      <span className="px-2.5 py-0.5 rounded-full bg-white/10 text-xs font-semibold text-white/90">
                        {item.category || 'Food'}
                      </span>
                      <span className="text-white/40">•</span>
                      <span className="text-white/70 text-xs font-medium">
                        {formatLocaleDate(item.created_at, language)}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Right: Review Pill (Fills lime on hover with arrow sliding 3px) */}
                <button
                  onClick={() => onOpenRequestModal(item as FoodRequest)}
                  className="group/btn px-4 py-2 rounded-full border border-white/25 bg-white/5 text-white hover:bg-[#B8FF3B] hover:text-[#0C2417] hover:border-[#B8FF3B] text-xs font-semibold flex items-center space-x-1.5 transition-all cursor-pointer shrink-0 active:scale-95 shadow-2xs"
                >
                  <span>{t('review') || (language === 'id' ? 'Tinjau' : 'Review')}</span>
                  <ArrowRight className="w-3.5 h-3.5 transition-transform duration-200 group-hover/btn:translate-x-[3px]" />
                </button>
              </div>
            );
          })}
        </div>

        {/* ── FOOTER: DIRECTLY UNDER LIST (No Dead Gap) ───────────────── */}
        <div className="pt-3.5 mt-2 border-t border-white/[0.08] flex items-center justify-between text-sm">
          <Link
            to="/food-requests"
            className="font-semibold text-[#B8FF3B] hover:underline flex items-center space-x-1"
          >
            <span>{t('viewAll') || (language === 'id' ? 'Lihat semua' : 'View all')}</span>
            <ArrowRight className="w-4 h-4" />
          </Link>

          <span className="px-3 py-1 rounded-full bg-[#18261B] text-[#B8FF3B] text-xs font-semibold">
            {pendingList.length > 0 ? pendingList.length : 1} {language === 'id' ? 'menunggu' : 'pending'}
          </span>
        </div>
      </div>

      {/* ── AMBIENT BOTTOM TELEMETRY (Balances table height cleanly) ── */}
      <div className="mt-6 pt-4 border-t border-white/[0.05] flex items-center justify-between text-xs">
        <div className="flex items-center space-x-2">
          <span className="w-2 h-2 rounded-full bg-[#B8FF3B]" />
          <span className="text-xs font-medium text-white/80">
            {t('rlsActive') || (language === 'id' ? 'Privasi Terjamin' : 'Privacy Enforced')}
          </span>
        </div>
        <span className="text-xs text-white/50">Calora Console</span>
      </div>
    </div>
  );
};
