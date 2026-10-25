import { supabase } from '../lib/supabase';
import { Profile } from '../types';

export const userService = {
  async getAll(): Promise<Profile[]> {
    const { data, error } = await supabase
      .from('profiles')
      .select('id, full_name, email, role, created_at, avatar_url, is_blocked')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching users from Supabase:', error);
      throw error;
    }

    return (data || []).map((p: any) => ({
      id: p.id,
      name: p.full_name || 'Calora User',
      email: p.email || undefined,
      role: p.role,
      created_at: p.created_at,
      avatar_url: p.avatar_url,
      is_active: !p.is_blocked,
      is_blocked: p.is_blocked ?? false,
    })) as Profile[];
  },

  async toggleBlockUser(userId: string, isBlocked: boolean): Promise<boolean> {
    const { error } = await supabase
      .from('profiles')
      .update({
        is_blocked: isBlocked,
        updated_at: new Date().toISOString(),
      })
      .eq('id', userId);

    if (error) {
      console.error('Error updating user block status in Supabase:', error);
      throw error;
    }

    return true;
  },
};
