import { supabase } from '../lib/supabase';
import { FoodCategory } from '../types';
export const categoryService = {
  async getAll(): Promise<FoodCategory[]> {
    const { data, error } = await supabase
      .from('food_categories')
      .select('*')
      .order('name', { ascending: true });

    if (error) {
      console.error('Error fetching categories from Supabase:', error);
      throw error;
    }
    return (data || []) as FoodCategory[];
  },

  async create(name: string): Promise<FoodCategory> {
    const trimmed = name.trim();
    const { data, error } = await supabase
      .from('food_categories')
      .insert({ name: trimmed })
      .select()
      .single();

    if (error || !data) {
      console.error('Error creating category in Supabase:', error);
      throw error;
    }
    return data as FoodCategory;
  },

  async update(id: string, name: string): Promise<FoodCategory> {
    const trimmed = name.trim();
    const { data, error } = await supabase
      .from('food_categories')
      .update({ name: trimmed })
      .eq('id', id)
      .select()
      .single();

    if (error || !data) {
      console.error('Error updating category in Supabase:', error);
      throw error;
    }
    return data as FoodCategory;
  },

  async delete(id: string): Promise<boolean> {
    const { error } = await supabase
      .from('food_categories')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Error deleting category from Supabase:', error);
      throw error;
    }
    return true;
  },

  async deleteMultiple(ids: string[]): Promise<boolean> {
    const { error } = await supabase
      .from('food_categories')
      .delete()
      .in('id', ids);

    if (error) {
      console.error('Error batch deleting categories from Supabase:', error);
      throw error;
    }
    return true;
  },
};
