import React, { useState, useMemo } from 'react';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { FoodRequest } from '../../types';
import {
  RiInboxArchiveFill,
  RiCheckFill,
  RiCloseFill,
  RiArrowRightLine,
  RiSearchLine,
  RiArrowUpSFill,
  RiArrowDownSFill,
  RiArrowUpDownLine,
  RiArrowLeftSLine,
  RiArrowRightSLine,
  RiCloseLine,
  RiEyeFill,
} from 'react-icons/ri';
import { Link } from 'react-router-dom';
import { formatTimeAgo } from '../../lib/utils';

interface CustomerListTableProps {
  onOpenRequestModal?: (req: FoodRequest) => void;
}

type SortField = 'food_name' | 'user_id' | 'calories' | 'status' | 'created_at';
type SortOrder = 'asc' | 'desc';

export const CustomerListTable: React.FC<CustomerListTableProps> = ({
  onOpenRequestModal,
}) => {
  const { requests, approveRequest, rejectRequest, stats, users } = useAdmin();
  const { t } = useThemeLanguage();

  const getSubmitterDisplayName = (req: FoodRequest) => {
    if (req.submitter_name && req.submitter_name !== 'Community Member') {
      return req.submitter_name;
    }
    const matched = users.find((u) => u.id === req.user_id);
    if (matched?.name) return matched.name;
    return req.submitter_name || 'Calora User';
  };

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
  const [pageSize, setPageSize] = useState(5);

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('asc');
    }
  };

  // Distinct categories
  const categoriesList = useMemo(() => {
    const cats = new Set<string>();
    requests.forEach((r) => {
      if (r.category) cats.add(r.category);
    });
    return Array.from(cats);
  }, [requests]);

  // Filtered & Sorted items
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

        const matchesCategory =
          categoryFilter === 'all' ? true : req.category === categoryFilter;

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

  return (
    <div className="bg-white dark:bg-[#181E19] rounded-2xl border border-[#EAECE8] dark:border-[#263226] shadow-xs overflow-hidden transition-colors duration-200">
      {/* ── TABLE HEADER: TOOLBAR (SEARCHING & FILTERING) ──────────── */}
      <div className="p-5 border-b border-[#EAECE8] dark:border-[#222D23] flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <div className="flex items-center space-x-2">
            <h3 className="text-base font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight">
              {t('recentSubmissions')}
            </h3>
            {stats.pendingRequests > 0 && (
              <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-amber-100 dark:bg-amber-950/60 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-800">
                {stats.pendingRequests} Pending
              </span>
            )}
          </div>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
            {t('submissionsSubtitle')}
          </p>
        </div>

        {/* Toolbar Controls */}
        <div className="flex items-center flex-wrap gap-2.5">
          {/* 1. SEARCHING INPUT */}
          <div className="relative">
            <RiSearchLine className="w-3.5 h-3.5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              placeholder="Search dishes, users..."
              className="bg-gray-50 dark:bg-[#202820] border border-gray-200 dark:border-[#2D382D] text-xs text-[#111111] dark:text-[#F3F5EF] placeholder-gray-400 rounded-xl pl-8 pr-7 py-1.5 focus:outline-none focus:ring-1 focus:ring-[#74D100] w-48 transition-colors"
            />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-white"
              >
                <RiCloseLine className="w-3.5 h-3.5" />
              </button>
            )}
          </div>

          {/* Category Dropdown Filter */}
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

          {/* 2. STATUS FILTERING PILLS */}
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
              {t('allTab')}
            </button>
            <button
              onClick={() => {
                setStatusFilter('pending');
                setCurrentPage(1);
              }}
              className={`px-3 py-1 rounded-lg transition-all cursor-pointer ${
                statusFilter === 'pending'
                  ? 'bg-amber-500 text-white shadow-2xs font-extrabold'
                  : 'text-gray-500 hover:text-amber-500'
              }`}
            >
              {t('pendingTab')}
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
              {t('approvedTab')}
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
              {t('rejectedTab')}
            </button>
          </div>

          <Link
            to="/food-requests"
            className="text-xs font-bold text-[#16A34A] dark:text-[#B8FF3B] hover:underline flex items-center space-x-1 ml-1"
          >
            <span>{t('viewAll')}</span>
            <RiArrowRightLine className="w-3.5 h-3.5" />
          </Link>
        </div>
      </div>

      {/* ── TABLE CONTENT (NUMBERING & SORTING) ──────────────────────── */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse text-xs font-medium">
          <thead>
            <tr className="border-b border-[#EAECE8] dark:border-[#222D23] text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider bg-gray-50/50 dark:bg-[#151C16]">
              {/* NUMBERING HEADER */}
              <th className="py-3 px-4 w-12 text-center">#</th>

              {/* FOOD ITEM (SORTABLE) */}
              <th
                onClick={() => handleSort('food_name')}
                className="py-3 px-4 cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none transition-colors"
              >
                <div className="flex items-center space-x-1">
                  <span>{t('foodItem')}</span>
                  {sortField === 'food_name' ? (
                    sortOrder === 'asc' ? (
                      <RiArrowUpSFill className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" />
                    ) : (
                      <RiArrowDownSFill className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" />
                    )
                  ) : (
                    <RiArrowUpDownLine className="w-3.5 h-3.5 opacity-30" />
                  )}
                </div>
              </th>

              {/* SUBMITTED BY (SORTABLE) */}
              <th
                onClick={() => handleSort('user_id')}
                className="py-3 px-4 cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none transition-colors"
              >
                <div className="flex items-center space-x-1">
                  <span>{t('submittedBy')}</span>
                  {sortField === 'user_id' ? (
                    sortOrder === 'asc' ? (
                      <RiArrowUpSFill className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" />
                    ) : (
                      <RiArrowDownSFill className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" />
                    )
                  ) : (
                    <RiArrowUpDownLine className="w-3.5 h-3.5 opacity-30" />
                  )}
                </div>
              </th>

              {/* CALORIES & MACROS (SORTABLE) */}
              <th
                onClick={() => handleSort('calories')}
                className="py-3 px-4 cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none transition-colors"
              >
                <div className="flex items-center space-x-1">
                  <span>{t('caloriesMacros')}</span>
                  {sortField === 'calories' ? (
                    sortOrder === 'asc' ? (
                      <RiArrowUpSFill className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" />
                    ) : (
                      <RiArrowDownSFill className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" />
                    )
                  ) : (
                    <RiArrowUpDownLine className="w-3.5 h-3.5 opacity-30" />
                  )}
                </div>
              </th>

              {/* DATE (SORTABLE) */}
              <th
                onClick={() => handleSort('created_at')}
                className="py-3 px-4 cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none transition-colors"
              >
                <div className="flex items-center space-x-1">
                  <span>{t('dateCol')}</span>
                  {sortField === 'created_at' ? (
                    sortOrder === 'asc' ? (
                      <RiArrowUpSFill className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" />
                    ) : (
                      <RiArrowDownSFill className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" />
                    )
                  ) : (
                    <RiArrowUpDownLine className="w-3.5 h-3.5 opacity-30" />
                  )}
                </div>
              </th>

              {/* STATUS (SORTABLE) */}
              <th
                onClick={() => handleSort('status')}
                className="py-3 px-4 cursor-pointer hover:text-gray-700 dark:hover:text-gray-200 select-none transition-colors"
              >
                <div className="flex items-center space-x-1">
                  <span>{t('status')}</span>
                  {sortField === 'status' ? (
                    sortOrder === 'asc' ? (
                      <RiArrowUpSFill className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" />
                    ) : (
                      <RiArrowDownSFill className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B]" />
                    )
                  ) : (
                    <RiArrowUpDownLine className="w-3.5 h-3.5 opacity-30" />
                  )}
                </div>
              </th>

              {/* ACTION */}
              <th className="py-3 px-4 text-right">{t('actionCol')}</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-[#EAECE8] dark:divide-[#222D23]">
            {paginatedRequests.length === 0 ? (
              <tr>
                <td colSpan={7} className="py-10 text-center text-gray-400">
                  <div className="flex flex-col items-center justify-center space-y-2">
                    <RiInboxArchiveFill className="w-8 h-8 opacity-40 text-[#16A34A]" />
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
              paginatedRequests.map((req, index) => {
                // NUMBERING FORMULA (Continuous across pages)
                const continuousNumber = (validCurrentPage - 1) * pageSize + index + 1;

                return (
                  <tr
                    key={req.id}
                    className="hover:bg-gray-50/70 dark:hover:bg-[#202820] transition-colors group"
                  >
                    {/* NUMBERING CELL */}
                    <td className="py-3.5 px-4 text-center font-bold text-gray-400 dark:text-gray-500 text-[11px]">
                      {continuousNumber}
                    </td>

                    {/* FOOD ITEM */}
                    <td className="py-3.5 px-4">
                      <div className="flex items-center space-x-3">
                        <div className="w-9 h-9 rounded-xl overflow-hidden bg-gray-100 dark:bg-[#253026] shrink-0 border border-gray-200 dark:border-[#303E30]">
                          {req.image_url ? (
                            <img
                              src={req.image_url}
                              alt={req.food_name}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center font-bold text-xs text-gray-400">
                              {req.food_name[0]}
                            </div>
                          )}
                        </div>
                        <div>
                          <p className="font-bold text-[#111111] dark:text-[#F3F5EF] leading-tight">
                            {req.food_name}
                          </p>
                          <div className="flex items-center space-x-1.5 text-[10px] text-gray-400 dark:text-gray-500 mt-0.5">
                            <span>{req.serving_size}g ({req.serving_unit || 'portion'})</span>
                            {req.category && (
                              <>
                                <span>•</span>
                                <span className="text-[#16A34A] dark:text-[#3DDC84]">
                                  {req.category}
                                </span>
                              </>
                            )}
                          </div>
                        </div>
                      </div>
                    </td>

                    {/* SUBMITTED BY */}
                    <td className="py-3.5 px-4 text-[#111111] dark:text-[#F3F5EF]">
                      <div className="font-semibold text-xs">
                        {getSubmitterDisplayName(req)}
                      </div>
                      <div className="text-[10px] text-gray-400">
                        {req.submitter_name && req.submitter_name !== 'Community Member' ? 'Verified Member' : 'Mobile User'}
                      </div>
                    </td>

                    {/* CALORIES & MACROS */}
                    <td className="py-3.5 px-4">
                      <div className="font-black text-[#111111] dark:text-[#F3F5EF]">
                        {req.calories} kcal
                      </div>
                      <div className="flex items-center space-x-2 text-[10px] text-gray-400 mt-0.5">
                        <span className="text-[#FF6B57] font-semibold">{req.protein_g}g P</span>
                        <span className="text-[#FFC24B] font-semibold">{req.carbs_g}g C</span>
                        <span className="text-[#7C9CFF] font-semibold">{req.fat_g}g F</span>
                      </div>
                    </td>

                    {/* DATE */}
                    <td className="py-3.5 px-4 text-gray-400 dark:text-gray-500 text-[11px]">
                      {formatTimeAgo(req.created_at)}
                    </td>

                    {/* STATUS */}
                    <td className="py-3.5 px-4">
                      <span
                        className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-extrabold capitalize ${
                          req.status === 'approved'
                            ? 'bg-emerald-100 dark:bg-[#14331C] text-[#16A34A] dark:text-[#3DDC84]'
                            : req.status === 'pending'
                            ? 'bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400'
                            : 'bg-red-100 dark:bg-red-950/60 text-red-600 dark:text-red-400'
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
                              title="Quick Approve"
                              className="w-7 h-7 rounded-lg bg-emerald-50 dark:bg-[#14331C] text-[#16A34A] dark:text-[#3DDC84] hover:bg-emerald-100 dark:hover:bg-[#1C4627] flex items-center justify-center transition-colors cursor-pointer"
                            >
                              <RiCheckFill className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => rejectRequest(req.id, 'Nutritional data incomplete')}
                              title="Quick Reject"
                              className="w-7 h-7 rounded-lg bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/60 flex items-center justify-center transition-colors cursor-pointer"
                            >
                              <RiCloseFill className="w-4 h-4" />
                            </button>
                          </>
                        )}
                        {onOpenRequestModal && (
                          <button
                            onClick={() => onOpenRequestModal(req)}
                            title="View Details"
                            className="w-7 h-7 rounded-lg bg-gray-100 dark:bg-[#253026] text-gray-600 dark:text-gray-300 hover:text-[#16A34A] dark:hover:text-[#B8FF3B] flex items-center justify-center transition-colors cursor-pointer"
                          >
                            <RiEyeFill className="w-3.5 h-3.5" />
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

      {/* ── 4. PAGINATION FOOTER ────────────────────────────────────── */}
      <div className="p-4 border-t border-[#EAECE8] dark:border-[#222D23] flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-gray-500 dark:text-gray-400">
        {/* Entries Count */}
        <div>
          Showing{' '}
          <span className="font-bold text-[#111111] dark:text-[#F3F5EF]">
            {totalEntries === 0 ? 0 : (validCurrentPage - 1) * pageSize + 1}
          </span>{' '}
          to{' '}
          <span className="font-bold text-[#111111] dark:text-[#F3F5EF]">
            {Math.min(validCurrentPage * pageSize, totalEntries)}
          </span>{' '}
          of{' '}
          <span className="font-bold text-[#111111] dark:text-[#F3F5EF]">
            {totalEntries}
          </span>{' '}
          entries
        </div>

        {/* Page Size & Page Navigation */}
        <div className="flex items-center space-x-3">
          {/* Page size selector */}
          <div className="flex items-center space-x-1">
            <span className="text-[11px]">Rows:</span>
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

          {/* Prev / Next & Page pills */}
          <div className="flex items-center space-x-1">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={validCurrentPage <= 1}
              className="w-7 h-7 rounded-lg border border-gray-200 dark:border-[#2D382D] flex items-center justify-center text-gray-500 hover:text-gray-900 dark:hover:text-white disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
            >
              <RiArrowLeftSLine className="w-4 h-4" />
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
                      ? 'bg-[#B8FF3B] text-[#0C2417] shadow-2xs'
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
              <RiArrowRightSLine className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
