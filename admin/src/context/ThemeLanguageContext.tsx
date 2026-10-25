import React, { createContext, useContext, useState, useEffect } from 'react';

export type ThemeMode = 'light' | 'dark';
export type Language = 'en' | 'id';

export const translations = {
  en: {
    // Header & Global
    consoleTitle: 'Calora Admin',
    searchPlaceholder: 'Search here...',
    syncData: 'Sync Data',
    addFood: 'Add Food',
    switchTheme: 'Toggle theme',
    switchToDark: 'Dark Mode',
    switchToLight: 'Light Mode',

    // Navigation (Simple & Direct)
    dashboard: 'Dashboard',
    foodRequests: 'Food Requests',
    foodsCatalog: 'Foods',
    alerts: 'Alerts',
    taxonomy: 'Categories',
    moderationQueue: 'Requests',
    analytics: 'Analytics',
    userDirectory: 'Users',
    systemSettings: 'Settings',
    superAdmin: 'Admin',
    collapseSidebar: 'Collapse sidebar',
    expandSidebar: 'Expand sidebar',
    logout: 'Log Out',

    // Dashboard & Stats
    quickStats: 'Quick Stats',
    quickStatsSubtitle: 'Overview of public nutrition database.',
    totalFoods: 'Total Foods',
    totalCategories: 'Total Categories',
    pendingRequests: 'Pending Requests',
    approvedRequests: 'Approved Requests',
    rejectedRequests: 'Rejected Requests',
    dailySubmissions: 'Daily Submissions',
    foodRequestActivity: 'Food Request Activity',
    submittedRequests: 'Submitted Requests',
    approvedFoods: 'Approved Foods',
    pendingFoodRequests: 'Pending Food Requests',
    publicFoodDatabase: 'Public Food Database',
    category: 'Category',
    status: 'Status',
    allCategories: 'All Categories',

    // Table & Columns
    foodItem: 'Food Name',
    foodName: 'Food Name',
    categoryField: 'Category',
    calories: 'Calories',
    protein: 'Protein',
    carbs: 'Carbs',
    fat: 'Fat',
    servingLabel: 'Serving Label',
    action: 'Action',
    actions: 'Actions',
    submittedBy: 'Submitted By',
    registrationDate: 'Registration Date',
    accountStatus: 'Account Status',
    role: 'Role',

    // Statuses & Actions
    pending: 'Pending',
    approved: 'Approved',
    rejected: 'Rejected',
    all: 'All',
    review: 'Review',
    viewDetails: 'View Details',
    edit: 'Edit',
    delete: 'Delete',
    save: 'Save',
    cancel: 'Cancel',
    search: 'Search',
    filter: 'Filter',
    viewAll: 'View all',

    // Foods Page
    foodsPageTitle: 'Foods',
    foodsPageSubtitle: 'Verified foods and nutrition targets available to all users',
    itemsCataloged: 'items',
    noFoodsFound: 'No foods found',
    noFoodsFilterHelp: 'Try changing your search or category filter.',
    editFood: 'Edit Food',
    deleteFood: 'Delete Food',
    confirmDeleteFood: 'Are you sure you want to delete this food item?',

    // Categories Page
    taxonomyPageTitle: 'Categories',
    taxonomyPageSubtitle: 'Food categories for organizing nutrition items',
    createNewCategory: 'Add Category',
    categoryNamePlaceholder: 'Category name',
    addCategoryBtn: 'Add Category',
    deleteCategoryTitle: 'Delete Category',
    confirmDeleteCat: 'Are you sure you want to delete this category?',
    categoryName: 'Category Name',
    catalogItems: 'Items',
    inUseLabel: 'In Use',
    emptyLabel: 'Empty',
    totalLabel: 'Total',

    // Food Requests Page
    requestsPageTitle: 'Food Requests',
    requestsPageSubtitle: 'Review foods submitted by mobile users before adding to public database',
    addFoodManually: 'Add Food',
    pendingTab: 'Pending',
    approvedTab: 'Approved',
    rejectedTab: 'Rejected',
    allTab: 'All',
    resolutionRate: 'Completed Rate',
    noRequestsFound: 'No requests found',
    noPendingRequests: 'No pending requests',
    noActivityYet: 'No activity yet',
    noRequestsFilterHelp: 'Try changing your search or status filter.',
    reviewBtn: 'Review',

    // Users Page
    usersPageTitle: 'Users',
    usersPageSubtitle: 'Administer user accounts and staff roles. Health records remain private.',
    membersRegistered: 'registered users',
    rlsActive: 'Privacy Enforced',
    userProfile: 'User Profile',
    email: 'Email',
    administrator: 'Administrator',
    member: 'Member',
    active: 'Active',
    blocked: 'Blocked',
    blockUser: 'Block User',
    unblockUser: 'Unblock',
    cannotBlockAdmin: 'Cannot block administrator',
    confirmBlockUserTitle: 'Block User Account',
    confirmBlockUserDesc: 'Are you sure you want to block this user? They will not be able to log in or access Calora until unblocked.',
    confirmUnblockUserTitle: 'Unblock User Account',
    confirmUnblockUserDesc: 'Are you sure you want to unblock this user? They will regain access to their account.',
    statusFilterAll: 'All Status',
    statusFilterActive: 'Active',
    statusFilterBlocked: 'Blocked',

    // Pagination & General
    showingText: 'Showing',
    toText: 'to',
    ofText: 'of',
    entriesText: 'entries',
    perPageText: 'per page',
    rowsText: 'Rows:',
    foodTaxonomy: 'Food Categories',
    addVerifiedFood: 'Add Food',
    itemsSelected: 'selected',
    deleteSelected: 'Delete Selected',
    deselectAll: 'Deselect',
    bulkDelete: 'Bulk Delete',
    bulkApprove: 'Approve Selected',
    bulkReject: 'Reject Selected',
    bulkDeleteConfirmTitle: 'Delete Selected Items',
    bulkDeleteFoodDesc: 'Are you sure you want to delete these selected foods from the public database?',
    // Legacy / Auxiliary dashboard component support
    activeUsers: 'Active Users',
    submissionsSubtitle: 'User-submitted foods awaiting review',
    today: 'Today',
    pendingSubmissions: 'Pending Review',
    awaitingReview: 'awaiting review',
    verifiedFoods: 'Verified Foods',
    addedThisMonth: 'added this month',
    vsLastMonth: 'vs last month',
    catalogAccuracy: 'Catalog Accuracy',
    recentSubmissions: 'Recent Submissions',
    caloriesMacros: 'Calories & Macros',
    dateCol: 'Date',
    actionCol: 'Action',
    requestId: 'Request ID',
    approvedStatus: 'Approved',
    rejectedStatus: 'Rejected',
    pendingStatus: 'Pending',

    // Modals
    reviewModalTitle: 'Review Food Request',
    portionLabel: 'Portion',
    nutritionalValues: 'Nutrition Values',
    proteinLabel: 'Protein',
    carbsLabel: 'Carbs',
    fatLabel: 'Fat',
    submittedByLabel: 'Submitted By',
    requestDateLabel: 'Submitted Date',
    submissionNotes: 'Notes',
    noNotesProvided: 'No notes provided.',
    rejectReasonPrompt: 'Reason for rejection:',
    approveAndPublish: 'Approve & Add to Database',
    rejectSubmission: 'Reject',
    confirmReject: 'Confirm Rejection',
    editFoodModalTitle: 'Edit Food',
    addFoodModalTitle: 'Add Food',
    publishDirectlySubtitle: 'Add directly to the public Calora food database',
    foodNameField: 'Food Name',
    servingLabelField: 'Serving Label (e.g. 100g cooked, 1 bowl)',
    caloriesKcalField: 'Calories (kcal)',
    saveChanges: 'Save',
    addToCatalog: 'Add Food',

    // Analytics & Charts
    analyticsTitle: 'Analytics',
    analyticsSubtitle: 'Metrics on moderation velocity, nutritional accuracy, and community submission growth',
    approvalRate: 'Approval Rate',
    rejectionRate: 'Rejection Rate',
    pendingReview: 'Pending Review',
    activityChartTitle: 'Food Submissions & Moderation Activity',
    activityChartSubtitle: 'Real velocity of user-submitted dishes reviewed by administration',
    macroDistributionTitle: 'Macro Distribution by Category',
    macroDistributionSubtitle: 'Average macronutrient breakdown (g) across cataloged food categories',
    timeframe7d: '7 Days',
    timeframe30d: '30 Days',
    timeframe1y: '1 Year',
  },
  id: {
    // Header & Global
    consoleTitle: 'Calora Admin',
    searchPlaceholder: 'Cari di sini...',
    syncData: 'Sinkron Data',
    addFood: 'Tambah Makanan',
    switchTheme: 'Ganti tema',
    switchToDark: 'Mode Gelap',
    switchToLight: 'Mode Terang',

    // Navigation (Simple & Direct)
    dashboard: 'Dashboard',
    foodRequests: 'Permintaan Makanan',
    foodsCatalog: 'Makanan',
    alerts: 'Pemberitahuan',
    taxonomy: 'Kategori',
    moderationQueue: 'Permintaan',
    analytics: 'Analitik',
    userDirectory: 'Pengguna',
    systemSettings: 'Pengaturan',
    superAdmin: 'Admin',
    collapseSidebar: 'Ciutkan sidebar',
    expandSidebar: 'Buka sidebar',
    logout: 'Keluar',

    // Dashboard & Stats
    quickStats: 'Statistik Cepat',
    quickStatsSubtitle: 'Ringkasan database makanan publik.',
    totalFoods: 'Total Makanan',
    totalCategories: 'Total Kategori',
    pendingRequests: 'Permintaan Menunggu',
    approvedRequests: 'Permintaan Disetujui',
    rejectedRequests: 'Permintaan Ditolak',
    dailySubmissions: 'Pengajuan Harian',
    foodRequestActivity: 'Aktivitas Permintaan Makanan',
    submittedRequests: 'Permintaan Diajukan',
    approvedFoods: 'Makanan Disetujui',
    pendingFoodRequests: 'Permintaan Makanan Menunggu',
    publicFoodDatabase: 'Database Makanan Publik',
    category: 'Kategori',
    status: 'Status',
    allCategories: 'Semua Kategori',

    // Table & Columns
    foodItem: 'Nama Makanan',
    foodName: 'Nama Makanan',
    categoryField: 'Kategori',
    calories: 'Kalori',
    protein: 'Protein',
    carbs: 'Karbohidrat',
    fat: 'Lemak',
    servingLabel: 'Label Porsi',
    action: 'Aksi',
    actions: 'Aksi',
    submittedBy: 'Diajukan Oleh',
    registrationDate: 'Tanggal Daftar',
    accountStatus: 'Status Akun',
    role: 'Peran',

    // Statuses & Actions
    pending: 'Menunggu',
    approved: 'Disetujui',
    rejected: 'Ditolak',
    all: 'Semua',
    review: 'Tinjau',
    viewDetails: 'Lihat Detail',
    edit: 'Edit',
    delete: 'Hapus',
    save: 'Simpan',
    cancel: 'Batal',
    search: 'Cari',
    filter: 'Filter',
    viewAll: 'Lihat semua',

    // Foods Page
    foodsPageTitle: 'Makanan',
    foodsPageSubtitle: 'Katalog makanan terverifikasi untuk pengguna Calora',
    itemsCataloged: 'menu',
    noFoodsFound: 'Makanan tidak ditemukan',
    noFoodsFilterHelp: 'Coba ubah kata pencarian atau pilih kategori lain.',
    editFood: 'Edit Makanan',
    deleteFood: 'Hapus Makanan',
    confirmDeleteFood: 'Yakin ingin menghapus makanan ini?',

    // Categories Page
    taxonomyPageTitle: 'Kategori',
    taxonomyPageSubtitle: 'Kategori makanan untuk mengelompokkan menu',
    createNewCategory: 'Tambah Kategori',
    categoryNamePlaceholder: 'Nama kategori',
    addCategoryBtn: 'Simpan Kategori',
    deleteCategoryTitle: 'Hapus Kategori',
    confirmDeleteCat: 'Yakin ingin menghapus kategori ini?',
    categoryName: 'Nama Kategori',
    catalogItems: 'Jumlah',
    inUseLabel: 'Digunakan',
    emptyLabel: 'Kosong',
    totalLabel: 'Total',

    // Food Requests Page
    requestsPageTitle: 'Permintaan Makanan',
    requestsPageSubtitle: 'Tinjau menu dari pengguna sebelum masuk ke database publik',
    addFoodManually: 'Tambah Makanan',
    pendingTab: 'Menunggu',
    approvedTab: 'Disetujui',
    rejectedTab: 'Ditolak',
    allTab: 'Semua',
    resolutionRate: 'Tingkat Selesai',
    noRequestsFound: 'Tidak ada permintaan',
    noPendingRequests: 'Tidak ada permintaan menunggu',
    noActivityYet: 'Belum ada aktivitas',
    noRequestsFilterHelp: 'Coba ubah kata pencarian atau filter status.',
    reviewBtn: 'Tinjau',

    // Users Page
    usersPageTitle: 'Pengguna',
    usersPageSubtitle: 'Kelola akun pengguna dan staf admin. Data kesehatan tetap privat.',
    membersRegistered: 'pengguna terdaftar',
    rlsActive: 'Privasi Terjamin',
    userProfile: 'Profil Pengguna',
    email: 'Email',
    administrator: 'Administrator',
    member: 'Pengguna',
    active: 'Aktif',
    blocked: 'Diblokir',
    blockUser: 'Blokir Pengguna',
    unblockUser: 'Buka Blokir',
    cannotBlockAdmin: 'Tidak dapat memblokir administrator',
    confirmBlockUserTitle: 'Blokir Akun Pengguna',
    confirmBlockUserDesc: 'Apakah Anda yakin ingin memblokir akun ini? Pengguna tidak akan dapat masuk atau mengakses Calora sampai blokir dibuka.',
    confirmUnblockUserTitle: 'Buka Blokir Akun',
    confirmUnblockUserDesc: 'Apakah Anda yakin ingin membuka blokir akun ini? Pengguna akan dapat kembali mengakses akun Calora mereka.',
    statusFilterAll: 'Semua Status',
    statusFilterActive: 'Aktif',
    statusFilterBlocked: 'Diblokir',

    // Pagination & General
    showingText: 'Menampilkan',
    toText: 'sampai',
    ofText: 'dari',
    entriesText: 'data',
    perPageText: 'per halaman',
    rowsText: 'Baris:',
    foodTaxonomy: 'Kategori Makanan',
    addVerifiedFood: 'Tambah Makanan',
    itemsSelected: 'terpilih',
    deleteSelected: 'Hapus Terpilih',
    deselectAll: 'Batalkan',
    bulkDelete: 'Hapus Massal',
    bulkApprove: 'Setujui Terpilih',
    bulkReject: 'Tolak Terpilih',
    bulkDeleteConfirmTitle: 'Hapus Item Terpilih',
    bulkDeleteFoodDesc: 'Apakah Anda yakin ingin menghapus makanan terpilih ini dari database publik?',
    // Legacy / Auxiliary dashboard component support
    activeUsers: 'Pengguna Aktif',
    submissionsSubtitle: 'Permintaan makanan dari pengguna',
    today: 'Hari Ini',
    pendingSubmissions: 'Menunggu Review',
    awaitingReview: 'menunggu review',
    verifiedFoods: 'Makanan Terverifikasi',
    addedThisMonth: 'ditambahkan bulan ini',
    vsLastMonth: 'dibanding bulan lalu',
    catalogAccuracy: 'Akurasi Nutrisi',
    recentSubmissions: 'Permintaan Terbaru',
    caloriesMacros: 'Kalori & Makro',
    dateCol: 'Tanggal',
    actionCol: 'Aksi',
    requestId: 'ID Permintaan',
    approvedStatus: 'Disetujui',
    rejectedStatus: 'Ditolak',
    pendingStatus: 'Menunggu',

    // Modals
    reviewModalTitle: 'Tinjau Permintaan Makanan',
    portionLabel: 'Porsi',
    nutritionalValues: 'Nilai Nutrisi',
    proteinLabel: 'Protein',
    carbsLabel: 'Karbohidrat',
    fatLabel: 'Lemak',
    submittedByLabel: 'Diajukan Oleh',
    requestDateLabel: 'Tanggal Diajukan',
    submissionNotes: 'Catatan',
    noNotesProvided: 'Tidak ada catatan.',
    rejectReasonPrompt: 'Alasan penolakan:',
    approveAndPublish: 'Setujui & Tambah ke Database',
    rejectSubmission: 'Tolak',
    confirmReject: 'Konfirmasi Tolak',
    editFoodModalTitle: 'Edit Makanan',
    addFoodModalTitle: 'Tambah Makanan',
    publishDirectlySubtitle: 'Tambahkan langsung ke database makanan publik Calora',
    foodNameField: 'Nama Makanan',
    servingLabelField: 'Label Porsi (contoh: 100g, 1 mangkok)',
    caloriesKcalField: 'Kalori (kcal)',
    saveChanges: 'Simpan',
    addToCatalog: 'Tambah Makanan',

    // Analytics & Charts
    analyticsTitle: 'Analitik',
    analyticsSubtitle: 'Metrik kecepatan moderasi, akurasi nutrisi, dan pertumbuhan pengajuan komunitas',
    approvalRate: 'Tingkat Disetujui',
    rejectionRate: 'Tingkat Ditolak',
    pendingReview: 'Menunggu Review',
    activityChartTitle: 'Aktivitas Pengajuan & Moderasi Makanan',
    activityChartSubtitle: 'Kecepatan nyata peninjauan hidangan pengguna oleh administrator',
    macroDistributionTitle: 'Distribusi Makronutrien per Kategori',
    macroDistributionSubtitle: 'Rata-rata rincian makronutrien (g) pada tiap kategori makanan',
    timeframe7d: '7 Hari',
    timeframe30d: '30 Hari',
    timeframe1y: '1 Tahun',
  },
};

