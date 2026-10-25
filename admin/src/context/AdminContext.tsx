import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  Profile,
  Food,
  FoodCategory,
  FoodRequest,
  AdminActivity,
  DashboardStats,
} from '../types';
import { authService } from '../services/authService';
import { foodRequestService } from '../services/foodRequestService';
import { foodService } from '../services/foodService';
import { categoryService } from '../services/categoryService';
import { userService } from '../services/userService';
import { INITIAL_ACTIVITIES } from '../lib/mockData';
import { supabase } from '../lib/supabase';

interface Toast {
  id: string;
  message: string;
  type: 'success' | 'warning' | 'danger' | 'info';
}

interface AdminContextType {
  user: Profile | null;
  isLoading: boolean;
  searchQuery: string;
  setSearchQuery: (query: string) => void;
  requestStatusFilter: string;
  setRequestStatusFilter: (status: string) => void;
  foodCategoryFilter: string;
  setFoodCategoryFilter: (category: string) => void;
  requests: FoodRequest[];
  foods: Food[];
  categories: FoodCategory[];
  users: Profile[];
  activities: AdminActivity[];
  stats: DashboardStats;
  urgentRequests: FoodRequest[];
  filteredRequests: FoodRequest[];
  filteredFoods: Food[];
  toasts: Toast[];
  dismissToast: (id: string) => void;
  approveRequest: (requestId: string) => Promise<void>;
  rejectRequest: (requestId: string, reason: string) => Promise<void>;
  addFood: (food: Omit<Food, 'id'>) => Promise<void>;
  updateFood: (id: string, updates: Partial<Food>) => Promise<void>;
  deleteFood: (id: string, reason?: string) => Promise<void>;
  deleteFoods: (ids: string[], reason?: string) => Promise<void>;
  addCategory: (name: string) => Promise<void>;
  updateCategory: (id: string, name: string) => Promise<void>;
  deleteCategory: (id: string) => Promise<void>;
  deleteCategories: (ids: string[]) => Promise<void>;
  approveRequests: (ids: string[]) => Promise<void>;
  rejectRequests: (ids: string[], reason: string) => Promise<void>;
  deleteRequests: (ids: string[]) => Promise<void>;
  toggleBlockUser: (userId: string, isBlocked: boolean) => Promise<void>;
  refreshAll: () => Promise<void>;
  logout: () => Promise<void>;
  setUser: (u: Profile | null) => void;
}

const AdminContext = createContext<AdminContextType | undefined>(undefined);

