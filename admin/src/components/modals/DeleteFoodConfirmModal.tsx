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
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#F2F4F0] dark:border-[#222D23] shrink-0">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 rounded-full bg-red-100 dark:bg-red-950/60 text-red-600 flex items-center justify-center shrink-0">
              <AlertTriangle className="w-4 h-4 stroke-[2]" />
            </div>
            <div>
              <h3 className="text-base font-bold text-[#111111] dark:text-[#F3F5EF]">
                {isBulk ? `Hapus ${foods.length} Makanan` : 'Hapus Makanan'}
              </h3>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                {isBulk
                  ? 'Konfirmasi penghapusan massal dari database publik'
                  : 'Konfirmasi penghapusan dari database publik'}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            disabled={isDeleting}
            className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-5 h-5 stroke-[1.8]" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-4 overflow-y-auto flex-1">
          <div className="p-3.5 bg-red-50/70 dark:bg-red-950/20 border border-red-200 dark:border-red-900/40 rounded-xl">
            {isBulk ? (
              <div>
                <p className="text-xs text-red-800 dark:text-red-300">
                  Apakah Anda yakin ingin menghapus <strong className="font-bold">{foods.length} makanan terpilih</strong> dari database publik?
                </p>
                <div className="mt-2 flex flex-wrap gap-1 max-h-24 overflow-y-auto pr-1">
                  {foods.map((f) => (
                    <span
                      key={f.id}
                      className="px-2 py-0.5 rounded-md text-[10px] font-semibold bg-red-100/80 dark:bg-red-900/50 text-red-800 dark:text-red-200"
                    >
                      {f.name}
                    </span>
                  ))}
                </div>
              </div>
            ) : food ? (
              <p className="text-xs text-red-800 dark:text-red-300">
                Apakah Anda yakin ingin menghapus <strong className="font-bold underline">{food.name}</strong> ({food.calories} kcal · {food.serving_label})?
              </p>
            ) : null}
            <p className="text-[11px] text-red-700/80 dark:text-red-400/80 mt-2">
              Jika makanan ini berasal dari pengajuan user, status pengajuannya akan diperbarui menjadi Ditolak beserta catatan alasan di bawah.
            </p>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
              Alasan Penghapusan / Catatan untuk User
            </label>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Contoh: Porsi tidak sesuai atau kalori perlu diverifikasi ulang..."
              rows={2}
              className="w-full text-xs p-3 rounded-xl border border-gray-200 dark:border-[#2A362C] bg-white dark:bg-[#121A14] text-[#111111] dark:text-[#F3F5EF] focus:outline-none focus:ring-1 focus:ring-red-500 transition-colors"
            />
          </div>

          {/* Quick preset chips */}
          <div>
            <span className="text-[10px] font-medium text-gray-400 uppercase tracking-wider block mb-1.5">
              Pilihan Cepat Alasan:
            </span>
            <div className="flex flex-wrap gap-1.5">
              {presetReasons.map((p) => (
                <button
                  key={p}
                  type="button"
                  onClick={() => setReason(p)}
                  className="text-[11px] px-2.5 py-1 rounded-lg bg-gray-100 dark:bg-[#202B22] text-gray-700 dark:text-gray-300 hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-950/40 dark:hover:text-red-400 transition-colors cursor-pointer text-left"
                >
                  {p}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end px-6 py-4 bg-gray-50/70 dark:bg-[#151C16] border-t border-gray-100 dark:border-[#222D23] space-x-3 shrink-0">
          <button
            type="button"
            onClick={onClose}
            disabled={isDeleting}
            className="px-4 py-2 text-xs font-semibold text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors cursor-pointer"
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            onClick={handleConfirm}
            disabled={isDeleting}
            className="px-5 py-2 text-xs font-bold bg-red-600 text-white hover:bg-red-700 active:scale-95 rounded-xl transition-all flex items-center space-x-1.5 cursor-pointer shadow-xs disabled:opacity-50"
          >
            <Trash2 className="w-3.5 h-3.5 stroke-[2]" />
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
