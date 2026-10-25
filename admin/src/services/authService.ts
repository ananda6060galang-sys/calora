import { supabase } from '../lib/supabase';
import { Profile } from '../types';

export interface AuthState {
  user: Profile | null;
  isAuthenticated: boolean;
  isAdmin: boolean;
}

export const authService = {
  async getCurrentUser(): Promise<Profile | null> {
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (!session?.user) {
        return null;
      }

      const { data: profile, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .single();

      if (error || !profile) {
        return null;
      }

      if (profile.role !== 'admin') {
        return null;
      }

      return {
        id: profile.id,
        name: profile.full_name || session.user.email?.split('@')[0] || 'Admin',
        email: session.user.email,
        role: 'admin',
        avatar_url: profile.avatar_url,
        is_active: true,
      };
    } catch {
      return null;
    }
  },

  async login(email: string, password: string): Promise<{ user: Profile | null; error?: string }> {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password: password.trim(),
      });

      if (error || !data.user) {
        return { user: null, error: error?.message || 'Authentication failed' };
      }

      const { data: profile, error: profileErr } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', data.user.id)
        .single();

      if (profileErr || !profile || profile.role !== 'admin') {
        await supabase.auth.signOut();
        return { user: null, error: 'ACCESS_DENIED' };
      }

      const userProfile: Profile = {
        id: profile.id,
        name: profile.full_name || data.user.email?.split('@')[0] || 'Admin',
        email: data.user.email,
        role: 'admin',
        avatar_url: profile.avatar_url,
        is_active: true,
      };

      return { user: userProfile };
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Authentication failed';
      return { user: null, error: message };
    }
  },

  async loginAsDemoAdmin(): Promise<Profile> {
    const res = await this.login('admin@calora.app', 'admin123');
    if (res.user) {
      return res.user;
    }
    throw new Error(res.error || 'Failed to authenticate as Admin');
  },

  async logout(): Promise<void> {
    try {
      await supabase.auth.signOut();
    } catch {
      // Ignore
    }
  },
};
