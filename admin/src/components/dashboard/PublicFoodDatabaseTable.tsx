import React, { useState, useMemo } from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { Food } from '../../types';
import { DeleteFoodConfirmModal } from '../modals/DeleteFoodConfirmModal';
import {
  ChevronDown,
  Plus,
  Check,
  Pencil,
  Trash2,
  Search,
  X,
  ChevronLeft,
  ChevronRight,
  Minus,
} from 'lucide-react';

interface PublicFoodDatabaseTableProps {
  onOpenFoodModal: () => void;
  onEditFood?: (food: Food) => void;
}

export const PublicFoodDatabaseTable: React.FC<PublicFoodDatabaseTableProps> = ({
  onOpenFoodModal,
  onEditFood,
}) => {
  const { foods, deleteFood, deleteFoods, categories } = useAdmin();
  const { t } = useThemeLanguage();

  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [isCategoryOpen, setIsCategoryOpen] = useState<boolean>(false);

  // Pagination state
  const [currentPage, setCurrentPage] = useState<number>(1);
  const pageSize = 8;

  // Filtered foods
  const filteredFoods = useMemo(() => {
    return foods.filter((f) => {
      const q = searchTerm.toLowerCase().trim();
      const matchesSearch =
        !q ||
        f.name.toLowerCase().includes(q) ||
        (f.category && f.category.toLowerCase().includes(q));

      const matchesCategory =
        selectedCategory === 'all' ||
        f.category === selectedCategory ||
        f.category_id === selectedCategory;

      return matchesSearch && matchesCategory;
    });
  }, [foods, searchTerm, selectedCategory]);

  const totalEntries = filteredFoods.length;
  const totalPages = Math.max(1, Math.ceil(totalEntries / pageSize));
  const validCurrentPage = Math.min(currentPage, totalPages);

  const paginatedFoods = useMemo(() => {
    const start = (validCurrentPage - 1) * pageSize;
    return filteredFoods.slice(start, start + pageSize);
  }, [filteredFoods, validCurrentPage, pageSize]);

  // Checkbox handlers
  const toggleSelect = (id: string) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  const paginatedIds = useMemo(() => paginatedFoods.map((f) => f.id), [paginatedFoods]);
  const isAllPaginatedSelected =
    paginatedIds.length > 0 && paginatedIds.every((id) => selectedIds.includes(id));
  const isSomePaginatedSelected =
    paginatedIds.some((id) => selectedIds.includes(id)) && !isAllPaginatedSelected;

  const toggleSelectAll = () => {
    if (isAllPaginatedSelected) {
      setSelectedIds((prev) => prev.filter((id) => !paginatedIds.includes(id)));
    } else {
      setSelectedIds((prev) => Array.from(new Set([...prev, ...paginatedIds])));
    }
  };

  // Delete modal state
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState<boolean>(false);
  const [foodToDelete, setFoodToDelete] = useState<Food | null>(null);
  const [bulkFoodsToDelete, setBulkFoodsToDelete] = useState<Food[]>([]);

  const handleDeleteSingle = (food: Food) => {
    setFoodToDelete(food);
    setBulkFoodsToDelete([]);
    setIsDeleteModalOpen(true);
  };

  const handleDeleteBulk = () => {
    const targets = foods.filter((f) => selectedIds.includes(f.id));
    if (targets.length === 0) return;
    setFoodToDelete(null);
    setBulkFoodsToDelete(targets);
    setIsDeleteModalOpen(true);
  };

  const handleConfirmDelete = async (idOrIds: string | string[], reason: string) => {
    if (Array.isArray(idOrIds)) {
      await deleteFoods(idOrIds, reason);
      setSelectedIds((prev) => prev.filter((id) => !idOrIds.includes(id)));
    } else {
      await deleteFood(idOrIds, reason);
      setSelectedIds((prev) => prev.filter((id) => id !== idOrIds));
    }
  };

  return (
    <div className="bg-white dark:bg-[#141C17] rounded-2xl p-5 sm:p-6 border border-[#E9EFE8] dark:border-[#212E23] shadow-xs transition-colors duration-200 space-y-4">
      {/* ── HEADER & TOOLBAR ────────────────────────────────────────── */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
        <div>
          <h3 className="text-base sm:text-lg font-bold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
            {t('publicFoodDatabase')}
          </h3>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
            {totalEntries} {t('itemsCataloged')}
          </p>
        </div>

        {/* Search, Filter & Actions */}
        <div className="flex items-center space-x-2 flex-wrap gap-y-2">
          {/* Live Search Input */}
          <div className="relative">
            <Search className="w-3.5 h-3.5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none stroke-[1.8]" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              placeholder={t('searchPlaceholder')}
              className="bg-gray-50 dark:bg-[#1A241E] border border-gray-200 dark:border-gray-700 text-xs text-[#111111] dark:text-[#F3F5EF] placeholder-gray-400 rounded-full pl-8 pr-7 py-1.5 focus:outline-none focus:ring-1 focus:ring-[#B8FF3B] w-48 sm:w-56 transition-colors shadow-2xs"
            />
            {searchTerm && (
              <button
                onClick={() => {
                  setSearchTerm('');
                  setCurrentPage(1);
                }}
                aria-label="Clear search"
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-white cursor-pointer"
              >
                <X className="w-3 h-3 stroke-[2]" />
              </button>
            )}
          </div>

          {/* Category Filter Dropdown */}
          <div className="relative">
            <button
              onClick={() => setIsCategoryOpen(!isCategoryOpen)}
              className="px-3 py-1.5 rounded-full border border-gray-200 dark:border-gray-700 bg-white dark:bg-[#1A241E] hover:bg-gray-50 dark:hover:bg-[#223026] text-xs font-semibold text-gray-700 dark:text-gray-200 flex items-center space-x-1.5 shadow-2xs cursor-pointer transition-colors"
            >
              <span>{selectedCategory === 'all' ? t('category') : selectedCategory}</span>
              <ChevronDown className="w-3 h-3 text-gray-400 stroke-[2]" />
            </button>

            {isCategoryOpen && (
              <div className="absolute right-0 mt-1 w-44 bg-white dark:bg-[#18221B] border border-gray-200 dark:border-[#2A3B2E] rounded-xl shadow-lg z-30 py-1 text-xs">
                <button
                  onClick={() => {
                    setSelectedCategory('all');
                    setIsCategoryOpen(false);
                    setCurrentPage(1);
                  }}
                  className="w-full text-left px-3 py-1.5 hover:bg-gray-100 dark:hover:bg-[#202E23] text-gray-700 dark:text-gray-200 cursor-pointer font-medium"
                >
                  {t('allCategories')}
                </button>
                {categories.map((cat) => (
                  <button
                    key={cat.id}
                    onClick={() => {
                      setSelectedCategory(cat.name);
                      setIsCategoryOpen(false);
                      setCurrentPage(1);
                    }}
                    className="w-full text-left px-3 py-1.5 hover:bg-gray-100 dark:hover:bg-[#202E23] text-gray-700 dark:text-gray-200 truncate cursor-pointer font-medium"
                  >
                    {cat.name}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Primary CTA Button: Add Food */}
          <button
            onClick={onOpenFoodModal}
            className="px-4 py-1.5 rounded-full bg-[#B8FF3B] hover:brightness-105 active:scale-95 text-[#0C2417] text-xs font-bold flex items-center space-x-1.5 shadow-2xs transition-all cursor-pointer"
          >
            <Plus className="w-3.5 h-3.5 stroke-[2.2]" />
            <span>{t('addFood')}</span>
          </button>
        </div>
      </div>

      {/* ── BULK ACTION BAR ─────────────────────────────────────────── */}
      {selectedIds.length > 0 && (
        <div className="p-3 bg-red-50/80 dark:bg-red-950/30 border border-red-200 dark:border-red-900/50 rounded-xl flex items-center justify-between flex-wrap gap-2 animate-in fade-in slide-in-from-top-1 duration-150">
          <div className="flex items-center space-x-2">
            <span className="w-5 h-5 rounded-full bg-red-600 text-white text-[11px] font-bold flex items-center justify-center">
              {selectedIds.length}
            </span>
            <span className="text-xs font-semibold text-red-900 dark:text-red-200">
              {selectedIds.length} {t('itemsSelected')}
            </span>
          </div>

          <div className="flex items-center space-x-2">
            <button
              onClick={handleDeleteBulk}
              className="px-3.5 py-1.5 rounded-lg bg-red-600 hover:bg-red-700 active:scale-95 text-white text-xs font-bold flex items-center space-x-1.5 transition-all shadow-2xs cursor-pointer"
            >
              <Trash2 className="w-3.5 h-3.5 stroke-[2]" />
              <span>{t('deleteSelected')}</span>
            </button>
            <button
              onClick={() => setSelectedIds([])}
              className="px-3 py-1.5 rounded-lg border border-gray-300 dark:border-gray-600 hover:bg-white dark:hover:bg-[#1A241E] text-xs font-medium text-gray-700 dark:text-gray-300 transition-colors cursor-pointer"
            >
              {t('deselectAll')}
            </button>
          </div>
        </div>
      )}

      {/* ── TABLE ───────────────────────────────────────────────────── */}
      <div className="overflow-x-auto scrollbar-wide">
        <table className="w-full text-left border-collapse text-xs min-w-[700px]">
          <thead>
            <tr className="border-b border-[#F2F5F0] dark:border-[#202C22] text-[11px] font-semibold text-gray-400 dark:text-gray-500 pb-3">
              {/* Checkbox Header */}
              <th className="pb-3 pl-2 w-10">
                <button
                  onClick={toggleSelectAll}
                  aria-label="Select all rows on this page"
                  className={`w-4 h-4 rounded flex items-center justify-center transition-all cursor-pointer ${
                    isAllPaginatedSelected
                      ? 'bg-[#111111] dark:bg-white text-white dark:text-[#111111]'
                      : isSomePaginatedSelected
                      ? 'bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-white'
                      : 'border border-gray-300 dark:border-gray-600 bg-white dark:bg-[#1A241E]'
                  }`}
                >
                  {isAllPaginatedSelected ? (
                    <Check className="w-2.5 h-2.5 stroke-[3]" />
                  ) : isSomePaginatedSelected ? (
                    <Minus className="w-2.5 h-2.5 stroke-[3]" />
                  ) : null}
                </button>
              </th>
              <th className="pb-3 font-semibold">{t('foodName')}</th>
              <th className="pb-3 font-semibold">{t('categoryField')}</th>
              <th className="pb-3 font-semibold">{t('calories')}</th>
              <th className="pb-3 font-semibold">{t('protein')}</th>
              <th className="pb-3 font-semibold">{t('carbs')}</th>
              <th className="pb-3 font-semibold">{t('fat')}</th>
              <th className="pb-3 font-semibold">{t('servingLabel')}</th>
              <th className="pb-3 font-semibold text-center w-20">{t('action')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#F2F5F0] dark:divide-[#202C22]">
            {paginatedFoods.length === 0 ? (
              <tr>
                <td colSpan={9} className="py-10 text-center text-sm text-gray-400 dark:text-gray-500">
                  {t('noFoodsFound')}
                </td>
              </tr>
            ) : (
              paginatedFoods.map((food) => {
                const isChecked = selectedIds.includes(food.id);

                return (
                  <tr
                    key={food.id}
                    className={`hover:bg-[#F9FBF8] dark:hover:bg-[#19241D] transition-colors group ${
                      isChecked ? 'bg-green-50/30 dark:bg-[#18231B]/50' : ''
                    }`}
                  >
                    {/* Checkbox */}
                    <td className="py-3.5 pl-2">
                      <button
                        onClick={() => toggleSelect(food.id)}
                        aria-label={`Select ${food.name}`}
                        className={`w-4 h-4 rounded flex items-center justify-center transition-all cursor-pointer ${
                          isChecked
                            ? 'bg-[#111111] dark:bg-white text-white dark:text-[#111111]'
                            : 'border border-gray-300 dark:border-gray-600 bg-white dark:bg-[#1A241E]'
                        }`}
                      >
                        {isChecked && (
                          <Check className="w-2.5 h-2.5 stroke-[3]" />
                        )}
                      </button>
                    </td>

                    {/* Food Name */}
                    <td className="py-3.5 font-semibold text-[#111111] dark:text-[#F3F5EF] group-hover:text-[#16A34A] dark:group-hover:text-[#B8FF3B] transition-colors">
                      {food.name}
                    </td>

                    {/* Category */}
                    <td className="py-3.5 text-gray-600 dark:text-gray-300 font-medium">
                      {food.category || 'General'}
                    </td>

                    {/* Calories */}
                    <td className="py-3.5 font-bold text-[#111111] dark:text-white">
                      {food.calories} kcal
                    </td>

                    {/* Protein */}
                    <td className="py-3.5 text-gray-600 dark:text-gray-300 font-medium">
                      {food.protein_g}g
                    </td>

                    {/* Carbs */}
                    <td className="py-3.5 text-gray-600 dark:text-gray-300 font-medium">
                      {food.carbs_g}g
                    </td>

                    {/* Fat */}
                    <td className="py-3.5 text-gray-600 dark:text-gray-300 font-medium">
                      {food.fat_g}g
                    </td>

                    {/* Serving Label */}
                    <td className="py-3.5 text-gray-500 dark:text-gray-400 font-medium">
                      {food.serving_label || '100g standard'}
                    </td>

                    {/* Actions */}
                    <td className="py-3.5 text-center">
                      <div className="flex items-center justify-center space-x-1">
                        {onEditFood && (
                          <button
                            onClick={() => onEditFood(food)}
                            title={t('edit')}
                            className="w-7 h-7 rounded-lg hover:bg-gray-100 dark:hover:bg-[#253628] flex items-center justify-center text-gray-400 hover:text-gray-700 dark:hover:text-white transition-colors cursor-pointer"
                          >
                            <Pencil className="w-3.5 h-3.5 stroke-[1.8]" />
                          </button>
                        )}
                        <button
                          onClick={() => handleDeleteSingle(food)}
                          title={t('delete')}
                          className="w-7 h-7 rounded-lg hover:bg-red-50 dark:hover:bg-red-950/40 flex items-center justify-center text-gray-400 hover:text-red-500 transition-colors cursor-pointer"
                        >
                          <Trash2 className="w-3.5 h-3.5 stroke-[1.8]" />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* ── PAGINATION CONTROLS ─────────────────────────────────────── */}
      {totalPages > 1 && (
        <div className="pt-2 border-t border-[#F2F5F0] dark:border-[#202C22] flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
          <span>
            {t('showingText')}{' '}
            {Math.min(totalEntries, (validCurrentPage - 1) * pageSize + 1)}{' '}
            {t('toText')}{' '}
            {Math.min(totalEntries, validCurrentPage * pageSize)}{' '}
            {t('ofText')} {totalEntries} {t('entriesText')}
          </span>

          <div className="flex items-center space-x-1">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={validCurrentPage === 1}
              aria-label="Previous page"
              className="w-8 h-8 rounded-lg border border-gray-200 dark:border-[#2D382D] flex items-center justify-center disabled:opacity-30 hover:bg-gray-50 dark:hover:bg-[#202820] transition-colors cursor-pointer"
            >
              <ChevronLeft className="w-3.5 h-3.5 stroke-[2]" />
            </button>

            {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
              <button
                key={page}
                onClick={() => setCurrentPage(page)}
                className={`w-8 h-8 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  page === validCurrentPage
                    ? 'bg-[#B8FF3B] text-[#0C2417] shadow-2xs'
                    : 'hover:bg-gray-50 dark:hover:bg-[#202820] text-gray-600 dark:text-gray-400'
                }`}
              >
                {page}
              </button>
            ))}

            <button
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              disabled={validCurrentPage === totalPages}
              aria-label="Next page"
              className="w-8 h-8 rounded-lg border border-gray-200 dark:border-[#2D382D] flex items-center justify-center disabled:opacity-30 hover:bg-gray-50 dark:hover:bg-[#202820] transition-colors cursor-pointer"
            >
              <ChevronRight className="w-3.5 h-3.5 stroke-[2]" />
            </button>
          </div>
        </div>
      )}

      {/* Delete Food Confirm Modal with Reason (Single or Bulk) */}
      <DeleteFoodConfirmModal
        isOpen={isDeleteModalOpen}
        food={foodToDelete}
        foods={bulkFoodsToDelete}
        onClose={() => {
          setIsDeleteModalOpen(false);
          setFoodToDelete(null);
          setBulkFoodsToDelete([]);
        }}
        onConfirm={handleConfirmDelete}
      />
    </div>
  );
};
