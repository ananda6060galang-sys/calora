import React, { useMemo } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';

export const MacroDistributionChart: React.FC = () => {
  const { foods, categories } = useAdmin();
  const { t } = useThemeLanguage();

  // Compute average protein, carbs, and fat per category from real foods
  const data = useMemo(() => {
    if (categories.length === 0) return [];

    return categories.map((cat) => {
      const catFoods = foods.filter(
        (f) => f.category === cat.name || f.category_id === cat.id
      );

      if (catFoods.length === 0) {
        return {
          name: cat.name,
          protein: 0,
          carbs: 0,
          fat: 0,
        };
      }

      const totalProtein = catFoods.reduce((sum, f) => sum + (f.protein_g || 0), 0);
      const totalCarbs = catFoods.reduce((sum, f) => sum + (f.carbs_g || 0), 0);
      const totalFat = catFoods.reduce((sum, f) => sum + (f.fat_g || 0), 0);

      return {
        name: cat.name,
        protein: Math.round((totalProtein / catFoods.length) * 10) / 10,
        carbs: Math.round((totalCarbs / catFoods.length) * 10) / 10,
        fat: Math.round((totalFat / catFoods.length) * 10) / 10,
      };
    });
  }, [foods, categories]);

  return (
    <div className="p-6 bg-white dark:bg-calora-dark-surface rounded-2xl border border-gray-100 dark:border-calora-dark-border shadow-xs">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center space-x-2">
            <h3 className="text-base font-extrabold text-calora-light-text dark:text-calora-dark-text tracking-tight">
              {t('macroDistributionTitle')}
            </h3>
          </div>
          <p className="text-xs text-gray-500 dark:text-calora-dark-muted mt-0.5">
            {t('macroDistributionSubtitle')}
          </p>
        </div>

        <div className="flex items-center space-x-4">
          {/* Legend */}
          <div className="flex items-center space-x-3 text-xs">
            <div className="flex items-center space-x-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-calora-protein" />
              <span className="text-gray-500 font-medium">{t('protein')}</span>
            </div>
            <div className="flex items-center space-x-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-calora-carbs" />
              <span className="text-gray-500 font-medium">{t('carbs')}</span>
            </div>
            <div className="flex items-center space-x-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-calora-fat" />
              <span className="text-gray-500 font-medium">{t('fat')}</span>
            </div>
          </div>
        </div>
      </div>

      <div className="h-64 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 0 }} barGap={3}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" opacity={0.5} />
            <XAxis dataKey="name" stroke="#9CA3AF" fontSize={10} tickLine={false} axisLine={false} />
            <YAxis stroke="#9CA3AF" fontSize={11} tickLine={false} axisLine={false} />
            <Tooltip
              formatter={(val: number) => [`${val}g`]}
              contentStyle={{
                backgroundColor: '#181E19',
                borderColor: '#303830',
                borderRadius: '12px',
                color: '#F3F5EF',
                fontSize: '12px',
              }}
              itemStyle={{ color: '#F3F5EF' }}
            />
            <Bar dataKey="protein" fill="#FF6B57" radius={[4, 4, 0, 0]} maxBarSize={14} />
            <Bar dataKey="carbs" fill="#FFC24B" radius={[4, 4, 0, 0]} maxBarSize={14} />
            <Bar dataKey="fat" fill="#7C9CFF" radius={[4, 4, 0, 0]} maxBarSize={14} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};
