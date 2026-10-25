import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { useAdmin } from '../../context/AdminContext';
import { FoodCategory } from '../../types';
import { Folder, X, Check } from 'lucide-react';

interface CategoryModalProps {
  isOpen: boolean;
  onClose: () => void;
  categoryToEdit?: FoodCategory | null;
}

export const CategoryModal: React.FC<CategoryModalProps> = ({
  isOpen,
  onClose,
  categoryToEdit,
}) => {
  const { addCategory, updateCategory } = useAdmin();
  const [name, setName] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  useEffect(() => {
    if (categoryToEdit) {
      setName(categoryToEdit.name);
    } else {
      setName('');
    }
  }, [categoryToEdit, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    setIsSubmitting(true);
    if (categoryToEdit) {
      await updateCategory(categoryToEdit.id, name.trim());
    } else {
      await addCategory(name.trim());
    }
    setIsSubmitting(false);
    onClose();
  };

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/60 backdrop-blur-xs overflow-y-auto animate-in fade-in duration-150">
      <div className="bg-white dark:bg-[#181E19] w-full max-w-md rounded-2xl shadow-2xl border border-[#EAECE8] dark:border-[#263226] overflow-hidden flex flex-col max-h-[calc(100vh-2rem)] my-auto">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#F2F4F0] dark:border-[#222D23] shrink-0">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 rounded-xl bg-[#0B2114] text-[#B8FF3B] flex items-center justify-center">
              <Folder className="w-4 h-4 stroke-[1.8]" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-[#111111] dark:text-[#F3F5EF]">
                {categoryToEdit ? 'Edit Category' : 'Add New Category'}
              </h3>
              <p className="text-[11px] text-gray-500 dark:text-gray-400">
                Organize verified dishes into taxonomy groups
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-4 h-4 stroke-[1.8]" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4 overflow-y-auto flex-1">
          <div>
            <label className="text-xs font-bold text-[#111111] dark:text-[#F3F5EF] mb-1.5 block">
              Category Name *
            </label>
            <input
              type="text"
              required
              autoFocus
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Minuman & Jus Sehat"
              className="w-full text-xs px-3.5 py-2.5 rounded-xl border border-gray-200 dark:border-[#303830] bg-gray-50/50 dark:bg-[#202820] text-[#111111] dark:text-[#F3F5EF] focus:outline-none focus:ring-1 focus:ring-[#B8FF3B]"
            />
          </div>

          <div className="flex items-center justify-end space-x-2 pt-2 border-t border-[#F2F4F0] dark:border-[#222D23]">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-bold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-[#222D23] rounded-xl transition-colors cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting || !name.trim()}
              className="px-5 py-2 text-xs font-black text-[#0C2417] bg-[#B8FF3B] hover:brightness-105 active:scale-95 disabled:opacity-50 rounded-xl transition-all shadow-xs flex items-center space-x-1.5 cursor-pointer"
            >
              <Check className="w-3.5 h-3.5 stroke-[2.2]" />
              <span>{categoryToEdit ? 'Save Changes' : 'Create Category'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>,
    document.body
  );
};