export type TranslationKey = keyof typeof translations['en'];

interface ThemeLanguageContextType {
  theme: ThemeMode;
  toggleTheme: () => void;
  language: Language;
  setLanguage: (lang: Language) => void;
  t: (key: TranslationKey) => string;
  isDark: boolean;
}

const ThemeLanguageContext = createContext<ThemeLanguageContextType | undefined>(undefined);

export const ThemeLanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [theme, setTheme] = useState<ThemeMode>(() => {
    const saved = localStorage.getItem('calora_theme') as ThemeMode;
    return saved === 'dark' ? 'dark' : 'light';
  });

  const [language, setLanguageState] = useState<Language>(() => {
    const saved = localStorage.getItem('calora_lang') as Language;
    return saved === 'id' ? 'id' : 'en';
  });

  useEffect(() => {
    const root = document.documentElement;
    if (theme === 'dark') {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
    localStorage.setItem('calora_theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme((prev) => (prev === 'light' ? 'dark' : 'light'));
  };

  const setLanguage = (lang: Language) => {
    setLanguageState(lang);
    localStorage.setItem('calora_lang', lang);
  };

  const t = (key: TranslationKey): string => {
    return translations[language]?.[key] || translations['en']?.[key] || (key as string);
  };

  const isDark = theme === 'dark';

  return (
    <ThemeLanguageContext.Provider
      value={{
        theme,
        toggleTheme,
        language,
        setLanguage,
        t,
        isDark,
      }}
    >
      {children}
    </ThemeLanguageContext.Provider>
  );
};

export const useThemeLanguage = () => {
  const context = useContext(ThemeLanguageContext);
  if (!context) {
    throw new Error('useThemeLanguage must be used within a ThemeLanguageProvider');
  }
  return context;
};
