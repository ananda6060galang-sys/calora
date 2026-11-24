import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Food } from '../../types';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { AlertTriangle, Trash2, X } from 'lucide-react';

interface DeleteFoodConfirmModalProps {
  isOpen: boolean;
  food?: Food | null;
  foods?: Food[];
  onClose: () => void;
  onConfirm: (idOrIds: string | string[], reason: string) => Promise<void>;
}

export const DeleteFoodConfirmModal: React.FC<DeleteFoodConfirmModalProps> = ({
  isOpen,
  food,
  foods = [],
  onClose,
  onConfirm,
}) => {
  const { t } = useThemeLanguage();
  const [reason, setReason] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setReason('');
      setIsDeleting(false);
    }
  }, [isOpen]);

  const isBulk = foods.length > 0;
  if (!isOpen || (!food && !isBulk)) return null;

  const handleConfirm = async () => {
    setIsDeleting(true);
    try {
      if (isBulk) {
        await onConfirm(foods.map((f) => f.id), reason.trim());
      } else if (food) {
        await onConfirm(food.id, reason.trim());
      }
      onClose();
    } catch (e) {
      console.error('Failed to delete food:', e);
    } finally {
      setIsDeleting(false);
    }
  };

  const presetReasons = [
    'Nutrisi tidak akurat / perlu verifikasi resep standar',
    'Label porsi kurang jelas / perlu revisi gramasi',
    'Duplikasi dengan menu yang sudah ada di database',
    'Menu ditarik dari database publik',
  ];

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
                {isBulk ? `Hapus ${foods.length} Makanan` : 'Hapus Makanan'}
              </h3>
              <p className="text-xs sm:text-sm text-stone-500 dark:text-stone-400">
                {isBulk
                  ? 'Konfirmasi penghapusan massal dari database publik'
                  : 'Konfirmasi penghapusan dari database publik'}
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
          <div className="p-4 bg-red-50/70 dark:bg-red-950/20 border border-red-200 dark:border-red-900/40 rounded-xl">
            {isBulk ? (
              <div>
                <p className="text-sm text-red-900 dark:text-red-300 font-medium">
                  Apakah Anda yakin ingin menghapus <strong className="font-bold">{foods.length} makanan terpilih</strong> dari database publik?
                </p>
                <div className="mt-2.5 flex flex-wrap gap-1.5 max-h-28 overflow-y-auto pr-1">
                  {foods.map((f) => (
                    <span
                      key={f.id}
                      className="px-2.5 py-1 rounded-md text-xs font-semibold bg-red-100/80 dark:bg-red-900/50 text-red-900 dark:text-red-200"
                    >
                      {f.name}
                    </span>
                  ))}
                </div>
              </div>
            ) : food ? (
              <p className="text-sm text-red-900 dark:text-red-300 font-medium">
                Apakah Anda yakin ingin menghapus <strong className="font-bold underline">{food.name}</strong> ({food.calories} kcal · {food.serving_label})?
              </p>
            ) : null}
            <p className="text-xs text-red-700/90 dark:text-red-400/90 mt-2 font-medium">
              Jika makanan ini berasal dari pengajuan user, status pengajuannya akan diperbarui menjadi Ditolak beserta catatan alasan di bawah.
            </p>
          </div>

          <div>
            <label className="block text-sm font-semibold text-stone-800 dark:text-stone-200 mb-2">
              Alasan Penghapusan / Catatan untuk User
            </label>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Contoh: Porsi tidak sesuai atau kalori perlu diverifikasi ulang..."
              rows={2}
              className="w-full text-sm p-3.5 rounded-xl border border-stone-200 dark:border-[#2A362C] bg-white dark:bg-[#121A14] text-stone-900 dark:text-stone-100 focus:outline-none focus:ring-2 focus:ring-red-500/50 transition-colors"
            />
          </div>

          {/* Quick preset chips */}
          <div>
            <span className="text-xs font-semibold text-stone-500 dark:text-stone-400 uppercase tracking-wider block mb-2">
              Pilihan Cepat Alasan:
            </span>
            <div className="flex flex-wrap gap-2">
              {presetReasons.map((p) => (
                <button
                  key={p}
                  type="button"
                  onClick={() => setReason(p)}
                  className="text-xs px-3 py-1.5 rounded-lg bg-stone-100 dark:bg-[#202B22] text-stone-700 dark:text-stone-300 hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-950/40 dark:hover:text-red-400 font-medium transition-colors cursor-pointer text-left"
                >
                  {p}
                </button>
              ))}
            </div>
          </div>
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
                : isBulk
                ? `Hapus ${foods.length} Makanan`
                : 'Hapus Makanan'}
            </span>
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
};
