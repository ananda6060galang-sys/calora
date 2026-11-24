import React, { useState, useEffect } from 'react';
import { Food } from '../../types';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { X, Plus, Utensils } from 'lucide-react';

interface FoodFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  foodToEdit?: Food | null;
}

export const FoodFormModal: React.FC<FoodFormModalProps> = ({
  isOpen,
  onClose,
  foodToEdit,
}) => {
  const { categories, addFood, updateFood } = useAdmin();
  const { t } = useThemeLanguage();

  const [name, setName] = useState('');
  const [category, setCategory] = useState('Lauk Protein');
  const [servingLabel, setServingLabel] = useState('1 porsi (100g)');
  const [calories, setCalories] = useState('150');
  const [protein, setProtein] = useState('10');
  const [carbs, setCarbs] = useState('15');
  const [fat, setFat] = useState('5');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (foodToEdit) {
      setName(foodToEdit.name);
      setCategory(foodToEdit.category || 'Lauk Protein');
      setServingLabel(foodToEdit.serving_label);
      setCalories(foodToEdit.calories.toString());
      setProtein(foodToEdit.protein_g.toString());
      setCarbs(foodToEdit.carbs_g.toString());
      setFat(foodToEdit.fat_g.toString());
    } else {
      setName('');
      setCategory(categories[0]?.name || 'Lauk Protein');
      setServingLabel('1 porsi (100g)');
      setCalories('150');
      setProtein('10');
      setCarbs('15');
      setFat('5');
    }
  }, [foodToEdit, isOpen, categories]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    setIsSubmitting(true);
    const catObj = categories.find((c) => c.name === category);

    const foodData = {
      name: name.trim(),
      category,
      category_id: catObj?.id,
      serving_label: servingLabel.trim(),
      calories: parseInt(calories, 10) || 0,
      protein_g: parseFloat(protein) || 0,
      carbs_g: parseFloat(carbs) || 0,
      fat_g: parseFloat(fat) || 0,
      portion_grams: 100,
      source: 'admin_manual',
    };

    if (foodToEdit) {
      await updateFood(foodToEdit.id, foodData);
    } else {
      await addFood(foodData);
    }

    setIsSubmitting(false);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-150">
      <div className="bg-white dark:bg-[#181E19] w-full max-w-lg rounded-2xl shadow-2xl border border-[#EAECE8] dark:border-[#263226] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#F2F4F0] dark:border-[#222D23]">
          <div className="flex items-center space-x-3">
            <Utensils className="w-5 h-5 text-[#16A34A] dark:text-[#3DDC84] stroke-[1.8]" />
            <div>
              <h3 className="text-base font-bold text-[#111111] dark:text-[#F3F5EF]">
                {foodToEdit ? t('editFoodModalTitle') : t('addFoodModalTitle')}
              </h3>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                {t('publishDirectlySubtitle')}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-5 h-5 stroke-[1.8]" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit}>
          <div className="p-6 space-y-4.5 max-h-[75vh] overflow-y-auto">
            <div>
              <label className="text-sm font-semibold text-stone-900 dark:text-white mb-1.5 block">
                {t('foodNameField')} *
              </label>
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. Ayam Bakar Madu"
                className="w-full text-sm px-4 py-2.5 rounded-xl border border-gray-200 dark:border-[#303830] bg-gray-50/50 dark:bg-[#202820] text-stone-900 dark:text-white placeholder-stone-400 focus:outline-none focus:ring-2 focus:ring-[#B8FF3B]/50"
              />
            </div>

            <div className="grid grid-cols-2 gap-3.5">
              <div>
                <label className="text-sm font-semibold text-stone-900 dark:text-white mb-1.5 block">
                  {t('categoryField')}
                </label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full text-sm px-3.5 py-2.5 rounded-xl border border-gray-200 dark:border-[#303830] bg-gray-50/50 dark:bg-[#202820] text-stone-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B8FF3B]/50 cursor-pointer"
                >
                  {categories.map((c) => (
                    <option key={c.id} value={c.name}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-sm font-semibold text-stone-900 dark:text-white mb-1.5 block">
                  {t('servingLabelField')} *
                </label>
                <input
                  type="text"
                  required
                  value={servingLabel}
                  onChange={(e) => setServingLabel(e.target.value)}
                  placeholder="e.g. 1 porsi (150g)"
                  className="w-full text-sm px-4 py-2.5 rounded-xl border border-gray-200 dark:border-[#303830] bg-gray-50/50 dark:bg-[#202820] text-stone-900 dark:text-white placeholder-stone-400 focus:outline-none focus:ring-2 focus:ring-[#B8FF3B]/50"
                />
              </div>
            </div>

            <div>
              <label className="text-sm font-semibold text-stone-900 dark:text-white mb-1.5 block">
                {t('nutritionalValues')}
              </label>
              <div className="grid grid-cols-4 gap-2.5">
                <div>
                  <span className="text-xs font-semibold text-stone-500 dark:text-stone-400 block mb-1">
                    {t('caloriesKcalField')}
                  </span>
                  <input
                    type="number"
                    min="0"
                    required
                    value={calories}
                    onChange={(e) => setCalories(e.target.value)}
                    className="w-full text-sm font-bold text-center px-2 py-2 rounded-lg border border-gray-200 dark:border-[#303830] bg-gray-50/50 dark:bg-[#202820] text-stone-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B8FF3B]/50"
                  />
                </div>
                <div>
                  <span className="text-xs font-semibold text-[#FF6B57] block mb-1">
                    {t('proteinLabel')} (g)
                  </span>
                  <input
                    type="number"
                    min="0"
                    step="0.1"
                    required
                    value={protein}
                    onChange={(e) => setProtein(e.target.value)}
                    className="w-full text-sm font-bold text-center px-2 py-2 rounded-lg border border-gray-200 dark:border-[#303830] bg-gray-50/50 dark:bg-[#202820] text-[#FF6B57] focus:outline-none focus:ring-2 focus:ring-[#FF6B57]/50"
                  />
                </div>
                <div>
                  <span className="text-xs font-semibold text-[#FFA048] block mb-1">
                    {t('carbsLabel')} (g)
                  </span>
                  <input
                    type="number"
                    min="0"
                    step="0.1"
                    required
                    value={carbs}
                    onChange={(e) => setCarbs(e.target.value)}
                    className="w-full text-sm font-bold text-center px-2 py-2 rounded-lg border border-gray-200 dark:border-[#303830] bg-gray-50/50 dark:bg-[#202820] text-[#FFA048] focus:outline-none focus:ring-2 focus:ring-[#FFA048]/50"
                  />
                </div>
                <div>
                  <span className="text-xs font-semibold text-[#7C9CFF] block mb-1">
                    {t('fatLabel')} (g)
                  </span>
                  <input
                    type="number"
                    min="0"
                    step="0.1"
                    required
                    value={fat}
                    onChange={(e) => setFat(e.target.value)}
                    className="w-full text-sm font-bold text-center px-2 py-2 rounded-lg border border-gray-200 dark:border-[#303830] bg-gray-50/50 dark:bg-[#202820] text-[#7C9CFF] focus:outline-none focus:ring-2 focus:ring-[#7C9CFF]/50"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Footer Actions */}
          <div className="flex items-center justify-end px-6 py-4 bg-gray-50/70 dark:bg-[#151C16] border-t border-gray-100 dark:border-[#222D23] space-x-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2.5 text-sm font-semibold text-stone-600 dark:text-stone-400 hover:text-stone-900 dark:hover:text-white transition-colors cursor-pointer"
            >
              {t('cancel')}
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-5 py-2.5 text-sm font-bold bg-[#B8FF3B] text-[#0C2417] hover:brightness-105 active:scale-95 rounded-xl shadow-xs transition-all flex items-center space-x-1.5 cursor-pointer"
            >
              <Plus className="w-4 h-4 text-[#0C2417] stroke-[2.2]" />
              <span>{foodToEdit ? t('saveChanges') : t('addToCatalog')}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
