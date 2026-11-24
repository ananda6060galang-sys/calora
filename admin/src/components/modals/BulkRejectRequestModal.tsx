import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import { XCircle, X } from 'lucide-react';

interface BulkRejectRequestModalProps {
  isOpen: boolean;
  count: number;
  onClose: () => void;
  onConfirm: (reason: string) => Promise<void>;
}

export const BulkRejectRequestModal: React.FC<BulkRejectRequestModalProps> = ({
  isOpen,
  count,
  onClose,
  onConfirm,
}) => {
  const { t } = useThemeLanguage();
  const [reason, setReason] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setReason('');
      setIsSubmitting(false);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleConfirm = async () => {
    setIsSubmitting(true);
    try {
      await onConfirm(reason.trim());
      onClose();
    } catch (e) {
      console.error('Failed to reject requests:', e);
    } finally {
      setIsSubmitting(false);
    }
  };

  const presetReasons = [
    'Foto makanan buram atau tidak menunjukkan hidangan yang dimaksud',
    'Duplikasi dengan makanan yang sudah ada di database',
    'Nama makanan tidak spesifik atau informasi gramasi kurang lengkap',
  ];

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/60 backdrop-blur-xs overflow-y-auto animate-in fade-in duration-150">
      <div className="bg-white dark:bg-[#181E19] w-full max-w-md rounded-2xl shadow-2xl border border-[#EAECE8] dark:border-[#263226] overflow-hidden flex flex-col max-h-[calc(100vh-2rem)] my-auto">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4.5 border-b border-[#F2F4F0] dark:border-[#222D23] shrink-0">
          <div className="flex items-center space-x-3">
            <div className="w-8.5 h-8.5 rounded-full bg-red-100 dark:bg-red-950/60 text-red-600 flex items-center justify-center shrink-0">
              <XCircle className="w-4.5 h-4.5 stroke-[2]" />
            </div>
            <div>
              <h3 className="text-base sm:text-lg font-bold text-stone-900 dark:text-stone-100">
                Tolak {count} Permintaan
              </h3>
              <p className="text-xs sm:text-sm text-stone-500 dark:text-stone-400">
                Berikan catatan penolakan untuk pengguna
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            disabled={isSubmitting}
            className="p-1.5 rounded-lg text-stone-400 hover:text-stone-600 dark:hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-5 h-5 stroke-[1.8]" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-4.5 overflow-y-auto flex-1">
          <div>
            <label className="block text-sm font-semibold text-stone-800 dark:text-stone-200 mb-2">
              Alasan Penolakan / Catatan untuk User
            </label>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Jelaskan alasan penolakan agar user dapat merevisi..."
              rows={2}
              className="w-full text-sm p-3.5 rounded-xl border border-stone-200 dark:border-[#2A362C] bg-white dark:bg-[#121A14] text-stone-900 dark:text-stone-100 focus:outline-none focus:ring-2 focus:ring-red-500/50 transition-colors"
            />
          </div>

          {/* Quick preset chips */}
          <div>
            <span className="text-xs font-semibold text-stone-500 dark:text-stone-400 uppercase tracking-wider block mb-2">
              Pilihan Cepat:
            </span>
            <div className="flex flex-wrap gap-2">
              {presetReasons.map((p) => (
                <button
                  key={p}
                  type="button"
                  onClick={() => setReason(p)}
                  className="text-xs px-3 py-1.5 rounded-lg bg-stone-100 dark:bg-[#202B22] text-stone-700 dark:text-stone-300 font-medium hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-950/40 dark:hover:text-red-400 transition-colors cursor-pointer text-left"
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
            disabled={isSubmitting}
            className="px-4.5 py-2.5 text-sm font-semibold text-stone-600 dark:text-stone-300 hover:text-stone-900 dark:hover:text-white transition-colors cursor-pointer"
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            onClick={handleConfirm}
            disabled={isSubmitting}
            className="px-5 py-2.5 text-sm font-bold bg-red-600 text-white hover:bg-red-700 active:scale-95 rounded-xl transition-all flex items-center space-x-2 cursor-pointer shadow-xs disabled:opacity-50"
          >
            <XCircle className="w-4 h-4 stroke-[2]" />
            <span>{isSubmitting ? 'Memproses...' : `Tolak ${count} Permintaan`}</span>
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
};
