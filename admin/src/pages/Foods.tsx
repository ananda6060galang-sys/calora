import React, { useState, useMemo } from 'react';
import { useOutletContext } from 'react-router-dom';
import { useAdmin } from '../context/AdminContext';
import { useThemeLanguage } from '../context/ThemeLanguageContext';
import { AdminHeader } from '../components/layout/AdminHeader';
import { FoodFormModal } from '../components/modals/FoodFormModal';
import { DeleteFoodConfirmModal } from '../components/modals/DeleteFoodConfirmModal';
import { Food } from '../types';
import {
  Utensils,
  Folder,
  Flame,
  Zap,
  Search,
  X,
  Plus,
  ChevronUp,
  ChevronDown,
  ChevronsUpDown,
  Pencil,
  Trash2,
  ChevronLeft,
  ChevronRight,
  Check,
  Minus,
} from 'lucide-react';

type SortField = 'name' | 'category' | 'calories' | 'created_at';
type SortOrder = 'asc' | 'desc';

export const Foods: React.FC = () => {
  const { foods, categories, deleteFood, deleteFoods } = useAdmin();
  const { t } = useThemeLanguage();
  const { handleOpenFoodModal } = useOutletContext<{
    handleOpenFoodModal: () => void;
  }>();

  const [searchTerm, setSearchTerm] = useState('');
  const [foodCategoryFilter, setFoodCategoryFilter] = useState('all');
  const [sortField, setSortField] = useState<SortField>('name');
  const [sortOrder, setSortOrder] = useState<SortOrder>('asc');

  const [currentPage, setCurrentPage] = useState(1);
  const pageSize = 10;

  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [foodToEdit, setFoodToEdit] = useState<Food | null>(null);

  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [foodToDelete, setFoodToDelete] = useState<Food | null>(null);
  const [bulkFoodsToDelete, setBulkFoodsToDelete] = useState<Food[]>([]);

  const handleEdit = (food: Food) => {
    setFoodToEdit(food);
    setIsEditModalOpen(true);
  };

  const handleDelete = (food: Food) => {
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

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('asc');
    }
  };

  // Metrics
  const avgCalories = useMemo(() => {
    if (foods.length === 0) return 0;
    const total = foods.reduce((acc, f) => acc + f.calories, 0);
    return Math.round(total / foods.length);
  }, [foods]);

  const highProteinDishes = useMemo(() => {
    return foods.filter((f) => f.protein_g >= 20).length;
  }, [foods]);

  // Filtered & Sorted Foods
  const processedFoods = useMemo(() => {
    return foods
      .filter((food) => {
        const matchesSearch =
          !searchTerm ||
          food.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
          (food.category && food.category.toLowerCase().includes(searchTerm.toLowerCase()));

        const matchesCategory =
          foodCategoryFilter === 'all' ||
          food.category === foodCategoryFilter ||
          food.category_id === foodCategoryFilter;

        return matchesSearch && matchesCategory;
      })
      .sort((a, b) => {
        let comparison = 0;
        if (sortField === 'name') {
          comparison = a.name.localeCompare(b.name);
        } else if (sortField === 'category') {
          comparison = (a.category || '').localeCompare(b.category || '');
        } else if (sortField === 'calories') {
          comparison = (a.calories || 0) - (b.calories || 0);
        }
        return sortOrder === 'asc' ? comparison : -comparison;
      });
  }, [foods, searchTerm, foodCategoryFilter, sortField, sortOrder]);

  const totalEntries = processedFoods.length;
  const totalPages = Math.ceil(totalEntries / pageSize) || 1;
  const validCurrentPage = Math.min(Math.max(1, currentPage), totalPages);

  const paginatedFoods = useMemo(() => {
    const start = (validCurrentPage - 1) * pageSize;
    return processedFoods.slice(start, start + pageSize);
  }, [processedFoods, validCurrentPage, pageSize]);

  const paginatedIds = useMemo(() => paginatedFoods.map((f) => f.id), [paginatedFoods]);
  const isAllPaginatedSelected =
    paginatedIds.length > 0 && paginatedIds.every((id) => selectedIds.includes(id));
  const isSomePaginatedSelected =
    paginatedIds.some((id) => selectedIds.includes(id)) && !isAllPaginatedSelected;

  const toggleSelect = (id: string) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  const toggleSelectAll = () => {
    if (isAllPaginatedSelected) {
      setSelectedIds((prev) => prev.filter((id) => !paginatedIds.includes(id)));
    } else {
      setSelectedIds((prev) => Array.from(new Set([...prev, ...paginatedIds])));
    }
  };

  return (
    <div className="space-y-6">
      {/* ── HEADER ──────────────────────────────────────────────────── */}
      <AdminHeader
        title={t('foodsCatalog')}
        actionLabel={t('addFood')}
        onAction={handleOpenFoodModal}
        actionIcon={Plus}
        showSearch={false}
      />

      {/* ── 4 STAT CARDS ────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5 sm:gap-4">
        {/* Card 1: Total Foods */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#B8FF3B] text-[#0C2417]">
            <Utensils className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {foods.length.toLocaleString()}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('totalFoods')}
          </span>
        </div>

        {/* Card 2: Total Categories */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-[#111111] dark:text-[#E2E8DF]">
            <Folder className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {categories.length}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('totalCategories')}
          </span>
        </div>

        {/* Card 3: Average Calories */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-amber-600 dark:text-amber-400">
            <Flame className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {avgCalories} <span className="text-sm font-normal text-stone-400">kcal</span>
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            Avg {t('calories')}
          </span>
        </div>

        {/* Card 4: High Protein */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-emerald-600 dark:text-emerald-400">
            <Zap className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {highProteinDishes}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            High Protein (&ge;20g)
          </span>
        </div>
      </div>

      {/* ── TOOLBAR: SEARCH & CATEGORY FILTER ───────────────────────── */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
        {/* Category Pills */}
        <div className="flex items-center space-x-2 overflow-x-auto pb-1 max-w-full scrollbar-wide">
          <button
            onClick={() => {
              setFoodCategoryFilter('all');
              setCurrentPage(1);
            }}
            className={`px-4.5 py-2.5 text-sm font-semibold rounded-full transition-all whitespace-nowrap cursor-pointer ${
              foodCategoryFilter === 'all'
                ? 'bg-[#B8FF3B] text-[#0C2417] font-bold shadow-2xs'
                : 'bg-white dark:bg-[#181E19] text-stone-600 dark:text-stone-400 border border-[#EAECE8] dark:border-[#263226] hover:text-[#111111] dark:hover:text-white'
            }`}
          >
            {t('allCategories')}
          </button>
          {categories.map((c) => (
            <button
              key={c.id}
              onClick={() => {
                setFoodCategoryFilter(c.name);
                setCurrentPage(1);
              }}
              className={`px-4.5 py-2.5 text-sm font-semibold rounded-full transition-all whitespace-nowrap cursor-pointer ${
                foodCategoryFilter === c.name
                  ? 'bg-[#B8FF3B] text-[#0C2417] font-bold shadow-2xs'
                  : 'bg-white dark:bg-[#181E19] text-stone-600 dark:text-stone-400 border border-[#EAECE8] dark:border-[#263226] hover:text-[#111111] dark:hover:text-white'
              }`}
            >
              {c.name}
            </button>
          ))}
        </div>

        {/* Search */}
        <div className="relative shrink-0">
          <Search className="w-4 h-4 text-stone-400 dark:text-stone-500 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none stroke-[1.8]" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => {
              setSearchTerm(e.target.value);
              setCurrentPage(1);
            }}
            placeholder={t('searchPlaceholder')}
            className="bg-[#EFF2EE] dark:bg-[#181E19] border border-[#E0E5DF] dark:border-[#263226] text-sm text-[#111111] dark:text-[#F3F5EF] placeholder-stone-500 dark:placeholder-stone-400 rounded-full pl-10 pr-8 py-2.5 focus:outline-none focus:border-[#B8FF3B] focus:ring-1 focus:ring-[#B8FF3B] w-full sm:w-72 transition-colors shadow-2xs"
          />
          {searchTerm && (
            <button
              onClick={() => setSearchTerm('')}
              aria-label="Clear search"
              className="absolute right-3 top-1/2 -translate-y-1/2 text-stone-400 hover:text-stone-600 dark:hover:text-white cursor-pointer"
            >
              <X className="w-3.5 h-3.5 stroke-[2]" />
            </button>
          )}
        </div>
      </div>

      {/* ── FOODS TABLE ─────────────────────────────────────────────── */}
      <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] border border-[#EAEFE8] dark:border-[#212E23] shadow-xs overflow-hidden transition-colors duration-200">
        <div className="p-4.5 sm:px-6 border-b border-[#F2F5F0] dark:border-[#202C22] flex items-center justify-between text-sm text-stone-500 dark:text-stone-400">
          <span className="font-bold text-[#111111] dark:text-[#F3F5EF]">
            {totalEntries} {t('itemsCataloged')}
          </span>
          <button
            onClick={handleOpenFoodModal}
            className="text-sm font-bold text-[#16A34A] dark:text-[#B8FF3B] hover:underline cursor-pointer flex items-center space-x-1.5"
          >
            <Plus className="w-3.5 h-3.5 stroke-[2.2]" />
            <span>{t('addFood')}</span>
          </button>
        </div>

        {/* ── BULK ACTION BAR ───────────────────────────────────────── */}
        {selectedIds.length > 0 && (
          <div className="p-3.5 mx-4 my-3 bg-red-50/80 dark:bg-red-950/30 border border-red-200 dark:border-red-900/50 rounded-xl flex items-center justify-between flex-wrap gap-2 animate-in fade-in slide-in-from-top-1 duration-150">
            <div className="flex items-center space-x-2.5">
              <span className="w-5.5 h-5.5 rounded-full bg-red-600 text-white text-xs font-bold flex items-center justify-center">
                {selectedIds.length}
              </span>
              <span className="text-sm font-semibold text-red-900 dark:text-red-200">
                {selectedIds.length} {t('itemsSelected')}
              </span>
            </div>

            <div className="flex items-center space-x-2">
              <button
                onClick={handleDeleteBulk}
                className="px-4 py-2 rounded-xl bg-red-600 hover:bg-red-700 active:scale-95 text-white text-sm font-bold flex items-center space-x-2 transition-all shadow-2xs cursor-pointer"
              >
                <Trash2 className="w-4 h-4 stroke-[2]" />
                <span>{t('deleteSelected')}</span>
              </button>
              <button
                onClick={() => setSelectedIds([])}
                className="px-3.5 py-2 rounded-xl border border-stone-300 dark:border-stone-600 hover:bg-white dark:hover:bg-[#1A241E] text-sm font-medium text-stone-700 dark:text-stone-300 transition-colors cursor-pointer"
              >
                {t('deselectAll')}
              </button>
            </div>
          </div>
        )}

        {paginatedFoods.length === 0 ? (
          <div className="py-16 text-center">
            <Utensils className="w-8 h-8 text-gray-300 dark:text-gray-600 mx-auto mb-2 stroke-[1.5]" />
            <p className="text-sm font-bold text-[#111111] dark:text-[#F3F5EF]">
              {t('noFoodsFound')}
            </p>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
              {t('noFoodsFilterHelp')}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto scrollbar-wide">
            <table className="w-full text-left border-collapse text-sm min-w-[720px]">
              <thead>
                <tr className="border-b border-[#F2F5F0] dark:border-[#202C22] text-[13px] font-semibold text-stone-700 dark:text-stone-300">
                  <th className="py-3.5 px-4 w-10 text-center">
                    <button
                      onClick={toggleSelectAll}
                      aria-label="Select all rows on this page"
                      className={`w-4 h-4 rounded flex items-center justify-center transition-all cursor-pointer mx-auto ${
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
                  <th
                    onClick={() => handleSort('name')}
                    className="py-3.5 px-4 cursor-pointer hover:text-black dark:hover:text-white select-none transition-colors"
                  >
                    <div className="flex items-center space-x-1">
                      <span>{t('foodName')}</span>
                      {sortField === 'name' ? (
                        sortOrder === 'asc' ? <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" /> : <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" />
                      ) : (
                        <ChevronsUpDown className="w-3.5 h-3.5 opacity-40 stroke-[2]" />
                      )}
                    </div>
                  </th>
                  <th
                    onClick={() => handleSort('category')}
                    className="py-3.5 px-4 cursor-pointer hover:text-black dark:hover:text-white select-none transition-colors"
                  >
                    <div className="flex items-center space-x-1">
                      <span>{t('categoryField')}</span>
                      {sortField === 'category' ? (
                        sortOrder === 'asc' ? <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" /> : <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" />
                      ) : (
                        <ChevronsUpDown className="w-3.5 h-3.5 opacity-40 stroke-[2]" />
                      )}
                    </div>
                  </th>
                  <th
                    onClick={() => handleSort('calories')}
                    className="py-3.5 px-4 cursor-pointer hover:text-black dark:hover:text-white select-none transition-colors"
                  >
                    <div className="flex items-center space-x-1">
                      <span>{t('calories')}</span>
                      {sortField === 'calories' ? (
                        sortOrder === 'asc' ? <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" /> : <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" />
                      ) : (
                        <ChevronsUpDown className="w-3.5 h-3.5 opacity-40 stroke-[2]" />
                      )}
                    </div>
                  </th>
                  <th className="py-3.5 px-4">{t('protein')}</th>
                  <th className="py-3.5 px-4">{t('carbs')}</th>
                  <th className="py-3.5 px-4">{t('fat')}</th>
                  <th className="py-3.5 px-4">{t('servingLabel')}</th>
                  <th className="py-3.5 px-4 text-center w-20">{t('action')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#F2F5F0] dark:divide-[#202C22]">
                {paginatedFoods.map((food) => {
                  const isChecked = selectedIds.includes(food.id);
                  return (
                    <tr
                      key={food.id}
                      className={`hover:bg-[#F9FBF8] dark:hover:bg-[#19241D] transition-colors group ${
                        isChecked ? 'bg-green-50/30 dark:bg-[#18231B]/50' : ''
                      }`}
                    >
                      <td className="py-3.5 px-4 text-center">
                        <button
                          onClick={() => toggleSelect(food.id)}
                          aria-label={`Select ${food.name}`}
                          className={`w-4 h-4 rounded flex items-center justify-center transition-all cursor-pointer mx-auto ${
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

                      <td className="py-3.5 px-4 font-semibold text-sm text-[#111111] dark:text-[#F3F5EF] group-hover:text-[#16A34A] dark:group-hover:text-[#B8FF3B] transition-colors">
                        {food.name}
                      </td>

                      <td className="py-3.5 px-4 text-sm text-stone-700 dark:text-stone-300 font-medium">
                        {food.category || 'General'}
                      </td>

                      <td className="py-3.5 px-4 text-sm font-bold text-[#111111] dark:text-white">
                        {food.calories} kcal
                      </td>

                      <td className="py-3.5 px-4 text-sm text-stone-700 dark:text-stone-300 font-medium">
                        {food.protein_g}g
                      </td>

                      <td className="py-3.5 px-4 text-sm text-stone-700 dark:text-stone-300 font-medium">
                        {food.carbs_g}g
                      </td>

                      <td className="py-3.5 px-4 text-sm text-stone-700 dark:text-stone-300 font-medium">
                        {food.fat_g}g
                      </td>

                      <td className="py-3.5 px-4 text-[13px] text-stone-600 dark:text-stone-300 font-medium">
                        {food.serving_label || '100g standard'}
                      </td>

                      <td className="py-3.5 px-4 text-center">
                        <div className="flex items-center justify-center space-x-1">
                          <button
                            onClick={() => handleEdit(food)}
                            title={t('edit')}
                            className="w-8 h-8 rounded-lg hover:bg-gray-100 dark:hover:bg-[#253628] flex items-center justify-center text-stone-400 hover:text-stone-700 dark:hover:text-white transition-colors cursor-pointer"
                          >
                            <Pencil className="w-4 h-4 stroke-[1.8]" />
                          </button>
                          <button
                            onClick={() => handleDelete(food)}
                            title={t('delete')}
                            className="w-8 h-8 rounded-lg hover:bg-red-50 dark:hover:bg-red-950/40 flex items-center justify-center text-stone-400 hover:text-red-500 transition-colors cursor-pointer"
                          >
                            <Trash2 className="w-4 h-4 stroke-[1.8]" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* ── PAGINATION ────────────────────────────────────────────── */}
        {totalPages > 1 && (
          <div className="p-4 border-t border-[#F2F5F0] dark:border-[#202C22] flex items-center justify-between text-sm text-stone-600 dark:text-stone-400">
            <span>
              {t('showingText')} {Math.min(totalEntries, (validCurrentPage - 1) * pageSize + 1)} {t('toText')}{' '}
              {Math.min(totalEntries, validCurrentPage * pageSize)} {t('ofText')} {totalEntries} {t('entriesText')}
            </span>

            <div className="flex items-center space-x-1">
              <button
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                disabled={validCurrentPage === 1}
                aria-label="Previous page"
                className="w-8.5 h-8.5 rounded-lg border border-gray-200 dark:border-[#2D382D] flex items-center justify-center disabled:opacity-30 hover:bg-gray-50 dark:hover:bg-[#202820] transition-colors cursor-pointer"
              >
                <ChevronLeft className="w-4 h-4 stroke-[2]" />
              </button>

              {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
                <button
                  key={page}
                  onClick={() => setCurrentPage(page)}
                  className={`w-8.5 h-8.5 rounded-lg text-sm font-semibold transition-all cursor-pointer ${
                    page === validCurrentPage
                      ? 'bg-[#B8FF3B] text-[#0C2417] shadow-2xs font-bold'
                      : 'hover:bg-gray-50 dark:hover:bg-[#202820] text-stone-600 dark:text-stone-400'
                  }`}
                >
                  {page}
                </button>
              ))}

              <button
                onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                disabled={validCurrentPage === totalPages}
                aria-label="Next page"
                className="w-8.5 h-8.5 rounded-lg border border-gray-200 dark:border-[#2D382D] flex items-center justify-center disabled:opacity-30 hover:bg-gray-50 dark:hover:bg-[#202820] transition-colors cursor-pointer"
              >
                <ChevronRight className="w-4 h-4 stroke-[2]" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Edit Food Modal */}
      <FoodFormModal
        isOpen={isEditModalOpen}
        foodToEdit={foodToEdit}
        onClose={() => {
          setIsEditModalOpen(false);
          setFoodToEdit(null);
        }}
      />

      {/* Delete Food Modal with Reason (Single or Bulk) */}
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
