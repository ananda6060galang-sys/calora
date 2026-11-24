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
  const { t, language } = useThemeLanguage();

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
    setBulkFoodsToDelete(targets);
    setFoodToDelete(null);
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
    <div className="bg-white dark:bg-[#141C16] rounded-[24px] p-6 sm:p-7 shadow-soft hover-card-lift border-0 space-y-5 select-none animate-card-rise stagger-4">
      {/* ── 1. TOOLBAR: Search, Category Filter & Add Food (Soft Rounded Pills) ── */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <h3 className="text-base sm:text-lg font-semibold text-stone-900 dark:text-white tracking-tight">
            {t('publicFoodDatabase') || (language === 'id' ? 'Database Makanan Publik' : 'Public Food Database')}
          </h3>
          <p className="text-sm text-stone-500 dark:text-stone-400 mt-0.5">
            {totalEntries} {language === 'id' ? 'menu terdaftar' : 'items cataloged'}
          </p>
        </div>

        {/* Search, Filter & Actions (Pill Controls) */}
        <div className="flex items-center space-x-2.5 flex-wrap gap-y-2">
          {/* Live Search Input (Rounded Pill) */}
          <div className="relative">
            <Search className="w-4 h-4 text-stone-400 dark:text-stone-500 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none stroke-[1.8]" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              placeholder={t('searchPlaceholder') || (language === 'id' ? 'Cari di sini...' : 'Search foods...')}
              className="bg-[#F4F6F2] dark:bg-[#1A251D] border-0 text-sm text-stone-900 dark:text-white placeholder-stone-500 dark:placeholder-stone-400 rounded-full pl-10 pr-8 py-2.5 focus:outline-none focus:ring-2 focus:ring-[#B8FF3B]/50 w-48 sm:w-60 transition-all"
            />
            {searchTerm && (
              <button
                onClick={() => {
                  setSearchTerm('');
                  setCurrentPage(1);
                }}
                aria-label="Clear search"
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-stone-400 hover:text-stone-700 dark:hover:text-white cursor-pointer"
              >
                <X className="w-3.5 h-3.5 stroke-[2]" />
              </button>
            )}
          </div>

          {/* Category Filter Dropdown (Rounded Pill) */}
          <div className="relative">
            <button
              onClick={() => setIsCategoryOpen(!isCategoryOpen)}
              className="px-4 py-2.5 rounded-full bg-[#F4F6F2] dark:bg-[#1A251D] hover:bg-[#EAEFE8] dark:hover:bg-white/10 text-sm font-medium text-stone-700 dark:text-stone-200 flex items-center space-x-2 cursor-pointer transition-colors"
            >
              <span className="max-w-[130px] truncate">
                {selectedCategory === 'all'
                  ? (language === 'id' ? 'Semua Kategori' : 'All Categories')
                  : selectedCategory}
              </span>
              <ChevronDown className="w-4 h-4 text-stone-400 stroke-[2] shrink-0" />
            </button>

            {isCategoryOpen && (
              <div className="absolute right-0 mt-1.5 w-52 bg-white dark:bg-[#1A251D] rounded-2xl shadow-lg z-30 py-1.5 text-sm border border-stone-100 dark:border-white/10">
                <button
                  onClick={() => {
                    setSelectedCategory('all');
                    setIsCategoryOpen(false);
                    setCurrentPage(1);
                  }}
                  className="w-full text-left px-4 py-2.5 hover:bg-[#F4F6F2] dark:hover:bg-white/[0.06] text-stone-700 dark:text-stone-200 cursor-pointer font-medium"
                >
                  {language === 'id' ? 'Semua Kategori' : 'All Categories'}
                </button>
                {categories.map((cat) => (
                  <button
                    key={cat.id}
                    onClick={() => {
                      setSelectedCategory(cat.name);
                      setIsCategoryOpen(false);
                      setCurrentPage(1);
                    }}
                    className="w-full text-left px-4 py-2.5 hover:bg-[#F4F6F2] dark:hover:bg-white/[0.06] text-stone-700 dark:text-stone-200 truncate cursor-pointer font-medium"
                  >
                    {cat.name}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Primary CTA Button: Add Food (Dark Pill with Lime Icon) */}
          <button
            onClick={onOpenFoodModal}
            className="px-4.5 py-2.5 rounded-full bg-[#0B120C] hover:bg-[#18241A] dark:bg-white dark:hover:bg-stone-200 text-white dark:text-black text-sm font-semibold flex items-center space-x-1.5 transition-all cursor-pointer active:scale-95 shadow-2xs"
          >
            <Plus className="w-4 h-4 text-[#B8FF3B] dark:text-stone-900 stroke-[2.5]" />
            <span>{t('addFood') || (language === 'id' ? 'Tambah Makanan' : 'Add Food')}</span>
          </button>
        </div>
      </div>

      {/* ── BULK ACTION BAR ─────────────────────────────────────────── */}
      {selectedIds.length > 0 && (
        <div className="p-3 bg-rose-50 dark:bg-rose-950/30 rounded-2xl flex items-center justify-between flex-wrap gap-2 animate-in fade-in duration-200">
          <div className="flex items-center space-x-2.5">
            <span className="w-5 h-5 rounded-full bg-rose-600 text-white text-[11px] font-bold flex items-center justify-center">
              {selectedIds.length}
            </span>
            <span className="text-xs font-medium text-rose-800 dark:text-rose-200">
              {selectedIds.length} {language === 'id' ? 'item dipilih' : 'items selected'}
            </span>
          </div>

          <div className="flex items-center space-x-2">
            <button
              onClick={handleDeleteBulk}
              className="px-3.5 py-1.5 rounded-full bg-rose-600 hover:bg-rose-700 active:scale-95 text-white text-xs font-medium flex items-center space-x-1.5 transition-colors cursor-pointer"
            >
              <Trash2 className="w-3.5 h-3.5 stroke-[2]" />
              <span>{t('deleteSelected') || (language === 'id' ? 'Hapus Terpilih' : 'Delete Selected')}</span>
            </button>
            <button
              onClick={() => setSelectedIds([])}
              className="px-3.5 py-1.5 rounded-full bg-white dark:bg-white/10 hover:bg-rose-100 dark:hover:bg-white/20 text-xs font-medium text-rose-700 dark:text-gray-300 transition-colors cursor-pointer"
            >
              {language === 'id' ? 'Batal' : 'Deselect All'}
            </button>
          </div>
        </div>
      )}

      {/* ── TABLE: 64PX ROWS, SOFT HAIRLINE DIVIDERS, SENTENCE CASE HEADERS ── */}
      <div className="overflow-x-auto scrollbar-wide">
        <table className="w-full text-left border-collapse text-sm min-w-[720px]">
          <thead>
            <tr className="border-b border-stone-200/60 dark:border-white/[0.08] text-[13px] font-semibold text-stone-600 dark:text-stone-300">
              {/* Checkbox Header */}
              <th className="py-3.5 pl-3 w-10">
                <button
                  onClick={toggleSelectAll}
                  aria-label="Select all rows on this page"
                  className={`w-4 h-4 rounded-full flex items-center justify-center transition-all cursor-pointer ${
                    isAllPaginatedSelected
                      ? 'bg-[#B8FF3B] text-black font-bold'
                      : isSomePaginatedSelected
                      ? 'bg-stone-500 text-white'
                      : 'border border-stone-300 dark:border-white/20 bg-white dark:bg-white/[0.04]'
                  }`}
                >
                  {isAllPaginatedSelected ? (
                    <Check className="w-2.5 h-2.5 stroke-[3]" />
                  ) : isSomePaginatedSelected ? (
                    <Minus className="w-2.5 h-2.5 stroke-[3]" />
                  ) : null}
                </button>
              </th>
              <th className="py-3.5 font-semibold">{t('foodName') || (language === 'id' ? 'Nama makanan' : 'Food name')}</th>
              <th className="py-3.5 font-semibold">{t('categoryField') || (language === 'id' ? 'Kategori' : 'Category')}</th>
              <th className="py-3.5 font-semibold text-right pr-4">{t('calories') || (language === 'id' ? 'Kalori' : 'Calories')}</th>
              <th className="py-3.5 font-semibold text-right pr-4">{t('protein') || (language === 'id' ? 'Protein' : 'Protein')}</th>
              <th className="py-3.5 font-semibold text-right pr-4">{t('carbs') || (language === 'id' ? 'Karbo' : 'Carbs')}</th>
              <th className="py-3.5 font-semibold text-right pr-4">{t('fat') || (language === 'id' ? 'Lemak' : 'Fat')}</th>
              <th className="py-3.5 font-semibold">{t('servingLabel') || (language === 'id' ? 'Porsi' : 'Serving')}</th>
              <th className="py-3.5 font-semibold text-center w-20">{t('action') || (language === 'id' ? 'Aksi' : 'Action')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-stone-100 dark:divide-white/[0.04]">
            {paginatedFoods.length === 0 ? (
              <tr>
                <td colSpan={9} className="py-12 text-center text-sm text-stone-400 dark:text-stone-500">
                  {t('noFoodsFound') || (language === 'id' ? 'Tidak ada makanan ditemukan' : 'No foods found')}
                </td>
              </tr>
            ) : (
              paginatedFoods.map((food) => {
                const isChecked = selectedIds.includes(food.id);

                return (
                  <tr
                    key={food.id}
                    className={`h-16 hover:bg-[#F8FAF7] dark:hover:bg-white/[0.02] transition-colors group ${
                      isChecked ? 'bg-[#EDF7E7]/40 dark:bg-[#18261B]/30' : ''
                    }`}
                  >
                    {/* Checkbox */}
                    <td className="py-0 pl-3">
                      <button
                        onClick={() => toggleSelect(food.id)}
                        aria-label={`Select ${food.name}`}
                        className={`w-4 h-4 rounded-full flex items-center justify-center transition-all cursor-pointer ${
                          isChecked
                            ? 'bg-[#B8FF3B] text-black font-bold'
                            : 'border border-stone-300 dark:border-white/20 bg-white dark:bg-white/[0.04]'
                        }`}
                      >
                        {isChecked && (
                          <Check className="w-2.5 h-2.5 stroke-[3]" />
                        )}
                      </button>
                    </td>

                    {/* Food Name with Clean Monogram Avatar */}
                    <td className="py-0 font-medium text-stone-900 dark:text-white group-hover:text-black dark:group-hover:text-[#B8FF3B] transition-colors">
                      <div className="flex items-center space-x-3">
                        <div className="w-9 h-9 rounded-full bg-[#EDF7E7] dark:bg-white/[0.08] text-[#16A34A] dark:text-[#B8FF3B] flex items-center justify-center text-sm font-semibold shrink-0 group-hover:scale-105 transition-transform">
                          {food.name ? food.name.charAt(0).toUpperCase() : 'F'}
                        </div>
                        <span className="truncate max-w-[200px] text-sm">{food.name}</span>
                      </div>
                    </td>

                    {/* Category Soft Tinted Pill */}
                    <td className="py-0">
                      <span className="px-3 py-1 rounded-full bg-[#EDF7E7] dark:bg-[#18261B] text-xs font-semibold text-[#16A34A] dark:text-[#B8FF3B] inline-block">
                        {food.category || 'General'}
                      </span>
                    </td>

                    {/* Calories (Right-aligned, tabular figures) */}
                    <td className="py-0 text-sm text-right tabular-nums pr-4 text-stone-900 dark:text-white font-semibold">
                      {food.calories} <span className="text-xs text-stone-500 dark:text-stone-400 font-medium ml-0.5">kcal</span>
                    </td>

                    {/* Protein (Right-aligned) */}
                    <td className="py-0 text-sm text-right tabular-nums pr-4 text-stone-700 dark:text-stone-300 font-medium">
                      {food.protein_g}g
                    </td>

                    {/* Carbs (Right-aligned) */}
                    <td className="py-0 text-sm text-right tabular-nums pr-4 text-stone-700 dark:text-stone-300 font-medium">
                      {food.carbs_g}g
                    </td>

                    {/* Fat (Right-aligned) */}
                    <td className="py-0 text-sm text-right tabular-nums pr-4 text-stone-700 dark:text-stone-300 font-medium">
                      {food.fat_g}g
                    </td>

                    {/* Serving Label */}
                    <td className="py-0 text-[13px] text-stone-600 dark:text-stone-300 font-medium">
                      {food.serving_label || '100g standard'}
                    </td>

                    {/* Actions (Circular Soft Buttons) */}
                    <td className="py-0 text-center">
                      <div className="flex items-center justify-center space-x-1">
                        {onEditFood && (
                          <button
                            onClick={() => onEditFood(food)}
                            title={t('edit') || 'Edit'}
                            className="w-8.5 h-8.5 rounded-full hover:bg-stone-100 dark:hover:bg-white/10 flex items-center justify-center text-stone-400 hover:text-stone-700 dark:hover:text-white transition-colors cursor-pointer"
                          >
                            <Pencil className="w-4 h-4 stroke-[1.8]" />
                          </button>
                        )}
                        <button
                          onClick={() => handleDeleteSingle(food)}
                          title={t('delete') || 'Delete'}
                          className="w-8.5 h-8.5 rounded-full hover:bg-rose-50 dark:hover:bg-rose-950/40 flex items-center justify-center text-stone-400 hover:text-rose-600 transition-colors cursor-pointer"
                        >
                          <Trash2 className="w-4 h-4 stroke-[1.8]" />
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
        <div className="pt-3 border-t border-stone-100 dark:border-white/[0.06] flex items-center justify-between text-sm text-stone-600 dark:text-stone-400">
          <span>
            {language === 'id' ? 'Menampilkan' : 'Showing'}{' '}
            {Math.min(totalEntries, (validCurrentPage - 1) * pageSize + 1)}{' '}
            {language === 'id' ? 'hingga' : 'to'}{' '}
            {Math.min(totalEntries, validCurrentPage * pageSize)}{' '}
            {language === 'id' ? 'dari' : 'of'} {totalEntries} {language === 'id' ? 'entri' : 'entries'}
          </span>

          <div className="flex items-center space-x-1.5">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={validCurrentPage === 1}
              aria-label="Previous page"
              className="w-8.5 h-8.5 rounded-full bg-[#F4F6F2] dark:bg-white/[0.06] flex items-center justify-center disabled:opacity-30 hover:bg-[#EAEFE8] dark:hover:bg-white/10 transition-colors cursor-pointer"
            >
              <ChevronLeft className="w-4 h-4 stroke-[2]" />
            </button>

            {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
              <button
                key={page}
                onClick={() => setCurrentPage(page)}
                className={`w-8.5 h-8.5 rounded-full text-sm font-medium transition-colors cursor-pointer ${
                  page === validCurrentPage
                    ? 'bg-[#0B120C] text-white dark:bg-white dark:text-black font-semibold'
                    : 'hover:bg-[#F4F6F2] dark:hover:bg-white/[0.05] text-stone-600 dark:text-stone-400'
                }`}
              >
                {page}
              </button>
            ))}

            <button
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              disabled={validCurrentPage === totalPages}
              aria-label="Next page"
              className="w-8.5 h-8.5 rounded-full bg-[#F4F6F2] dark:bg-white/[0.06] flex items-center justify-center disabled:opacity-30 hover:bg-[#EAEFE8] dark:hover:bg-white/10 transition-colors cursor-pointer"
            >
              <ChevronRight className="w-4 h-4 stroke-[2]" />
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
