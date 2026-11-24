import React, { useState, useMemo } from 'react';
import { useAdmin } from '../context/AdminContext';
import { useThemeLanguage } from '../context/ThemeLanguageContext';
import { AdminHeader } from '../components/layout/AdminHeader';
import { CategoryModal } from '../components/modals/CategoryModal';
import { BulkDeleteCategoryModal } from '../components/modals/BulkDeleteCategoryModal';
import { FoodCategory } from '../types';
import {
  Folder,
  Search,
  Plus,
  Pencil,
  Trash2,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  ChevronDown,
  ChevronsUpDown,
  X,
  CheckCircle2,
  MinusCircle,
  Layers,
  Check,
  Minus,
} from 'lucide-react';

type SortField = 'name' | 'itemCount' | 'created_at';
type SortOrder = 'asc' | 'desc';

export const Categories: React.FC = () => {
  const { categories, foods, deleteCategory, deleteCategories } = useAdmin();
  const { t } = useThemeLanguage();

  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'in_use' | 'empty'>('all');
  const [sortField, setSortField] = useState<SortField>('itemCount');
  const [sortOrder, setSortOrder] = useState<SortOrder>('desc');
  const [currentPage, setCurrentPage] = useState(1);
  const pageSize = 10;
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [isBulkDeleteModalOpen, setIsBulkDeleteModalOpen] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<FoodCategory | null>(null);

  const handleOpenAdd = () => {
    setSelectedCategory(null);
    setIsModalOpen(true);
  };

  const handleEdit = (category: FoodCategory) => {
    setSelectedCategory(category);
    setIsModalOpen(true);
  };

  const handleDelete = async (category: FoodCategory) => {
    const count = foods.filter(
      (f) => f.category === category.name || f.category_id === category.id
    ).length;

    if (count > 0) {
      alert(`Cannot delete category "${category.name}" because it contains ${count} food items.`);
      return;
    }

    if (window.confirm(`${t('confirmDeleteCat')} (${category.name})`)) {
      await deleteCategory(category.id);
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

  const enrichedCategories = useMemo(() => {
    return categories.map((cat) => {
      const count = foods.filter(
        (f) => f.category === cat.name || f.category_id === cat.id
      ).length;
      return {
        ...cat,
        itemCount: count,
      };
    });
  }, [categories, foods]);

  const processedCategories = useMemo(() => {
    return enrichedCategories
      .filter((cat) => {
        const matchesSearch =
          !searchTerm ||
          cat.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
          cat.id.toLowerCase().includes(searchTerm.toLowerCase());

        if (!matchesSearch) return false;

        if (filterType === 'in_use') return cat.itemCount > 0;
        if (filterType === 'empty') return cat.itemCount === 0;
        return true;
      })
      .sort((a, b) => {
        let comparison = 0;
        if (sortField === 'name') {
          comparison = a.name.localeCompare(b.name);
        } else if (sortField === 'itemCount') {
          comparison = a.itemCount - b.itemCount;
        } else if (sortField === 'created_at') {
          comparison = (a.created_at || '').localeCompare(b.created_at || '');
        }
        return sortOrder === 'asc' ? comparison : -comparison;
      });
  }, [enrichedCategories, searchTerm, filterType, sortField, sortOrder]);

  const totalEntries = processedCategories.length;
  const totalPages = Math.max(1, Math.ceil(totalEntries / pageSize));
  const validCurrentPage = Math.min(currentPage, totalPages);

  const paginatedCategories = useMemo(() => {
    const startIndex = (validCurrentPage - 1) * pageSize;
    return processedCategories.slice(startIndex, startIndex + pageSize);
  }, [processedCategories, validCurrentPage, pageSize]);

  const paginatedIds = useMemo(() => paginatedCategories.map((c) => c.id), [paginatedCategories]);
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

  const selectedCategoriesForModal = useMemo(() => {
    return enrichedCategories.filter((c) => selectedIds.includes(c.id));
  }, [enrichedCategories, selectedIds]);

  const handleConfirmBulkDelete = async (categoryIdsToDelete: string[]) => {
    await deleteCategories(categoryIdsToDelete);
    setSelectedIds((prev) => prev.filter((id) => !categoryIdsToDelete.includes(id)));
  };

  const totalInUse = enrichedCategories.filter((c) => c.itemCount > 0).length;
  const totalEmpty = enrichedCategories.filter((c) => c.itemCount === 0).length;

  return (
    <div className="space-y-6 animate-fade-in font-sans pb-12">
      {/* ── HEADER ─────────────────────────────────────────────────── */}
      <AdminHeader
        title={t('taxonomyPageTitle')}
        subtitle={t('taxonomyPageSubtitle')}
        actionLabel={t('createNewCategory')}
        onAction={handleOpenAdd}
        showSearch={false}
      />

      {/* ── 4 STAT CARDS ────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5 sm:gap-4">
        {/* Card 1: Total Categories */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#B8FF3B] text-[#0C2417]">
            <Folder className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {categories.length}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('totalCategories')}
          </span>
        </div>

        {/* Card 2: In Use */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-emerald-600 dark:text-emerald-400">
            <CheckCircle2 className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {totalInUse}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('inUseLabel')}
          </span>
        </div>

        {/* Card 3: Empty */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-gray-500 dark:text-gray-400">
            <MinusCircle className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {totalEmpty}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('emptyLabel')}
          </span>
        </div>

        {/* Card 4: Total Classified Foods */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-[#111111] dark:text-[#E2E8DF]">
            <Layers className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {foods.length}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('catalogItems')}
          </span>
        </div>
      </div>

      {/* ── TOOLBAR: SEARCH & STATUS FILTER ─────────────────────────── */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
        {/* Status Filter Pills */}
        <div className="flex items-center space-x-2">
          <button
            onClick={() => {
              setFilterType('all');
              setCurrentPage(1);
            }}
            className={`px-4 py-2 text-sm font-semibold rounded-full transition-all cursor-pointer ${
              filterType === 'all'
                ? 'bg-[#B8FF3B] text-[#0C2417] font-bold shadow-2xs'
                : 'bg-white dark:bg-[#181E19] text-stone-600 dark:text-stone-400 border border-[#EAECE8] dark:border-[#263226] hover:text-[#111111] dark:hover:text-white'
            }`}
          >
            {t('all')}
          </button>
          <button
            onClick={() => {
              setFilterType('in_use');
              setCurrentPage(1);
            }}
            className={`px-4 py-2 text-sm font-semibold rounded-full transition-all cursor-pointer ${
              filterType === 'in_use'
                ? 'bg-[#B8FF3B] text-[#0C2417] font-bold shadow-2xs'
                : 'bg-white dark:bg-[#181E19] text-stone-600 dark:text-stone-400 border border-[#EAECE8] dark:border-[#263226] hover:text-[#111111] dark:hover:text-white'
            }`}
          >
            {t('inUseLabel')}
          </button>
          <button
            onClick={() => {
              setFilterType('empty');
              setCurrentPage(1);
            }}
            className={`px-4 py-2 text-sm font-semibold rounded-full transition-all cursor-pointer ${
              filterType === 'empty'
                ? 'bg-[#B8FF3B] text-[#0C2417] font-bold shadow-2xs'
                : 'bg-white dark:bg-[#181E19] text-stone-600 dark:text-stone-400 border border-[#EAECE8] dark:border-[#263226] hover:text-[#111111] dark:hover:text-white'
            }`}
          >
            {t('emptyLabel')}
          </button>
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
            className="bg-white dark:bg-[#181E19] border border-[#EAECE8] dark:border-[#263226] text-sm text-[#111111] dark:text-[#F3F5EF] placeholder-stone-500 dark:placeholder-stone-400 rounded-full pl-10 pr-8 py-2.5 focus:outline-none focus:ring-1 focus:ring-[#B8FF3B] w-full sm:w-72 transition-colors shadow-2xs"
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

      {/* ── TABLE CONTAINER ─────────────────────────────────────────── */}
      <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] border border-[#EAEFE8] dark:border-[#212E23] shadow-xs overflow-hidden transition-colors duration-200">
        <div className="p-4.5 sm:px-6 border-b border-[#F2F5F0] dark:border-[#202C22] flex items-center justify-between text-sm text-stone-500 dark:text-stone-400">
          <span className="font-bold text-[#111111] dark:text-[#F3F5EF]">
            {totalEntries} {t('taxonomy')}
          </span>
          <button
            onClick={handleOpenAdd}
            className="text-sm font-bold text-[#16A34A] dark:text-[#B8FF3B] hover:underline cursor-pointer flex items-center space-x-1.5"
          >
            <Plus className="w-3.5 h-3.5 stroke-[2.2]" />
            <span>{t('createNewCategory')}</span>
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
                onClick={() => setIsBulkDeleteModalOpen(true)}
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

        {paginatedCategories.length === 0 ? (
          <div className="py-16 text-center">
            <Folder className="w-8 h-8 text-gray-300 dark:text-gray-600 mx-auto mb-2 stroke-[1.5]" />
            <p className="text-sm font-bold text-[#111111] dark:text-[#F3F5EF]">
              No categories found
            </p>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
              Try adjusting your search or filter.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto scrollbar-wide">
            <table className="w-full text-left border-collapse text-sm min-w-[620px]">
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
                      <span>{t('categoryName')}</span>
                      {sortField === 'name' ? (
                        sortOrder === 'asc' ? <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" /> : <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" />
                      ) : (
                        <ChevronsUpDown className="w-3.5 h-3.5 opacity-40 stroke-[2]" />
                      )}
                    </div>
                  </th>
                  <th
                    onClick={() => handleSort('itemCount')}
                    className="py-3.5 px-4 cursor-pointer hover:text-black dark:hover:text-white select-none transition-colors"
                  >
                    <div className="flex items-center space-x-1">
                      <span>{t('catalogItems')}</span>
                      {sortField === 'itemCount' ? (
                        sortOrder === 'asc' ? <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" /> : <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" />
                      ) : (
                        <ChevronsUpDown className="w-3.5 h-3.5 opacity-40 stroke-[2]" />
                      )}
                    </div>
                  </th>
                  <th className="py-3.5 px-4">{t('status')}</th>
                  <th className="py-3.5 px-4 text-center w-20">{t('action')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#F2F5F0] dark:divide-[#202C22]">
                {paginatedCategories.map((cat) => {
                  const isChecked = selectedIds.includes(cat.id);
                  const isInUse = cat.itemCount > 0;

                  return (
                    <tr
                      key={cat.id}
                      className={`hover:bg-[#F9FBF8] dark:hover:bg-[#19241D] transition-colors group ${
                        isChecked ? 'bg-green-50/30 dark:bg-[#18231B]/50' : ''
                      }`}
                    >
                      <td className="py-3.5 px-4 text-center">
                        <button
                          onClick={() => toggleSelect(cat.id)}
                          aria-label={`Select ${cat.name}`}
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
                        {cat.name}
                      </td>

                      <td className="py-3.5 px-4 font-bold text-sm text-[#111111] dark:text-white">
                        {cat.itemCount}
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${
                            isInUse
                              ? 'bg-emerald-50 dark:bg-[#14331C] text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-[#234B2D]'
                              : 'bg-gray-100 dark:bg-[#202A22] text-stone-600 dark:text-stone-400 border border-stone-200 dark:border-[#2E3B30]'
                          }`}
                        >
                          {isInUse ? t('inUseLabel') : t('emptyLabel')}
                        </span>
                      </td>

                      <td className="py-3.5 px-4 text-center">
                        <div className="flex items-center justify-center space-x-1">
                          <button
                            onClick={() => handleEdit(cat)}
                            title={t('edit')}
                            className="w-8 h-8 rounded-lg hover:bg-gray-100 dark:hover:bg-[#253628] flex items-center justify-center text-stone-400 hover:text-stone-700 dark:hover:text-white transition-colors cursor-pointer"
                          >
                            <Pencil className="w-4 h-4 stroke-[1.8]" />
                          </button>
                          <button
                            onClick={() => handleDelete(cat)}
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

      {/* Category Modal */}
      <CategoryModal
        isOpen={isModalOpen}
        categoryToEdit={selectedCategory}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedCategory(null);
        }}
      />

      {/* Bulk Delete Category Modal */}
      <BulkDeleteCategoryModal
        isOpen={isBulkDeleteModalOpen}
        selectedCategories={selectedCategoriesForModal}
        onClose={() => setIsBulkDeleteModalOpen(false)}
        onConfirm={handleConfirmBulkDelete}
      />
    </div>
  );
};
