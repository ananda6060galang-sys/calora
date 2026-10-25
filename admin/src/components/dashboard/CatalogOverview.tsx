import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { Link } from 'react-router-dom';
import {
  PiFolderSimpleFill,
  PiForkKnifeFill,
  PiPlusBold,
} from 'react-icons/pi';

interface CatalogOverviewProps {
  onOpenFoodModal?: () => void;
}

export const CatalogOverview: React.FC<CatalogOverviewProps> = ({
  onOpenFoodModal,
}) => {
  const { foods, categories } = useAdmin();
  const { t } = useThemeLanguage();

  const totalFoods = foods.length;

  // Compute food count per category from actual data
  const categoryStats = categories.slice(0, 5).map((cat) => {
    const count = foods.filter(
      (f) => f.category === cat.name || f.category_id === cat.id
    ).length;
    const percentage = totalFoods > 0 ? Math.round((count / totalFoods) * 100) : 0;
    return {
      ...cat,
      count,
      percentage,
    };
  });

  // Recent 4 foods
  const recentFoods = foods.slice(0, 4);

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
      {/* ── LEFT: CATEGORY DISTRIBUTION (6 cols) ────────────────────── */}
      <div className="lg:col-span-6 bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center space-x-2">
            <PiFolderSimpleFill className="w-4 h-4 text-[#16A34A] dark:text-[#3DDC84]" />
            <h3 className="text-sm font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
              {t('foodTaxonomy')}
            </h3>
          </div>
          <Link
            to="/categories"
            className="text-xs font-bold text-[#16A34A] dark:text-[#B8FF3B] hover:underline"
          >
            Manage
          </Link>
        </div>

        <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">
          Distribution of {totalFoods} verified items across core food categories
        </p>

        <div className="space-y-3.5">
          {categoryStats.map((cat) => (
            <div key={cat.id} className="space-y-1.5">
              <div className="flex items-center justify-between text-xs">
                <span className="font-semibold text-[#111111] dark:text-[#F3F5EF]">
                  {cat.name}
                </span>
                <span className="text-gray-500 dark:text-gray-400 text-[11px]">
                  {cat.count} items ({cat.percentage}%)
                </span>
              </div>
              <div className="w-full h-2 rounded-full bg-gray-100 dark:bg-[#202820] overflow-hidden">
                <div
                  className="h-full rounded-full bg-[#16A34A] dark:bg-[#B8FF3B] transition-all duration-300"
                  style={{ width: `${Math.max(5, cat.percentage)}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ── RIGHT: RECENT VERIFIED FOODS (6 cols) ───────────────────── */}
      <div className="lg:col-span-6 bg-white dark:bg-[#181E19] rounded-2xl p-5 border border-[#EAECE8] dark:border-[#263226] shadow-xs flex flex-col justify-between">
        <div>
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-2">
              <PiForkKnifeFill className="w-4 h-4 text-[#16A34A] dark:text-[#3DDC84]" />
              <h3 className="text-sm font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
                Recently Verified Foods
              </h3>
            </div>
            <Link
              to="/foods"
              className="text-xs font-bold text-[#16A34A] dark:text-[#B8FF3B] hover:underline"
            >
              Catalog
            </Link>
          </div>

          <div className="space-y-2.5">
            {recentFoods.map((food) => (
              <div
                key={food.id}
                className="flex items-center justify-between p-2.5 rounded-xl bg-gray-50/70 dark:bg-[#202820] border border-gray-100 dark:border-[#283528]"
              >
                <div className="min-w-0 pr-3">
                  <p className="text-xs font-bold text-[#111111] dark:text-[#F3F5EF] truncate">
                    {food.name}
                  </p>
                  <p className="text-[10px] text-gray-500 dark:text-gray-400 mt-0.5">
                    {food.serving_label} • {food.category || 'General'}
                  </p>
                </div>

                <div className="text-right shrink-0">
                  <span className="text-xs font-black text-[#111111] dark:text-[#F3F5EF]">
                    {food.calories} kcal
                  </span>
                  <div className="text-[10px] text-gray-400 mt-0.5 space-x-1 font-medium">
                    <span className="text-[#FF6B57]">{food.protein_g}g P</span>
                    <span>•</span>
                    <span className="text-[#FFC24B]">{food.carbs_g}g C</span>
                    <span>•</span>
                    <span className="text-[#7C9CFF]">{food.fat_g}g F</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {onOpenFoodModal && (
          <div className="mt-4 pt-3 border-t border-gray-100 dark:border-[#222D23]">
            <button
              onClick={onOpenFoodModal}
              className="w-full py-2 px-3 rounded-xl bg-gray-100 hover:bg-gray-200 dark:bg-[#202820] dark:hover:bg-[#283528] text-gray-700 dark:text-gray-300 text-xs font-bold flex items-center justify-center space-x-1.5 transition-colors cursor-pointer"
            >
              <PiPlusBold className="w-3.5 h-3.5" />
              <span>{t('addVerifiedFood')}</span>
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
