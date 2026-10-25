export type UserRole = 'admin' | 'user';

export type FoodRequestStatus = 'pending' | 'approved' | 'rejected';

export interface Profile {
  id: string;
  name: string;
  email?: string;
  role: UserRole;
  date_of_birth?: string;
  gender?: 'male' | 'female';
  height_cm?: number;
  weight_kg?: number;
  activity_level?: string;
  goal?: string;
  created_at?: string;
  submissions_count?: number;
  avatar_url?: string;
  is_active?: boolean;
  is_blocked?: boolean;
}

export interface FoodCategory {
  id: string;
  name: string;
  created_at?: string;
}

export interface Food {
  id: string;
  category_id?: string;
  category?: string;
  name: string;
  serving_label: string;
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  portion_grams?: number;
  source: string;
  created_at?: string;
}

export interface FoodRequest {
  id: string;
  user_id: string;
  submitter_name?: string;
  submitter_avatar?: string;
  image_url?: string;
  category_id?: string;
  category_name?: string;
  category?: string;
  food_name: string;
  serving_label: string;
  serving_size?: number;
  serving_unit?: string;
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  status: FoodRequestStatus;
  notes?: string;
  created_at: string;
}

export type ActivityType =
  | 'approved'
  | 'rejected'
  | 'submission'
  | 'foodAdded'
  | 'userJoined';

export interface AdminActivity {
  id: string;
  title: string;
  description: string;
  type: ActivityType;
  timestamp: string;
}

export interface DashboardStats {
  totalUsers: number;
  totalRequests: number;
  pendingRequests: number;
  approvedRequests: number;
  rejectedRequests: number;
  totalFoods: number;
  totalCategories: number;
  aiScannerAccuracy?: number;
}
