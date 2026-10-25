import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { CheckCircle2, AlertTriangle, XCircle, Info, X } from 'lucide-react';

export const ToastContainer: React.FC = () => {
  const { toasts, dismissToast } = useAdmin();

  if (toasts.length === 0) return null;

  return (
    <div className="fixed bottom-6 right-6 z-50 flex flex-col space-y-3 pointer-events-none max-w-sm w-full">
      {toasts.map((toast) => {
        let icon = <Info className="w-5 h-5 text-blue-500" />;
        let border = 'border-gray-200 dark:border-calora-dark-border';

        if (toast.type === 'success') {
          icon = <CheckCircle2 className="w-5 h-5 text-calora-success" />;
          border = 'border-calora-success/30';
        } else if (toast.type === 'warning') {
          icon = <AlertTriangle className="w-5 h-5 text-calora-warning" />;
          border = 'border-calora-warning/30';
        } else if (toast.type === 'danger') {
          icon = <XCircle className="w-5 h-5 text-calora-danger" />;
          border = 'border-calora-danger/30';
        }

        return (
          <div
            key={toast.id}
            className={`pointer-events-auto flex items-center justify-between p-4 bg-white dark:bg-calora-dark-surface shadow-lg rounded-xl border ${border} animate-in fade-in slide-in-from-bottom-5 duration-200`}
          >
            <div className="flex items-center space-x-3">
              {icon}
              <p className="text-xs font-semibold text-calora-light-text dark:text-calora-dark-text">
                {toast.message}
              </p>
            </div>
            <button
              onClick={() => dismissToast(toast.id)}
              className="p-1 rounded-md text-gray-400 hover:text-gray-600 dark:hover:text-white transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        );
      })}
    </div>
  );
};
