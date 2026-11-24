import React, { useState } from 'react';
import { createPortal } from 'react-dom';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { AlertTriangle, Trash2, X, AlertCircle } from 'lucide-react';

interface CategoryWithCount {
  id: string;
  name: string;
  itemCount: number;
}

interface BulkDeleteCategoryModalProps {
  isOpen: boolean;
  selectedCategories: CategoryWithCount[];
  onClose: () => void;
  onConfirm: (categoryIdsToDelete: string[]) => Promise<void>;
}

export const BulkDeleteCategoryModal: React.FC<BulkDeleteCategoryModalProps> = ({
  isOpen,
  selectedCategories,
  onClose,
  onConfirm,
}) => {
  const { t } = useThemeLanguage();
  const [isDeleting, setIsDeleting] = useState(false);

  if (!isOpen || selectedCategories.length === 0) return null;

  const inUseCategories = selectedCategories.filter((c) => c.itemCount > 0);
  const emptyCategories = selectedCategories.filter((c) => c.itemCount === 0);

  const handleConfirm = async () => {
    if (emptyCategories.length === 0) return;
    setIsDeleting(true);
    try {
      await onConfirm(emptyCategories.map((c) => c.id));
      onClose();
    } catch (e) {
      console.error('Failed to delete categories:', e);
    } finally {
      setIsDeleting(false);
    }
  };

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/60 backdrop-blur-xs overflow-y-auto animate-in fade-in duration-150">
      <div className="bg-white dark:bg-[#181E19] w-full max-w-md rounded-2xl shadow-2xl border border-[#EAECE8] dark:border-[#263226] overflow-hidden flex flex-col max-h-[calc(100vh-2rem)] my-auto">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4.5 border-b border-[#F2F4F0] dark:border-[#222D23] shrink-0">
          <div className="flex items-center space-x-3">
            <div className="w-8.5 h-8.5 rounded-full bg-red-100 dark:bg-red-950/60 text-red-600 flex items-center justify-center shrink-0">
              <AlertTriangle className="w-4.5 h-4.5 stroke-[2]" />
            </div>
            <div>
              <h3 className="text-base sm:text-lg font-bold text-stone-900 dark:text-stone-100">
                Hapus {selectedCategories.length} Kategori
              </h3>
              <p className="text-xs sm:text-sm text-stone-500 dark:text-stone-400">
                Konfirmasi penghapusan kategori taksonomi
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            disabled={isDeleting}
            className="p-1.5 rounded-lg text-stone-400 hover:text-stone-600 dark:hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-5 h-5 stroke-[1.8]" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-4.5 overflow-y-auto flex-1">
          {inUseCategories.length > 0 && (
            <div className="p-4 bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/50 rounded-xl space-y-2">
              <div className="flex items-center space-x-2 text-amber-900 dark:text-amber-300 font-semibold text-sm">
                <AlertCircle className="w-4.5 h-4.5 shrink-0 stroke-[2]" />
                <span>Kategori Sedang Digunakan</span>
              </div>
              <p className="text-xs text-amber-800/90 dark:text-amber-300/80 font-medium">
                {inUseCategories.length} kategori tidak dapat dihapus karena masih memuat makanan:
              </p>
              <div className="flex flex-wrap gap-1.5 pt-1">
                {inUseCategories.map((c) => (
                  <span
                    key={c.id}
                    className="px-2.5 py-1 rounded-md text-xs font-semibold bg-amber-100 dark:bg-amber-900/60 text-amber-900 dark:text-amber-200"
                  >
                    {c.name} ({c.itemCount} makanan)
                  </span>
                ))}
              </div>
            </div>
          )}

          {emptyCategories.length > 0 ? (
            <div className="p-4 bg-red-50/70 dark:bg-red-950/20 border border-red-200 dark:border-red-900/40 rounded-xl">
              <p className="text-sm text-red-900 dark:text-red-300 font-medium">
                Apakah Anda yakin ingin menghapus <strong className="font-bold">{emptyCategories.length} kategori kosong</strong> berikut?
              </p>
              <div className="mt-2.5 flex flex-wrap gap-1.5">
                {emptyCategories.map((c) => (
                  <span
                    key={c.id}
                    className="px-2.5 py-1 rounded-md text-xs font-semibold bg-red-100/80 dark:bg-red-900/50 text-red-900 dark:text-red-200"
                  >
                    {c.name}
                  </span>
                ))}
              </div>
            </div>
          ) : (
            <p className="text-sm text-stone-500 dark:text-stone-400 text-center py-3">
              Semua kategori terpilih sedang memuat makanan, sehingga tidak ada yang dapat dihapus.
            </p>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end px-6 py-4 bg-stone-50/80 dark:bg-[#151C16] border-t border-stone-200 dark:border-[#222D23] space-x-3 shrink-0">
          <button
            type="button"
            onClick={onClose}
            disabled={isDeleting}
            className="px-4.5 py-2.5 text-sm font-semibold text-stone-600 dark:text-stone-300 hover:text-stone-900 dark:hover:text-white transition-colors cursor-pointer"
          >
            {t('cancel')}
          </button>
          {emptyCategories.length > 0 && (
            <button
              type="button"
              onClick={handleConfirm}
              disabled={isDeleting}
              className="px-5 py-2.5 text-sm font-bold bg-red-600 text-white hover:bg-red-700 active:scale-95 rounded-xl transition-all flex items-center space-x-2 cursor-pointer shadow-xs disabled:opacity-50"
            >
              <Trash2 className="w-4 h-4 stroke-[2]" />
              <span>
                {isDeleting
                  ? 'Menghapus...'
                  : `Hapus ${emptyCategories.length} Kategori`}
              </span>
            </button>
          )}
        </div>
      </div>
    </div>,
    document.body
  );
};
