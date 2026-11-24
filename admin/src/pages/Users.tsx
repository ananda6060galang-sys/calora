import React, { useState, useMemo } from 'react';
import { useAdmin } from '../context/AdminContext';
import { useThemeLanguage } from '../context/ThemeLanguageContext';
import { AdminHeader } from '../components/layout/AdminHeader';
import {
  Users,
  ShieldCheck,
  Lock,
  CheckCircle2,
  Search,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  ChevronDown,
  ChevronsUpDown,
  X,
  Check,
  Minus,
  Ban,
} from 'lucide-react';
import { Profile } from '../types';

type SortField = 'name' | 'role' | 'submissions' | 'created_at';
type SortOrder = 'asc' | 'desc';

export const UsersPage: React.FC = () => {
  const { users, requests, toggleBlockUser } = useAdmin();
  const { t } = useThemeLanguage();

  const [localSearch, setLocalSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<'all' | 'admin' | 'user'>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'blocked'>('all');
  const [sortField, setSortField] = useState<SortField>('created_at');
  const [sortOrder, setSortOrder] = useState<SortOrder>('desc');
  const [currentPage, setCurrentPage] = useState(1);
  const pageSize = 10;
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  // State for block/unblock confirmation modal
  const [targetUserForBlock, setTargetUserForBlock] = useState<{
    user: Profile;
    action: 'block' | 'unblock';
  } | null>(null);
  const [isActionSubmitting, setIsActionSubmitting] = useState(false);

  // Submissions count mapping per user
  const userSubmissionCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    requests.forEach((r) => {
      counts[r.user_id] = (counts[r.user_id] || 0) + 1;
    });
    return counts;
  }, [requests]);

  // Filtering
  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      const matchRole = roleFilter === 'all' || u.role === roleFilter;
      const matchStatus =
        statusFilter === 'all' ||
        (statusFilter === 'active' && !u.is_blocked) ||
        (statusFilter === 'blocked' && !!u.is_blocked);
      const matchSearch =
        u.name.toLowerCase().includes(localSearch.toLowerCase()) ||
        (u.email && u.email.toLowerCase().includes(localSearch.toLowerCase()));
      return matchRole && matchStatus && matchSearch;
    });
  }, [users, roleFilter, statusFilter, localSearch]);

  // Sorting
  const sortedUsers = useMemo(() => {
    return [...filteredUsers].sort((a, b) => {
      let comparison = 0;
      if (sortField === 'name') {
        comparison = a.name.localeCompare(b.name);
      } else if (sortField === 'role') {
        comparison = a.role.localeCompare(b.role);
      } else if (sortField === 'submissions') {
        const countA = userSubmissionCounts[a.id] || 0;
        const countB = userSubmissionCounts[b.id] || 0;
        comparison = countA - countB;
      } else if (sortField === 'created_at') {
        const dateA = a.created_at ? new Date(a.created_at).getTime() : 0;
        const dateB = b.created_at ? new Date(b.created_at).getTime() : 0;
        comparison = dateA - dateB;
      }
      return sortOrder === 'asc' ? comparison : -comparison;
    });
  }, [filteredUsers, sortField, sortOrder, userSubmissionCounts]);

  const totalEntries = sortedUsers.length;
  const totalPages = Math.max(1, Math.ceil(totalEntries / pageSize));
  const validCurrentPage = Math.min(currentPage, totalPages);

  const paginatedUsers = useMemo(() => {
    const startIndex = (validCurrentPage - 1) * pageSize;
    return sortedUsers.slice(startIndex, startIndex + pageSize);
  }, [sortedUsers, validCurrentPage, pageSize]);

  const paginatedIds = useMemo(() => paginatedUsers.map((u) => u.id), [paginatedUsers]);
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

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('asc');
    }
  };

  const totalAdmins = users.filter((u) => u.role === 'admin').length;
  const totalActive = users.filter((u) => !u.is_blocked).length;
  const totalBlocked = users.filter((u) => !!u.is_blocked).length;

  const handleExecuteBlockAction = async () => {
    if (!targetUserForBlock) return;
    try {
      setIsActionSubmitting(true);
      await toggleBlockUser(targetUserForBlock.user.id, targetUserForBlock.action === 'block');
      setTargetUserForBlock(null);
    } catch (err) {
      console.error('Failed to execute block action:', err);
    } finally {
      setIsActionSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 animate-fade-in font-sans pb-12">
      {/* ── HEADER ─────────────────────────────────────────────────── */}
      <AdminHeader
        title={t('usersPageTitle')}
        subtitle={t('usersPageSubtitle')}
        showSearch={false}
      />

      {/* ── 4 STAT CARDS ────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5 sm:gap-4">
        {/* Card 1: Total Users */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#B8FF3B] text-[#0C2417]">
            <Users className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {users.length.toLocaleString()}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('userDirectory')}
          </span>
        </div>

        {/* Card 2: Staff Administrators */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-[#111111] dark:text-[#E2E8DF]">
            <ShieldCheck className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {totalAdmins}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('administrator')}
          </span>
        </div>

        {/* Card 3: Active Members */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-[#F2F5F0] dark:bg-[#1C261F] text-emerald-600 dark:text-emerald-400">
            <CheckCircle2 className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {totalActive}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('active')}
          </span>
        </div>

        {/* Card 4: Blocked Members */}
        <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] p-5 sm:p-6 border border-[#EAEFE8] dark:border-[#212E23] shadow-xs flex flex-col items-center justify-center text-center">
          <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs shrink-0 mb-3 bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400">
            <Ban className="w-4.5 h-4.5 stroke-[1.8]" />
          </div>
          <span className="text-2xl sm:text-3xl font-extrabold text-[#111111] dark:text-[#F3F5EF] tracking-tight block leading-tight">
            {totalBlocked}
          </span>
          <span className="text-sm font-medium text-stone-600 dark:text-stone-300 block mt-1.5">
            {t('blocked')}
          </span>
        </div>
      </div>

      {/* ── PRIVACY NOTE ────────────────────────────────────────────── */}
      <div className="flex items-center justify-between p-4.5 rounded-[20px] bg-[#EBF7EA] dark:bg-[#14331C]/60 border border-[#D5EED1] dark:border-[#234B2D] text-sm">
        <div className="flex items-center space-x-3">
          <div className="w-7 h-7 rounded-full bg-[#16A34A] text-white flex items-center justify-center text-xs shrink-0">
            <Lock className="w-4 h-4 stroke-[2]" />
          </div>
          <p className="text-emerald-950 dark:text-emerald-200 font-medium leading-tight">
            <strong>RLS Privacy Active:</strong> User food diaries, weight logs, and private health metrics are isolated and not accessible from this console.
          </p>
        </div>
      </div>

      {/* ── USERS TABLE CONTAINER ───────────────────────────────────── */}
      <div className="bg-white dark:bg-[#141C17] rounded-[22px] sm:rounded-[24px] border border-[#EAEFE8] dark:border-[#212E23] shadow-xs overflow-hidden transition-colors duration-200">
        {/* TOOLBAR */}
        <div className="p-4.5 sm:px-6 border-b border-[#F2F5F0] dark:border-[#202C22] flex flex-col md:flex-row md:items-center justify-between gap-3 text-sm">
          <div className="flex items-center space-x-2">
            <span className="font-bold text-[#111111] dark:text-[#F3F5EF]">
              {totalEntries} {t('userDirectory')}
            </span>
          </div>

          <div className="flex items-center flex-wrap gap-2.5">
            {/* Search */}
            <div className="relative">
              <Search className="w-4 h-4 text-stone-400 dark:text-stone-500 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none stroke-[1.8]" />
              <input
                type="text"
                value={localSearch}
                onChange={(e) => {
                  setLocalSearch(e.target.value);
                  setCurrentPage(1);
                }}
                placeholder={t('searchPlaceholder')}
                className="bg-white dark:bg-[#181E19] border border-gray-200 dark:border-[#263226] text-sm text-[#111111] dark:text-[#F3F5EF] placeholder-stone-500 dark:placeholder-stone-400 rounded-full pl-10 pr-8 py-2 focus:outline-none focus:ring-1 focus:ring-[#B8FF3B] w-56 transition-colors shadow-2xs"
              />
              {localSearch && (
                <button
                  onClick={() => setLocalSearch('')}
                  aria-label="Clear search"
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 text-stone-400 hover:text-stone-600 dark:hover:text-white cursor-pointer"
                >
                  <X className="w-3.5 h-3.5 stroke-[2]" />
                </button>
              )}
            </div>

            {/* Role Filter Pills */}
            <div className="flex items-center space-x-1 p-0.5 bg-gray-100 dark:bg-[#202820] rounded-full border border-gray-200 dark:border-[#2D382D] text-sm font-semibold">
              <button
                onClick={() => {
                  setRoleFilter('all');
                  setCurrentPage(1);
                }}
                className={`px-3.5 py-1.5 rounded-full transition-all cursor-pointer ${
                  roleFilter === 'all'
                    ? 'bg-white dark:bg-[#181E19] text-[#111111] dark:text-[#F3F5EF] shadow-2xs font-bold'
                    : 'text-stone-600 hover:text-stone-900 dark:text-stone-400 dark:hover:text-white'
                }`}
              >
                {t('all')}
              </button>
              <button
                onClick={() => {
                  setRoleFilter('admin');
                  setCurrentPage(1);
                }}
                className={`px-3.5 py-1.5 rounded-full transition-all cursor-pointer ${
                  roleFilter === 'admin'
                    ? 'bg-[#B8FF3B] text-[#0C2417] shadow-2xs font-bold'
                    : 'text-stone-600 hover:text-[#111111] dark:text-stone-400 dark:hover:text-white'
                }`}
              >
                {t('administrator')}
              </button>
              <button
                onClick={() => {
                  setRoleFilter('user');
                  setCurrentPage(1);
                }}
                className={`px-3.5 py-1.5 rounded-full transition-all cursor-pointer ${
                  roleFilter === 'user'
                    ? 'bg-[#16A34A] dark:bg-[#3DDC84] text-white dark:text-[#0C2417] shadow-2xs font-bold'
                    : 'text-stone-600 hover:text-stone-900 dark:text-stone-400 dark:hover:text-white'
                }`}
              >
                {t('member')}
              </button>
            </div>

            {/* Status Filter Pills */}
            <div className="flex items-center space-x-1 p-0.5 bg-gray-100 dark:bg-[#202820] rounded-full border border-gray-200 dark:border-[#2D382D] text-sm font-semibold">
              <button
                onClick={() => {
                  setStatusFilter('all');
                  setCurrentPage(1);
                }}
                className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                  statusFilter === 'all'
                    ? 'bg-white dark:bg-[#181E19] text-[#111111] dark:text-[#F3F5EF] shadow-2xs font-bold'
                    : 'text-stone-600 hover:text-stone-900 dark:text-stone-400 dark:hover:text-white'
                }`}
              >
                {t('statusFilterAll')}
              </button>
              <button
                onClick={() => {
                  setStatusFilter('active');
                  setCurrentPage(1);
                }}
                className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                  statusFilter === 'active'
                    ? 'bg-[#16A34A] dark:bg-[#3DDC84] text-white dark:text-[#0C2417] shadow-2xs font-bold'
                    : 'text-stone-600 hover:text-stone-900 dark:text-stone-400 dark:hover:text-white'
                }`}
              >
                {t('statusFilterActive')}
              </button>
              <button
                onClick={() => {
                  setStatusFilter('blocked');
                  setCurrentPage(1);
                }}
                className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                  statusFilter === 'blocked'
                    ? 'bg-rose-600 text-white shadow-2xs font-bold'
                    : 'text-stone-600 hover:text-rose-600 dark:text-stone-400 dark:hover:text-rose-400'
                }`}
              >
                {t('statusFilterBlocked')}
              </button>
            </div>
          </div>
        </div>

        {/* ── SELECTION BAR ─────────────────────────────────────────── */}
        {selectedIds.length > 0 && (
          <div className="p-3.5 mx-4 my-3 bg-emerald-50/80 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-900/50 rounded-xl flex items-center justify-between flex-wrap gap-2 animate-in fade-in slide-in-from-top-1 duration-150">
            <div className="flex items-center space-x-2.5">
              <span className="w-5.5 h-5.5 rounded-full bg-[#16A34A] text-white text-xs font-bold flex items-center justify-center">
                {selectedIds.length}
              </span>
              <span className="text-sm font-semibold text-emerald-900 dark:text-emerald-200">
                {selectedIds.length} {t('itemsSelected')}
              </span>
            </div>

            <button
              onClick={() => setSelectedIds([])}
              className="px-3.5 py-2 rounded-xl border border-stone-300 dark:border-stone-600 hover:bg-white dark:hover:bg-[#1A241E] text-sm font-medium text-stone-700 dark:text-stone-300 transition-colors cursor-pointer"
            >
              {t('deselectAll')}
            </button>
          </div>
        )}

        {/* TABLE CONTENT */}
        <div className="overflow-x-auto scrollbar-wide">
          <table className="w-full text-left border-collapse text-sm min-w-[650px]">
            <thead>
              <tr className="border-b border-[#F2F5F0] dark:border-[#202C22] text-[13px] font-semibold text-stone-700 dark:text-stone-300">
                <th className="py-3.5 px-4 w-10 text-center">
                  <button
                    onClick={toggleSelectAll}
                    aria-label="Select all users on this page"
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
                    <span>{t('userProfile')}</span>
                    {sortField === 'name' ? (
                      sortOrder === 'asc' ? <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" /> : <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" />
                    ) : (
                      <ChevronsUpDown className="w-3.5 h-3.5 opacity-40 stroke-[2]" />
                    )}
                  </div>
                </th>
                <th
                  onClick={() => handleSort('role')}
                  className="py-3.5 px-4 cursor-pointer hover:text-black dark:hover:text-white select-none transition-colors"
                >
                  <div className="flex items-center space-x-1">
                    <span>{t('role')}</span>
                    {sortField === 'role' ? (
                      sortOrder === 'asc' ? <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" /> : <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" />
                    ) : (
                      <ChevronsUpDown className="w-3.5 h-3.5 opacity-40 stroke-[2]" />
                    )}
                  </div>
                </th>
                <th className="py-3.5 px-4">{t('accountStatus')}</th>
                <th
                  onClick={() => handleSort('submissions')}
                  className="py-3.5 px-4 cursor-pointer hover:text-black dark:hover:text-white select-none transition-colors"
                >
                  <div className="flex items-center space-x-1">
                    <span>{t('foodRequests')}</span>
                    {sortField === 'submissions' ? (
                      sortOrder === 'asc' ? <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" /> : <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" />
                    ) : (
                      <ChevronsUpDown className="w-3.5 h-3.5 opacity-40 stroke-[2]" />
                    )}
                  </div>
                </th>
                <th
                  onClick={() => handleSort('created_at')}
                  className="py-3.5 px-6 cursor-pointer hover:text-black dark:hover:text-white select-none transition-colors"
                >
                  <div className="flex items-center space-x-1">
                    <span>{t('registrationDate')}</span>
                    {sortField === 'created_at' ? (
                      sortOrder === 'asc' ? <ChevronUp className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" /> : <ChevronDown className="w-3.5 h-3.5 text-[#16A34A] dark:text-[#B8FF3B] stroke-[2.2]" />
                    ) : (
                      <ChevronsUpDown className="w-3.5 h-3.5 opacity-40 stroke-[2]" />
                    )}
                  </div>
                </th>
                <th className="py-3.5 px-4 text-right">{t('action')}</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-[#F2F5F0] dark:divide-[#202C22]">
              {paginatedUsers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-sm text-stone-400 dark:text-stone-500">
                    No accounts found matching search criteria.
                  </td>
                </tr>
              ) : (
                paginatedUsers.map((u) => {
                  const isChecked = selectedIds.includes(u.id);
                  const submissionCount = userSubmissionCounts[u.id] || 0;

                  return (
                    <tr
                      key={u.id}
                      className={`hover:bg-[#F9FBF8] dark:hover:bg-[#19241D] transition-colors ${
                        isChecked ? 'bg-green-50/30 dark:bg-[#18231B]/50' : ''
                      }`}
                    >
                      <td className="py-3.5 px-4 text-center">
                        <button
                          onClick={() => toggleSelect(u.id)}
                          aria-label={`Select ${u.name}`}
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

                      <td className="py-3.5 px-4">
                        <div className="flex items-center space-x-3">
                          <div
                            className={`relative w-8.5 h-8.5 rounded-full flex items-center justify-center font-bold text-xs shrink-0 overflow-hidden ${
                              u.role === 'admin'
                                ? 'bg-[#0B2114] text-[#B8FF3B] ring-1 ring-[#B8FF3B]'
                                : u.is_blocked
                                ? 'bg-rose-50 dark:bg-rose-950/50 text-rose-600 dark:text-rose-400'
                                : 'bg-emerald-50 dark:bg-[#14331C] text-[#16A34A] dark:text-[#3DDC84]'
                            }`}
                          >
                            {u.avatar_url ? (
                              <img
                                src={u.avatar_url}
                                alt={u.name}
                                className="w-full h-full object-cover rounded-full absolute inset-0"
                                onError={(e) => {
                                  (e.currentTarget as HTMLElement).style.display = 'none';
                                }}
                              />
                            ) : null}
                            <span>{u.name?.[0]?.toUpperCase() || 'U'}</span>
                          </div>
                          <div>
                            <p className="font-semibold text-sm text-[#111111] dark:text-[#F3F5EF]">
                              {u.name}
                            </p>
                            <p className="text-xs text-stone-500 dark:text-stone-400 font-medium truncate max-w-[220px]" title={u.email}>
                              {u.email || '—'}
                            </p>
                          </div>
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center px-2.5 py-1 text-xs font-semibold rounded-full ${
                            u.role === 'admin'
                              ? 'bg-[#B8FF3B] text-[#0C2417] font-bold'
                              : 'bg-gray-100 dark:bg-[#202820] text-stone-600 dark:text-stone-300 border border-stone-200 dark:border-[#2D382D]'
                          }`}
                        >
                          {u.role === 'admin' ? t('administrator') : t('member')}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        {u.is_blocked ? (
                          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-900/40">
                            <span className="w-1.5 h-1.5 rounded-full bg-rose-500 mr-1.5"></span>
                            {t('blocked')}
                          </span>
                        ) : (
                          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-[#14331C] text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-900/40">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 mr-1.5"></span>
                            {t('active')}
                          </span>
                        )}
                      </td>

                      <td className="py-3.5 px-4 font-bold text-sm text-[#111111] dark:text-white">
                        {submissionCount}
                      </td>

                      <td className="py-3.5 px-6 text-stone-600 dark:text-stone-300 font-medium text-xs">
                        {u.created_at ? new Date(u.created_at).toLocaleDateString() : 'Active member'}
                      </td>

                      {/* Action Column */}
                      <td className="py-3.5 px-4 text-right">
                        {u.role === 'admin' ? (
                          <span className="text-xs text-stone-400 dark:text-stone-500 italic">
                            {t('administrator')}
                          </span>
                        ) : u.is_blocked ? (
                          <button
                            onClick={() => setTargetUserForBlock({ user: u, action: 'unblock' })}
                            className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 hover:bg-emerald-100 dark:hover:bg-emerald-900/50 border border-emerald-200 dark:border-emerald-800 transition-colors cursor-pointer"
                            title={t('unblockUser')}
                          >
                            <CheckCircle2 className="w-3.5 h-3.5 stroke-[2]" />
                            <span>{t('unblockUser')}</span>
                          </button>
                        ) : (
                          <button
                            onClick={() => setTargetUserForBlock({ user: u, action: 'block' })}
                            className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 hover:bg-rose-100 dark:hover:bg-rose-900/50 border border-rose-200 dark:border-rose-800 transition-colors cursor-pointer"
                            title={t('blockUser')}
                          >
                            <Ban className="w-3.5 h-3.5 stroke-[2]" />
                            <span>{t('blockUser')}</span>
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* PAGINATION */}
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

      {/* ── CONFIRMATION MODAL ────────────────────────────────────── */}
      {targetUserForBlock && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-xs p-4 animate-fade-in">
          <div className="bg-white dark:bg-[#141C17] border border-[#E9EFE8] dark:border-[#212E23] rounded-2xl max-w-md w-full p-6 shadow-xl space-y-4">
            <div className="flex items-center space-x-3">
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${
                  targetUserForBlock.action === 'block'
                    ? 'bg-rose-100 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400'
                    : 'bg-emerald-100 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400'
                }`}
              >
                {targetUserForBlock.action === 'block' ? (
                  <Ban className="w-5 h-5 stroke-[2]" />
                ) : (
                  <CheckCircle2 className="w-5 h-5 stroke-[2]" />
                )}
              </div>
              <div>
                <h3 className="text-base font-bold text-[#111111] dark:text-[#F3F5EF]">
                  {targetUserForBlock.action === 'block'
                    ? t('confirmBlockUserTitle')
                    : t('confirmUnblockUserTitle')}
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {targetUserForBlock.user.name} ({targetUserForBlock.user.email || 'Member'})
                </p>
              </div>
            </div>

            <p className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
              {targetUserForBlock.action === 'block'
                ? t('confirmBlockUserDesc')
                : t('confirmUnblockUserDesc')}
            </p>

            <div className="flex items-center justify-end space-x-2 pt-2">
              <button
                disabled={isActionSubmitting}
                onClick={() => setTargetUserForBlock(null)}
                className="px-4 py-2 rounded-xl border border-gray-200 dark:border-[#263226] text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-[#1A241E] transition-colors cursor-pointer disabled:opacity-50"
              >
                {t('cancel')}
              </button>
              <button
                disabled={isActionSubmitting}
                onClick={handleExecuteBlockAction}
                className={`px-4 py-2 rounded-xl text-xs font-bold transition-all shadow-xs cursor-pointer disabled:opacity-50 flex items-center space-x-1.5 ${
                  targetUserForBlock.action === 'block'
                    ? 'bg-rose-600 hover:bg-rose-700 text-white'
                    : 'bg-[#16A34A] hover:bg-[#15803D] text-white'
                }`}
              >
                {isActionSubmitting ? (
                  <span>Processing...</span>
                ) : (
                  <>
                    {targetUserForBlock.action === 'block' ? (
                      <>
                        <Ban className="w-3.5 h-3.5 stroke-[2]" />
                        <span>{t('blockUser')}</span>
                      </>
                    ) : (
                      <>
                        <CheckCircle2 className="w-3.5 h-3.5 stroke-[2]" />
                        <span>{t('unblockUser')}</span>
                      </>
                    )}
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
