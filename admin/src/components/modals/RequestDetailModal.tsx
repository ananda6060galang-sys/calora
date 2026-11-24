import React, { useState } from 'react';
import { createPortal } from 'react-dom';
import { FoodRequest } from '../../types';
import { useAdmin } from '../../context/AdminContext';
import { useThemeLanguage } from '../../context/ThemeLanguageContext';
import {
  FileText,
  X,
  Check,
  AlertCircle,
  Clock,
} from 'lucide-react';
import { formatDate } from '../../lib/utils';

interface RequestDetailModalProps {
  request: FoodRequest | null;
  isOpen: boolean;
  onClose: () => void;
}

export const RequestDetailModal: React.FC<RequestDetailModalProps> = ({
  request,
  isOpen,
  onClose,
}) => {
  const { approveRequest, rejectRequest, users } = useAdmin();
  const { t } = useThemeLanguage();
  const [rejectReason, setRejectReason] = useState(
    'Nutritional breakdown requires standard recipe or manufacturer packaging verification.'
  );
  const [isRejecting, setIsRejecting] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!isOpen || !request) return null;

  const submitterName =
    request.submitter_name && request.submitter_name !== 'Community Member'
      ? request.submitter_name
      : users.find((u) => u.id === request.user_id)?.name || request.submitter_name || 'Calora User';

  const submitterAvatar =
    request.submitter_avatar || users.find((u) => u.id === request.user_id)?.avatar_url;

  const handleApprove = async () => {
    setIsSubmitting(true);
    await approveRequest(request.id);
    setIsSubmitting(false);
    onClose();
  };

  const handleReject = async () => {
    setIsSubmitting(true);
    await rejectRequest(request.id, rejectReason.trim());
    setIsSubmitting(false);
    setIsRejecting(false);
    onClose();
  };

  const isPending = request.status === 'pending';

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/60 backdrop-blur-xs overflow-y-auto animate-in fade-in duration-150">
      <div className="bg-white dark:bg-[#181E19] w-full max-w-lg rounded-2xl shadow-2xl border border-[#EAECE8] dark:border-[#263226] overflow-hidden flex flex-col max-h-[calc(100vh-2rem)] my-auto">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#F2F4F0] dark:border-[#222D23] shrink-0">
          <div className="flex items-center space-x-3">
            <FileText className="w-5 h-5 text-[#16A34A] dark:text-[#3DDC84] stroke-[1.8]" />
            <div>
              <h3 className="text-base sm:text-lg font-bold text-stone-900 dark:text-stone-100">
                {t('reviewModalTitle')}
              </h3>
              <p className="text-xs font-mono font-medium text-stone-500 dark:text-stone-400">
                {t('requestId')}: {request.id}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-stone-400 hover:text-stone-600 dark:hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-5 h-5 stroke-[1.8]" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-5 max-h-[75vh] overflow-y-auto">
          <div>
            <div className="flex items-start justify-between">
              <div>
                <h2 className="text-xl sm:text-2xl font-bold tracking-tight text-stone-900 dark:text-stone-100">
                  {request.food_name}
                </h2>
                <p className="text-sm font-medium text-stone-600 dark:text-stone-300 mt-0.5">
                  {t('portionLabel')}: {request.serving_label}
                </p>
              </div>
              <span
                className={`px-3 py-1 text-xs font-semibold rounded-full capitalize ${
                  request.status === 'approved'
                    ? 'bg-[#EBF7EE] dark:bg-[#14331C] text-[#16A34A] dark:text-[#3DDC84]'
                    : request.status === 'rejected'
                    ? 'bg-[#FFEBEA] dark:bg-[#381617] text-[#DC2626] dark:text-[#FF5A5F]'
                    : 'bg-[#FFF8E7] dark:bg-[#332612] text-[#D97706] dark:text-[#FFB020]'
                }`}
              >
                {request.status === 'approved'
                  ? t('approvedStatus')
                  : request.status === 'rejected'
                  ? t('rejectedStatus')
                  : t('pendingStatus')}
              </span>
            </div>
          </div>

          {/* Macro Breakdown */}
          <div className="bg-stone-50 dark:bg-[#202820] p-4.5 rounded-xl border border-stone-200/80 dark:border-[#263226]">
            <p className="text-xs font-bold text-stone-500 dark:text-stone-400 tracking-wider uppercase mb-3">
              {t('nutritionalValues')}
            </p>
            <div className="grid grid-cols-4 gap-2 text-center">
              <div className="p-2">
                <span className="text-xs font-semibold text-stone-600 dark:text-stone-300 block">
                  Calories
                </span>
                <span className="text-xl font-bold text-stone-900 dark:text-stone-100">
                  {request.calories}
                </span>
                <span className="text-xs font-medium text-stone-500 dark:text-stone-400 block">kcal</span>
              </div>
              <div className="p-2">
                <span className="text-xs font-bold text-[#FF6B57] block">
                  {t('proteinLabel')}
                </span>
                <span className="text-xl font-bold text-[#FF6B57]">
                  {request.protein_g}
                </span>
                <span className="text-xs font-medium text-stone-500 dark:text-stone-400 block">g</span>
              </div>
              <div className="p-2">
                <span className="text-xs font-bold text-[#FFA048] block">
                  {t('carbsLabel')}
                </span>
                <span className="text-xl font-bold text-[#FFA048]">
                  {request.carbs_g}
                </span>
                <span className="text-xs font-medium text-stone-500 dark:text-stone-400 block">g</span>
              </div>
              <div className="p-2">
                <span className="text-xs font-bold text-[#7C9CFF] block">
                  {t('fatLabel')}
                </span>
                <span className="text-xl font-bold text-[#7C9CFF]">
                  {request.fat_g}
                </span>
                <span className="text-xs font-medium text-stone-500 dark:text-stone-400 block">g</span>
              </div>
            </div>
          </div>

          {/* Contributor Metadata */}
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div className="flex items-center space-x-2.5 text-stone-600 dark:text-stone-300">
              <div className="relative w-6 h-6 rounded-full flex items-center justify-center font-bold text-xs shrink-0 bg-emerald-50 dark:bg-[#14331C] text-[#16A34A] dark:text-[#3DDC84] overflow-hidden">
                {submitterAvatar ? (
                  <img
                    src={submitterAvatar}
                    alt={submitterName}
                    className="w-full h-full object-cover rounded-full absolute inset-0"
                    onError={(e) => {
                      (e.currentTarget as HTMLElement).style.display = 'none';
                    }}
                  />
                ) : null}
                <span>{submitterName?.[0]?.toUpperCase() || 'U'}</span>
              </div>
              <span className="truncate">
                {t('submittedByLabel')}:{' '}
                <strong className="text-stone-900 dark:text-stone-100 font-semibold">
                  {submitterName}
                </strong>
              </span>
            </div>
            <div className="flex items-center space-x-2 text-stone-600 dark:text-stone-300">
              <Clock className="w-4.5 h-4.5 text-stone-400 stroke-[1.8]" />
              <span>
                {t('requestDateLabel')}:{' '}
                <strong className="text-stone-900 dark:text-stone-100 font-semibold">
                  {formatDate(request.created_at)}
                </strong>
              </span>
            </div>
          </div>

          {/* User Notes */}
          {request.notes && (
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider text-stone-500 dark:text-stone-400 mb-1.5">
                {t('submissionNotes')}
              </p>
              <div className="p-3.5 bg-stone-50 dark:bg-[#202820] rounded-xl text-sm italic text-stone-700 dark:text-stone-300 border border-stone-200/80 dark:border-[#263226]">
                "{request.notes}"
              </div>
            </div>
          )}

          {/* Rejection Input */}
          {isRejecting && (
            <div className="space-y-2 pt-2 border-t border-stone-200 dark:border-[#263226]">
              <label className="text-sm font-semibold text-red-600 dark:text-red-400 flex items-center space-x-1.5">
                <AlertCircle className="w-4 h-4 stroke-[2]" />
                <span>{t('rejectReasonPrompt')}</span>
              </label>
              <textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                rows={2}
                className="w-full text-sm p-3 rounded-xl border border-red-300 dark:border-red-800 bg-red-50/50 dark:bg-[#2a1718] text-stone-900 dark:text-stone-100 focus:outline-none focus:ring-2 focus:ring-red-500/50"
                placeholder="Explain why this dish submission does not meet verification standards..."
              />
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <div className="flex items-center justify-end px-6 py-4 bg-stone-50/80 dark:bg-[#151C16] border-t border-stone-200 dark:border-[#222D23] space-x-3">
          <button
            onClick={onClose}
            className="px-4.5 py-2.5 text-sm font-semibold text-stone-600 dark:text-stone-300 hover:text-stone-900 dark:hover:text-white transition-colors cursor-pointer"
          >
            {t('cancel')}
          </button>

          {isPending && (
            <>
              {!isRejecting ? (
                <>
                  <button
                    onClick={() => setIsRejecting(true)}
                    disabled={isSubmitting}
                    className="px-4.5 py-2.5 text-sm font-bold text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/40 border border-red-300 dark:border-red-800 rounded-xl transition-colors flex items-center space-x-1.5 cursor-pointer"
                  >
                    <X className="w-4 h-4 stroke-[2]" />
                    <span>{t('rejectSubmission')}</span>
                  </button>
                  <button
                    onClick={handleApprove}
                    disabled={isSubmitting}
                    className="px-5 py-2.5 text-sm font-bold bg-[#B8FF3B] text-[#0C2417] hover:brightness-105 active:scale-95 rounded-xl shadow-xs transition-all flex items-center space-x-1.5 cursor-pointer"
                  >
                    <Check className="w-4 h-4 text-[#0C2417] stroke-[2.5]" />
                    <span>{t('approveAndPublish')}</span>
                  </button>
                </>
              ) : (
                <button
                  onClick={handleReject}
                  disabled={isSubmitting}
                  className="px-5 py-2.5 text-sm font-bold bg-red-600 text-white hover:bg-red-700 rounded-xl transition-colors flex items-center space-x-1.5 cursor-pointer"
                >
                  <span>{t('confirmReject')}</span>
                </button>
              )}
            </>
          )}
        </div>
      </div>
    </div>,
    document.body
  );
};