export const AdminProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<Profile | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [requestStatusFilter, setRequestStatusFilter] = useState<string>('all');
  const [foodCategoryFilter, setFoodCategoryFilter] = useState<string>('all');

  const [requests, setRequests] = useState<FoodRequest[]>([]);
  const [foods, setFoods] = useState<Food[]>([]);
  const [categories, setCategories] = useState<FoodCategory[]>([]);
  const [users, setUsers] = useState<Profile[]>([]);
  const [activities, setActivities] = useState<AdminActivity[]>(INITIAL_ACTIVITIES);
  const [toasts, setToasts] = useState<Toast[]>([]);

  const showToast = (message: string, type: Toast['type'] = 'info') => {
    const id = `toast_${Date.now()}`;
    setToasts((prev) => [...prev, { id, message, type }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 4000);
  };

  const dismissToast = (id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  };

  const addActivity = (title: string, description: string, type: AdminActivity['type']) => {
    const newAct: AdminActivity = {
      id: `act_${Date.now()}`,
      title,
      description,
      type,
      timestamp: new Date().toISOString(),
    };
    setActivities((prev) => [newAct, ...prev]);
  };

  const loadData = async () => {
    try {
      setIsLoading(true);
      const [currentUser, allRequests, allFoods, allCategories, allUsers] = await Promise.all([
        authService.getCurrentUser(),
        foodRequestService.getAll(),
        foodService.getAll(),
        categoryService.getAll(),
        userService.getAll(),
      ]);

      setUser(currentUser);
      setRequests(allRequests);
      setFoods(allFoods);
      setCategories(allCategories);
      setUsers(allUsers);
    } catch (err) {
      console.error('Error loading admin data:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      if ((event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') && session?.user) {
        await loadData();
      } else if (event === 'SIGNED_OUT') {
        setUser(null);
        setRequests([]);
        setFoods([]);
        setCategories([]);
        setUsers([]);
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const approveRequest = async (requestId: string) => {
    try {
      const result = await foodRequestService.approve(requestId);
      if (result) {
        setRequests((prev) =>
          prev.map((r) => (r.id === requestId ? result.updatedRequest : r))
        );
        if (result.createdFood) {
          setFoods((prev) => [result.createdFood, ...prev]);
        }

        addActivity(
          'Food request approved',
          `Admin approved "${result.updatedRequest.food_name}" into the public verified food catalog.`,
          'approved'
        );
        showToast(`Approved "${result.updatedRequest.food_name}" into public verified catalog.`, 'success');
      }
    } catch (err: any) {
      console.error('Failed to approve request:', err);
      showToast(`Failed to approve request: ${err.message || 'Error'}`, 'danger');
    }
  };

  const rejectRequest = async (requestId: string, reason: string) => {
    try {
      const updated = await foodRequestService.reject(requestId, reason);
      if (updated) {
        setRequests((prev) => prev.map((r) => (r.id === requestId ? updated : r)));
        addActivity(
          'Food request rejected',
          `Admin rejected "${updated.food_name}": ${reason || 'Criteria not met'}.`,
          'rejected'
        );
        showToast(`Rejected "${updated.food_name}". Reason recorded.`, 'warning');
      }
    } catch (err: any) {
      console.error('Failed to reject request:', err);
      showToast(`Failed to reject request: ${err.message || 'Error'}`, 'danger');
    }
  };

  const addFood = async (food: Omit<Food, 'id'>) => {
    const created = await foodService.create(food);
    setFoods((prev) => [created, ...prev]);
    addActivity(
      'New verified food added',
      `Admin published "${food.name}" (${food.calories} kcal) directly to the catalog.`,
      'foodAdded'
    );
    showToast(`Published "${food.name}" to verified database.`, 'success');
  };

  const updateFood = async (id: string, updates: Partial<Food>) => {
    const updated = await foodService.update(id, updates);
    if (updated) {
      setFoods((prev) => prev.map((f) => (f.id === id ? updated : f)));
      showToast(`Updated "${updated.name}" successfully.`, 'success');
    }
  };

  const deleteFood = async (id: string, reason?: string) => {
    const target = foods.find((f) => f.id === id);
    await foodService.delete(id, reason);
    setFoods((prev) => prev.filter((f) => f.id !== id));
    if (target) {
      setRequests((prev) =>
        prev.map((r) =>
          r.food_name.toLowerCase() === target.name.toLowerCase() && r.status === 'approved'
            ? {
                ...r,
                status: 'rejected',
                notes: reason?.trim()
                  ? `Makanan dihapus dari database publik: ${reason.trim()}`
                  : 'Makanan telah dihapus oleh admin dari database publik.',
              }
            : r
        )
      );
      addActivity(
        'Food removed from catalog',
        `Admin removed "${target.name}": ${reason || 'Removed from database'}.`,
        'rejected'
      );
      showToast(`Deleted "${target.name}" from catalog.`, 'danger');
    }
  };

  const addCategory = async (name: string) => {
    const created = await categoryService.create(name);
    setCategories((prev) => [...prev, created]);
    showToast(`Added category "${created.name}".`, 'success');
  };

  const updateCategory = async (id: string, name: string) => {
    const updated = await categoryService.update(id, name);
    if (updated) {
      setCategories((prev) => prev.map((c) => (c.id === id ? updated : c)));
      showToast(`Updated category "${updated.name}".`, 'success');
    }
  };

  const deleteCategory = async (id: string) => {
    const target = categories.find((c) => c.id === id);
    await categoryService.delete(id);
    setCategories((prev) => prev.filter((c) => c.id !== id));
    if (target) {
      showToast(`Deleted category "${target.name}".`, 'info');
    }
  };

  const deleteFoods = async (ids: string[], reason?: string) => {
    if (ids.length === 0) return;
    const targetFoods = foods.filter((f) => ids.includes(f.id));
    const targetNames = targetFoods.map((f) => f.name.toLowerCase());
    await foodService.deleteMultiple(ids, reason);
    setFoods((prev) => prev.filter((f) => !ids.includes(f.id)));
    if (targetNames.length > 0) {
      setRequests((prev) =>
        prev.map((r) =>
          targetNames.includes(r.food_name.toLowerCase()) && r.status === 'approved'
            ? {
                ...r,
                status: 'rejected',
                notes: reason?.trim()
                  ? `Makanan dihapus dari database publik: ${reason.trim()}`
                  : 'Makanan telah dihapus oleh admin dari database publik.',
              }
            : r
        )
      );
    }
    showToast(`Deleted ${ids.length} items from catalog.`, 'danger');
  };

  const deleteCategories = async (ids: string[]) => {
    if (ids.length === 0) return;
    await categoryService.deleteMultiple(ids);
    setCategories((prev) => prev.filter((c) => !ids.includes(c.id)));
    showToast(`Deleted ${ids.length} categories.`, 'info');
  };

  const approveRequests = async (ids: string[]) => {
    if (ids.length === 0) return;
    const { approvedIds, createdFoods } = await foodRequestService.approveMultiple(ids);
    setRequests((prev) =>
      prev.map((r) => (approvedIds.includes(r.id) ? { ...r, status: 'approved' } : r))
    );
    if (createdFoods.length > 0) {
      setFoods((prev) => [...createdFoods, ...prev]);
    }
    showToast(`Approved ${approvedIds.length} requests into public database.`, 'success');
  };

  const rejectRequests = async (ids: string[], reason: string) => {
    if (ids.length === 0) return;
    const rejectedIds = await foodRequestService.rejectMultiple(ids, reason);
    setRequests((prev) =>
      prev.map((r) => (rejectedIds.includes(r.id) ? { ...r, status: 'rejected', notes: reason } : r))
    );
    showToast(`Rejected ${rejectedIds.length} requests.`, 'warning');
  };

  const deleteRequests = async (ids: string[]) => {
    if (ids.length === 0) return;
    await foodRequestService.deleteMultiple(ids);
    setRequests((prev) => prev.filter((r) => !ids.includes(r.id)));
    showToast(`Deleted ${ids.length} requests.`, 'info');
  };

  const toggleBlockUser = async (userId: string, isBlocked: boolean) => {
    const targetUser = users.find((u) => u.id === userId);
    if (targetUser && targetUser.role === 'admin') {
      showToast('Cannot block an administrator account.', 'warning');
      return;
    }

    try {
      await userService.toggleBlockUser(userId, isBlocked);
      setUsers((prev) =>
        prev.map((u) =>
          u.id === userId
            ? { ...u, is_blocked: isBlocked, is_active: !isBlocked }
            : u
        )
      );

      const userName = targetUser?.name || 'User';
      if (isBlocked) {
        addActivity(
          'User Suspended',
          `Account for "${userName}" was blocked by administrator.`,
          'rejected'
        );
        showToast(`User "${userName}" has been blocked.`, 'warning');
      } else {
        addActivity(
          'User Reinstated',
          `Account for "${userName}" was unblocked by administrator.`,
          'approved'
        );
        showToast(`User "${userName}" has been unblocked.`, 'success');
      }
    } catch (err) {
      console.error('Failed to toggle block status:', err);
      showToast('Failed to update user block status.', 'danger');
    }
  };

  const logout = async () => {
    try {
      await authService.logout();
    } catch (e) {
      console.error('Logout error:', e);
    } finally {
      setUser(null);
      setRequests([]);
      setFoods([]);
      setCategories([]);
      setUsers([]);
    }
  };

  // Computed metrics
  const stats: DashboardStats = {
    totalUsers: users.length,
    totalRequests: requests.length,
    pendingRequests: requests.filter((r) => r.status === 'pending').length,
    approvedRequests: requests.filter((r) => r.status === 'approved').length,
    rejectedRequests: requests.filter((r) => r.status === 'rejected').length,
    totalFoods: foods.length,
    totalCategories: categories.length,
  };

  const urgentRequests = requests.filter((r) => r.status === 'pending').slice(0, 4);

  const filteredRequests = requests.filter((r) => {
    if (requestStatusFilter !== 'all' && r.status !== requestStatusFilter) {
      return false;
    }
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        r.food_name.toLowerCase().includes(q) ||
        r.user_id.toLowerCase().includes(q) ||
        (r.notes && r.notes.toLowerCase().includes(q))
      );
    }
    return true;
  });

  const filteredFoods = foods.filter((f) => {
    if (foodCategoryFilter !== 'all' && f.category !== foodCategoryFilter) {
      return false;
    }
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        f.name.toLowerCase().includes(q) ||
        (f.category && f.category.toLowerCase().includes(q))
      );
    }
    return true;
  });

  return (
    <AdminContext.Provider
      value={{
        user,
        isLoading,
        searchQuery,
        setSearchQuery,
        requestStatusFilter,
        setRequestStatusFilter,
        foodCategoryFilter,
        setFoodCategoryFilter,
        requests,
        foods,
        categories,
        users,
        activities,
        stats,
        urgentRequests,
        filteredRequests,
        filteredFoods,
        toasts,
        dismissToast,
        approveRequest,
        rejectRequest,
        addFood,
        updateFood,
        deleteFood,
        deleteFoods,
        addCategory,
        updateCategory,
        deleteCategory,
        deleteCategories,
        approveRequests,
        rejectRequests,
        deleteRequests,
        toggleBlockUser,
        refreshAll: loadData,
        logout,
        setUser,
      }}
    >
      {children}
    </AdminContext.Provider>
  );
};

export const useAdmin = () => {
  const context = useContext(AdminContext);
  if (!context) {
    throw new Error('useAdmin must be used within an AdminProvider');
  }
  return context;
};
