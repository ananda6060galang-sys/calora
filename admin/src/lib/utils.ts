import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatTimeAgo(dateString: string, language: 'en' | 'id' = 'id'): string {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return language === 'id' ? 'Baru saja' : 'Just now';
  }
  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return language === 'id' ? `${diffInMinutes} mnt lalu` : `${diffInMinutes}m ago`;
  }
  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return language === 'id' ? `${diffInHours} jam lalu` : `${diffInHours}h ago`;
  }
  const diffInDays = Math.floor(diffInHours / 24);
  return language === 'id' ? `${diffInDays} hari lalu` : `${diffInDays}d ago`;
}

/**
 * Locale-aware date formatter using Intl.DateTimeFormat.
 * Supports en-US and id-ID dynamically with consistent styling.
 */
export function formatLocaleDate(
  dateInput?: string | Date | null,
  language: 'en' | 'id' = 'id',
  options?: Intl.DateTimeFormatOptions
): string {
  if (!dateInput) return '';
  const d = typeof dateInput === 'string' ? new Date(dateInput) : dateInput;
  if (isNaN(d.getTime())) return '';
  const locale = language === 'id' ? 'id-ID' : 'en-US';
  const defaultOpts: Intl.DateTimeFormatOptions = options || {
    day: 'numeric',
    month: 'short',
  };
  return new Intl.DateTimeFormat(locale, defaultOpts).format(d);
}

/**
 * Returns month abbreviations for all 12 months in the active locale.
 */
export function getLocaleMonthAbbr(language: 'en' | 'id' = 'id'): string[] {
  const locale = language === 'id' ? 'id-ID' : 'en-US';
  const formatter = new Intl.DateTimeFormat(locale, { month: 'short' });
  return Array.from({ length: 12 }, (_, i) => {
    const d = new Date(2026, i, 15);
    return formatter.format(d);
  });
}

export function formatDate(dateString: string): string {
  return formatLocaleDate(dateString, 'en', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}
