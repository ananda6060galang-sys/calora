import React from 'react';
import { useAdmin } from '../../context/AdminContext';
import { Users, FileCheck, Utensils, Tags, TrendingUp } from 'lucide-react';
import { Link } from 'react-router-dom';

export const StatCards: React.FC = () => {
  const { stats } = useAdmin();

  const cards = [
    {
      title: 'Total Users',
      value: stats.totalUsers,
      subtext: '+18% this month',
      isPositive: true,
      icon: <Users className="w-5 h-5 text-calora-lavender" />,
      bg: 'bg-indigo-50/50 dark:bg-indigo-500/10',
      to: '/users',
    },
    {
      title: 'Pending Submissions',
      value: stats.pendingRequests,
      subtext: `${stats.totalRequests} total requests`,
      isPositive: stats.pendingRequests === 0,
      icon: <FileCheck className="w-5 h-5 text-amber-500" />,
      bg: 'bg-amber-50/50 dark:bg-amber-500/10',
      to: '/food-requests',
      highlight: stats.pendingRequests > 0,
    },
    {
      title: 'Verified Foods',
      value: stats.totalFoods,
      subtext: 'Public calorie database',
      isPositive: true,
      icon: <Utensils className="w-5 h-5 text-calora-accent text-[#111111] dark:text-calora-accent" />,
      bg: 'bg-lime-50/50 dark:bg-lime-500/10',
      to: '/foods',
    },
    {
      title: 'Active Categories',
      value: stats.totalCategories,
      subtext: 'Nutritional taxonomy',
      isPositive: true,
      icon: <Tags className="w-5 h-5 text-calora-protein" />,
      bg: 'bg-rose-50/50 dark:bg-rose-500/10',
      to: '/categories',
    },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {cards.map((card, i) => (
        <Link
          key={i}
          to={card.to}
          className="p-5 bg-white dark:bg-calora-dark-surface rounded-2xl border border-gray-100 dark:border-calora-dark-border hover:border-gray-300 dark:hover:border-calora-dark-border/80 shadow-xs hover:shadow-md transition-all group block"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-gray-500 dark:text-calora-dark-muted">
              {card.title}
            </span>
            <div className={`w-9 h-9 rounded-xl ${card.bg} flex items-center justify-center`}>
              {card.icon}
            </div>
          </div>

          <div className="mt-3">
            <h3 className="text-2xl font-black text-calora-light-text dark:text-calora-dark-text tracking-tight">
              {card.value}
            </h3>
            <div className="flex items-center space-x-1.5 mt-1.5">
              {card.highlight ? (
                <span className="px-2 py-0.5 text-[10px] font-bold rounded-md bg-amber-500/15 text-amber-600 dark:text-calora-warning">
                  Needs attention
                </span>
              ) : (
                <div className="flex items-center space-x-1 text-[11px] font-semibold text-calora-success">
                  <TrendingUp className="w-3.5 h-3.5" />
                  <span>{card.subtext}</span>
                </div>
              )}
            </div>
          </div>
        </Link>
      ))}
    </div>
  );
};
