import React, { useState, useMemo } from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { FoodRequest } from '../../types';
import { BulkRejectRequestModal } from '../modals/BulkRejectRequestModal';
import {
  Inbox,
  CheckCircle2,
  XCircle,
  Search,
  ChevronUp,
  ChevronDown,
  ChevronsUpDown,
  ChevronLeft,
  ChevronRight,
  X,
  Eye,
  Check,
  Minus,
  Trash2,
} from 'lucide-react';
import { formatTimeAgo } from '../../lib/utils';

interface ModerationQueueTableProps {
  onOpenRequestModal?: (req: FoodRequest) => void;
  isFullPage?: boolean;
}

type SortField = 'food_name' | 'user_id' | 'calories' | 'status' | 'created_at';
type SortOrder = 'asc' | 'desc';

export const ModerationQueueTable: React.FC<ModerationQueueTableProps> = ({
  onOpenRequestModal,
  isFullPage = false,
}) => {
  const { requests, approveRequest, rejectRequest, approveRequests, rejectRequests, deleteRequests, users } = useAdmin();
  const { t } = useThemeLanguage();

  const getSubmitterDisplayName = (req: FoodRequest) => {
    if (req.submitter_name && req.submitter_name !== 'Community Member') {
      return req.submitter_name;
    }
    const matched = users.find((u) => u.id === req.user_id);
    if (matched?.name) return matched.name;
    return req.submitter_name || 'Calora User';
  };

  const getSubmitterAvatar = (req: FoodRequest) => {
    if (req.submitter_avatar) return req.submitter_avatar;
    const matched = users.find((u) => u.id === req.user_id);
    return matched?.avatar_url;
  };

  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [isBulkRejectModalOpen, setIsBulkRejectModalOpen] = useState<boolean>(false);

  // 1. SEARCHING STATE
  const [searchTerm, setSearchTerm] = useState('');

  // 2. FILTERING STATE
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');

  // 3. SORTING STATE
  const [sortField, setSortField] = useState<SortField>('created_at');
  const [sortOrder, setSortOrder] = useState<SortOrder>('desc');

  // 4. PAGINATION STATE
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(isFullPage ? 8 : 5);

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('asc');
    }
  };

  // Distinct categories from requests
  const categoriesList = useMemo(() => {
    const cats = new Set<string>();
    requests.forEach((r) => {
      const cat = r.category || r.category_name;
      if (cat) cats.add(cat);
    });
    return Array.from(cats);
  }, [requests]);

  // Counts for status tabs
  const pendingCount = useMemo(() => requests.filter((r) => r.status === 'pending').length, [requests]);
  const approvedCount = useMemo(() => requests.filter((r) => r.status === 'approved').length, [requests]);
  const rejectedCount = useMemo(() => requests.filter((r) => r.status === 'rejected').length, [requests]);

  // Processed requests (Search, Filter, Sort)
  const processedRequests = useMemo(() => {
    return requests
      .filter((req) => {
        const q = searchTerm.toLowerCase().trim();
        const matchesSearch =
          !q ||
          req.food_name.toLowerCase().includes(q) ||
          (req.submitter_name && req.submitter_name.toLowerCase().includes(q)) ||
          req.user_id.toLowerCase().includes(q) ||
          (req.category && req.category.toLowerCase().includes(q));

        const matchesStatus =
          statusFilter === 'all' ? true : req.status === statusFilter;

        const reqCategory = req.category || req.category_name;
        const matchesCategory =
          categoryFilter === 'all' ? true : reqCategory === categoryFilter;

        return matchesSearch && matchesStatus && matchesCategory;
      })
      .sort((a, b) => {
        let comparison = 0;
        if (sortField === 'food_name') {
          comparison = a.food_name.localeCompare(b.food_name);
        } else if (sortField === 'user_id') {
          const nameA = a.submitter_name || a.user_id;
          const nameB = b.submitter_name || b.user_id;
          comparison = nameA.localeCompare(nameB);
        } else if (sortField === 'calories') {
          comparison = a.calories - b.calories;
        } else if (sortField === 'status') {
          comparison = a.status.localeCompare(b.status);
        } else if (sortField === 'created_at') {
          comparison = new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
        }
        return sortOrder === 'asc' ? comparison : -comparison;
      });
  }, [requests, searchTerm, statusFilter, categoryFilter, sortField, sortOrder]);

  // Pagination bounds
  const totalEntries = processedRequests.length;
  const totalPages = Math.max(1, Math.ceil(totalEntries / pageSize));
  const validCurrentPage = Math.min(currentPage, totalPages);

  const paginatedRequests = useMemo(() => {
    const startIndex = (validCurrentPage - 1) * pageSize;
    return processedRequests.slice(startIndex, startIndex + pageSize);
  }, [processedRequests, validCurrentPage, pageSize]);

  const paginatedIds = useMemo(() => paginatedRequests.map((r) => r.id), [paginatedRequests]);
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

  const selectedRequests = useMemo(() => {
    return requests.filter((r) => selectedIds.includes(r.id));
  }, [requests, selectedIds]);

  const pendingSelectedCount = selectedRequests.filter((r) => r.status === 'pending').length;

  const handleBulkApprove = async () => {
    const pendingIds = selectedRequests.filter((r) => r.status === 'pending').map((r) => r.id);
    if (pendingIds.length === 0) return;
    await approveRequests(pendingIds);
    setSelectedIds([]);
  };

  const handleConfirmBulkReject = async (reason: string) => {
    await rejectRequests(selectedIds, reason);
    setSelectedIds([]);
  };

  const handleBulkDelete = async () => {
    if (window.confirm(`Hapus ${selectedIds.length} pengajuan dari database?`)) {
      await deleteRequests(selectedIds);
      setSelectedIds([]);
    }
  };

  return (
    <div className="bg-white dark:bg-[#181E19] rounded-2xl border border-[#EAECE8] dark:border-[#263226] shadow-xs overflow-hidden transition-colors duration-200">
      {/* ── TOOLBAR: SEARCH & FILTER CONTROLS ───────────────────────── */}
      <div className="p-5 border-b border-[#EAECE8] dark:border-[#222D23] flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <div className="flex items-center space-x-2">
            <h3 className="text-base font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
              {t('recentSubmissions')}
            </h3>
            {pendingCount > 0 && (
              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 dark:bg-amber-950/60 text-amber-800 dark:text-amber-400 border border-amber-200 dark:border-amber-800">
                {pendingCount} Pending
              </span>
            )}
          </div>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
            {t('submissionsSubtitle')}
          </p>
        </div>

        {/* Toolbar interactive filters */}
        <div className="flex items-center flex-wrap gap-2.5">
          {/* 1. SEARCH INPUT */}
          <div className="relative">
            <Search className="w-3.5 h-3.5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" strokeWidth={1.8} />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              placeholder="Search dishes or users..."
              className="bg-gray-50 dark:bg-[#202820] border border-gray-200 dark:border-[#2D382D] text-xs text-[#111111] dark:text-[#F3F5EF] placeholder-gray-400 rounded-xl pl-8 pr-7 py-1.5 focus:outline-none focus:ring-1 focus:ring-[#74D100] w-48 transition-colors"
            />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-white"
              >
                <X className="w-3 h-3" strokeWidth={1.8} />
              </button>
            )}
          </div>

          {/* CATEGORY FILTER */}
          {categoriesList.length > 0 && (
            <select
              value={categoryFilter}
              onChange={(e) => {
                setCategoryFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="bg-gray-50 dark:bg-[#202820] border border-gray-200 dark:border-[#2D382D] rounded-xl px-2.5 py-1.5 text-xs text-gray-700 dark:text-gray-300 focus:outline-none cursor-pointer"
            >
              <option value="all">All Categories</option>
              {categoriesList.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          )}

          {/* 2. STATUS TABS */}
          <div className="flex items-center space-x-1 p-0.5 bg-gray-100 dark:bg-[#202820] rounded-xl border border-gray-200 dark:border-[#2D382D] overflow-x-auto text-xs font-semibold">
            <button
              onClick={() => {
                setStatusFilter('all');
                setCurrentPage(1);
              }}
              className={`px-3 py-1 rounded-lg transition-all cursor-pointer ${
                statusFilter === 'all'
                  ? 'bg-white dark:bg-[#181E19] text-[#111111] dark:text-[#F3F5EF] shadow-2xs font-extrabold'
                  : 'text-gray-500 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              {t('allTab')} ({requests.length})
            </button>
            <button
              onClick={() => {
                setStatusFilter('pending');
                setCurrentPage(1);
              }}
              className={`px-3 py-1 rounded-lg transition-all cursor-pointer ${
                statusFilter === 'pending'
                  ? 'bg-amber-500 text-white shadow-2xs font-extrabold'
                  : 'text-gray-500 hover:text-amber-600'
              }`}
            >
              {t('pendingTab')} ({pendingCount})
            </button>
            <button
              onClick={() => {
                setStatusFilter('approved');
                setCurrentPage(1);
              }}
              className={`px-3 py-1 rounded-lg transition-all cursor-pointer ${
                statusFilter === 'approved'
                  ? 'bg-[#16A34A] dark:bg-[#3DDC84] text-white dark:text-[#0C2417] shadow-2xs font-extrabold'
                  : 'text-gray-500 hover:text-[#16A34A]'
              }`}
            >
              {t('approvedTab')} ({approvedCount})
            </button>
            <button
              onClick={() => {
                setStatusFilter('rejected');
                setCurrentPage(1);
              }}
              className={`px-3 py-1 rounded-lg transition-all cursor-pointer ${
                statusFilter === 'rejected'
                  ? 'bg-[#FF5A5F] text-white shadow-2xs font-extrabold'
                  : 'text-gray-500 hover:text-[#FF5A5F]'
              }`}
            >
              {t('rejectedTab')} ({rejectedCount})
            </button>
          </div>
        </div>
      </div>

      {/* ── BULK ACTION BAR ───────────────────────────────────────── */}
      {selectedIds.length > 0 && (
        <div className="p-3 mx-4 my-3 bg-red-50/80 dark:bg-red-950/30 border border-red-200 dark:border-red-900/50 rounded-xl flex items-center justify-between flex-wrap gap-2 animate-in fade-in slide-in-from-top-1 duration-150">
          <div className="flex items-center space-x-2">
            <span className="w-5 h-5 rounded-full bg-red-600 text-white text-[11px] font-bold flex items-center justify-center">
              {selectedIds.length}
            </span>
            <span className="text-xs font-semibold text-red-900 dark:text-red-200">
              {selectedIds.length} {t('itemsSelected')}
            </span>
          </div>

          <div className="flex items-center space-x-2 flex-wrap gap-y-1">
            {pendingSelectedCount > 0 && (
              <>
                <button
                  onClick={handleBulkApprove}
                  className="px-3 py-1.5 rounded-lg bg-[#16A34A] hover:bg-emerald-700 active:scale-95 text-white text-xs font-bold flex items-center space-x-1.5 transition-all shadow-2xs cursor-pointer"
                >
                  <CheckCircle2 className="w-3.5 h-3.5 stroke-[2]" />
                  <span>{t('bulkApprove')} ({pendingSelectedCount})</span>
                </button>
                <button
                  onClick={() => setIsBulkRejectModalOpen(true)}
                  className="px-3 py-1.5 rounded-lg bg-amber-600 hover:bg-amber-700 active:scale-95 text-white text-xs font-bold flex items-center space-x-1.5 transition-all shadow-2xs cursor-pointer"
                >
                  <XCircle className="w-3.5 h-3.5 stroke-[2]" />
                  <span>{t('bulkReject')}</span>
                </button>
              </>
            )}
            <button
              onClick={handleBulkDelete}
              className="px-3 py-1.5 rounded-lg bg-red-600 hover:bg-red-700 active:scale-95 text-white text-xs font-bold flex items-center space-x-1.5 transition-all shadow-2xs cursor-pointer"
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

      {/* ── TABLE CONTENT (NUMBERING & SORTING) ──────────────────────── */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse text-xs font-medium">
          <thead>
            <tr className="border-b border-[#EAECE8] dark:border-[#222D23] text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider bg-gray-50/50 dark:bg-[#151C16]">
              {/* Checkbox Header */}
              <th className="py-3 px-4 w-10 text-center">
                <button
                  onClick={toggleSelectAll}
                  aria-label="Select all requests on this page"
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

              {/* FOOD ITEM */}
              <th
                onClick={() => handleSort('food_name')}
                className="py-3 px-4 cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none transition-colors"
              >
                <div className="flex items-center space-x-1">
                  <span>{t('foodItem')}</span>
                  {sortField === 'food_name' ? (
                    sortOrder === 'asc' ? (
                      <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" strokeWidth={1.8} />
                    ) : (
                      <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" strokeWidth={1.8} />
                    )
                  ) : (
                    <ChevronsUpDown className="w-3.5 h-3.5 opacity-30" strokeWidth={1.8} />
                  )}
                </div>
              </th>

              {/* SUBMITTED BY */}
              <th
                onClick={() => handleSort('user_id')}
                className="py-3 px-4 cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none transition-colors"
              >
                <div className="flex items-center space-x-1">
                  <span>{t('submittedBy')}</span>
                  {sortField === 'user_id' ? (
                    sortOrder === 'asc' ? (
                      <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" strokeWidth={1.8} />
                    ) : (
                      <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" strokeWidth={1.8} />
                    )
                  ) : (
                    <ChevronsUpDown className="w-3.5 h-3.5 opacity-30" strokeWidth={1.8} />
                  )}
                </div>
              </th>

              {/* CALORIES & MACROS */}
              <th
                onClick={() => handleSort('calories')}
                className="py-3 px-4 cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none transition-colors"
              >
                <div className="flex items-center space-x-1">
                  <span>{t('caloriesMacros')}</span>
                  {sortField === 'calories' ? (
                    sortOrder === 'asc' ? (
                      <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" strokeWidth={1.8} />
                    ) : (
                      <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" strokeWidth={1.8} />
                    )
                  ) : (
                    <ChevronsUpDown className="w-3.5 h-3.5 opacity-30" strokeWidth={1.8} />
                  )}
                </div>
              </th>

              {/* SUBMITTED DATE */}
              <th
                onClick={() => handleSort('created_at')}
                className="py-3 px-4 cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none transition-colors"
              >
                <div className="flex items-center space-x-1">
                  <span>{t('dateCol')}</span>
                  {sortField === 'created_at' ? (
                    sortOrder === 'asc' ? (
                      <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" strokeWidth={1.8} />
                    ) : (
                      <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" strokeWidth={1.8} />
                    )
                  ) : (
                    <ChevronsUpDown className="w-3.5 h-3.5 opacity-30" strokeWidth={1.8} />
                  )}
                </div>
              </th>

              {/* STATUS */}
              <th
                onClick={() => handleSort('status')}
                className="py-3 px-4 cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none transition-colors"
              >
                <div className="flex items-center space-x-1">
                  <span>{t('status')}</span>
                  {sortField === 'status' ? (
                    sortOrder === 'asc' ? (
                      <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" strokeWidth={1.8} />
                    ) : (
                      <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" strokeWidth={1.8} />
                    )
                  ) : (
                    <ChevronsUpDown className="w-3.5 h-3.5 opacity-30" strokeWidth={1.8} />
                  )}
                </div>
              </th>

              {/* ACTIONS */}
              <th className="py-3 px-4 text-right">{t('actionCol')}</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-[#EAECE8] dark:divide-[#222D23]">
            {paginatedRequests.length === 0 ? (
              <tr>
                <td colSpan={7} className="py-12 text-center text-gray-400">
                  <div className="flex flex-col items-center justify-center space-y-2">
                    <Inbox className="w-8 h-8 opacity-40 text-gray-400" strokeWidth={1.8} />
                    <p className="font-semibold text-xs text-[#111111] dark:text-[#F3F5EF]">
                      {t('noRequestsFound')}
                    </p>
                    <p className="text-[11px] text-gray-400">
                      {t('noRequestsFilterHelp')}
                    </p>
                  </div>
                </td>
              </tr>
            ) : (
              paginatedRequests.map((req) => {
                const isChecked = selectedIds.includes(req.id);

                return (
                  <tr
                    key={req.id}
                    className={`hover:bg-gray-50/70 dark:hover:bg-[#202820] transition-colors ${
                      isChecked ? 'bg-green-50/30 dark:bg-[#18231B]/50' : ''
                    }`}
                  >
                    {/* CHECKBOX CELL */}
                    <td className="py-3.5 px-4 text-center">
                      <button
                        onClick={() => toggleSelect(req.id)}
                        aria-label={`Select ${req.food_name}`}
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

                    {/* FOOD ITEM */}
                    <td className="py-3.5 px-4">
                      <div>
                        <p className="font-bold text-[#111111] dark:text-[#F3F5EF] leading-tight">
                          {req.food_name}
                        </p>
                        <div className="flex items-center space-x-1.5 text-[10px] text-gray-400 dark:text-gray-500 mt-0.5">
                          <span>{req.serving_label}</span>
                          {(req.category || req.category_name) && (
                            <>
                              <span>•</span>
                              <span className="text-gray-500 dark:text-gray-400">
                                {req.category || req.category_name}
                              </span>
                            </>
                          )}
                        </div>
                      </div>
                    </td>

                    {/* SUBMITTED BY */}
                    <td className="py-3.5 px-4 text-[#111111] dark:text-[#F3F5EF]">
                      <div className="flex items-center space-x-2.5">
                        <div className="relative w-6 h-6 rounded-full flex items-center justify-center font-bold text-[10px] shrink-0 bg-emerald-50 dark:bg-[#14331C] text-[#16A34A] dark:text-[#3DDC84] overflow-hidden">
                          {getSubmitterAvatar(req) ? (
                            <img
                              src={getSubmitterAvatar(req)}
                              alt={getSubmitterDisplayName(req)}
                              className="w-full h-full object-cover rounded-full absolute inset-0"
                              onError={(e) => {
                                (e.currentTarget as HTMLElement).style.display = 'none';
                              }}
                            />
                          ) : null}
                          <span>{getSubmitterDisplayName(req)?.[0]?.toUpperCase() || 'U'}</span>
                        </div>
                        <div>
                          <div className="font-semibold text-xs leading-tight">
                            {getSubmitterDisplayName(req)}
                          </div>
                          <div className="text-[10px] text-gray-400">
                            {req.submitter_name && req.submitter_name !== 'Community Member' ? 'Verified Member' : 'Mobile User'}
                          </div>
                        </div>
                      </div>
                    </td>

                    {/* CALORIES & MACROS */}
                    <td className="py-3.5 px-4">
                      <div className="font-black text-[#111111] dark:text-[#F3F5EF]">
                        {req.calories} kcal
                      </div>
                      <div className="flex items-center space-x-2 text-[10px] text-gray-400 mt-0.5 font-medium">
                        <span className="text-[#FF6B57]">{req.protein_g}g P</span>
                        <span className="text-[#FFC24B]">{req.carbs_g}g C</span>
                        <span className="text-[#7C9CFF]">{req.fat_g}g F</span>
                      </div>
                    </td>

                    {/* DATE */}
                    <td className="py-3.5 px-4 text-gray-400 dark:text-gray-500 text-[11px]">
                      {formatTimeAgo(req.created_at)}
                    </td>

                    {/* STATUS */}
                    <td className="py-3.5 px-4">
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold capitalize ${
                          req.status === 'approved'
                            ? 'bg-emerald-50 dark:bg-[#14331C] text-[#16A34A] dark:text-[#3DDC84] border border-emerald-200 dark:border-[#234B2D]'
                            : req.status === 'pending'
                            ? 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-800'
                            : 'bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400 border border-red-200 dark:border-red-900'
                        }`}
                      >
                        {req.status}
                      </span>
                    </td>

                    {/* ACTIONS */}
                    <td className="py-3.5 px-4 text-right">
                      <div className="flex items-center justify-end space-x-1.5">
                        {req.status === 'pending' && (
                          <>
                            <button
                              onClick={() => approveRequest(req.id)}
                              title="Approve submission"
                              className="w-7 h-7 rounded-lg bg-emerald-50 dark:bg-[#14331C] text-[#16A34A] dark:text-[#3DDC84] hover:bg-emerald-100 dark:hover:bg-[#1C4627] flex items-center justify-center transition-colors cursor-pointer"
                            >
                              <CheckCircle2 className="w-4 h-4" strokeWidth={1.8} />
                            </button>
                            <button
                              onClick={() => rejectRequest(req.id, 'Nutritional data incomplete')}
                              title="Reject submission"
                              className="w-7 h-7 rounded-lg bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/60 flex items-center justify-center transition-colors cursor-pointer"
                            >
                              <XCircle className="w-4 h-4" strokeWidth={1.8} />
                            </button>
                          </>
                        )}
                        {onOpenRequestModal && (
                          <button
                            onClick={() => onOpenRequestModal(req)}
                            title="View details"
                            className="w-7 h-7 rounded-lg bg-gray-100 dark:bg-[#253026] text-gray-600 dark:text-gray-300 hover:text-[#16A34A] dark:hover:text-[#B8FF3B] flex items-center justify-center transition-colors cursor-pointer"
                          >
                            <Eye className="w-4 h-4" strokeWidth={1.8} />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* ── PAGINATION CONTROLS ───────────────────────────────────── */}
      <div className="p-4 border-t border-[#EAECE8] dark:border-[#222D23] flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-gray-500 dark:text-gray-400">
        <div>
          {t('showingText')}{' '}
          <span className="font-bold text-[#111111] dark:text-[#F3F5EF]">
            {totalEntries === 0 ? 0 : (validCurrentPage - 1) * pageSize + 1}
          </span>{' '}
          {t('toText')}{' '}
          <span className="font-bold text-[#111111] dark:text-[#F3F5EF]">
            {Math.min(validCurrentPage * pageSize, totalEntries)}
          </span>{' '}
          {t('ofText')}{' '}
          <span className="font-bold text-[#111111] dark:text-[#F3F5EF]">
            {totalEntries}
          </span>{' '}
          {t('entriesText')}
        </div>

        <div className="flex items-center space-x-3">
          <div className="flex items-center space-x-1">
            <span className="text-[11px]">{t('rowsText')}</span>
            <select
              value={pageSize}
              onChange={(e) => {
                setPageSize(Number(e.target.value));
                setCurrentPage(1);
              }}
              className="bg-gray-50 dark:bg-[#202820] border border-gray-200 dark:border-[#2D382D] rounded-lg px-2 py-1 text-xs text-gray-700 dark:text-gray-300 focus:outline-none cursor-pointer"
            >
              <option value={3}>3</option>
              <option value={5}>5</option>
              <option value={10}>10</option>
              <option value={20}>20</option>
            </select>
          </div>

          <div className="flex items-center space-x-1">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={validCurrentPage <= 1}
              className="w-7 h-7 rounded-lg border border-gray-200 dark:border-[#2D382D] flex items-center justify-center text-gray-500 hover:text-gray-900 dark:hover:text-white disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft className="w-3.5 h-3.5" strokeWidth={1.8} />
            </button>

            {Array.from({ length: totalPages }, (_, i) => i + 1)
              .slice(
                Math.max(0, validCurrentPage - 2),
                Math.min(totalPages, validCurrentPage + 1)
              )
              .map((pageNum) => (
                <button
                  key={pageNum}
                  onClick={() => setCurrentPage(pageNum)}
                  className={`w-7 h-7 rounded-lg text-xs font-bold transition-colors cursor-pointer ${
                    validCurrentPage === pageNum
                      ? 'bg-[#B8FF3B] text-[#0C2417] shadow-2xs font-extrabold'
                      : 'hover:bg-gray-100 dark:hover:bg-[#202820] text-gray-600 dark:text-gray-400'
                  }`}
                >
                  {pageNum}
                </button>
              ))}

            <button
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              disabled={validCurrentPage >= totalPages}
              className="w-7 h-7 rounded-lg border border-gray-200 dark:border-[#2D382D] flex items-center justify-center text-gray-500 hover:text-gray-900 dark:hover:text-white disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronRight className="w-3.5 h-3.5" strokeWidth={1.8} />
            </button>
          </div>
        </div>
      </div>

      {/* Bulk Reject Modal */}
      <BulkRejectRequestModal
        isOpen={isBulkRejectModalOpen}
        count={selectedIds.length}
        onClose={() => setIsBulkRejectModalOpen(false)}
        onConfirm={handleConfirmBulkReject}
      />
    </div>
  );
};
