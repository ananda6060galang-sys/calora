import { supabase } from '../lib/supabase';
import { Food } from '../types';
export const foodService = {
  async getAll(): Promise<Food[]> {
    const { data, error } = await supabase
      .from('foods')
      .select('*, food_categories(name)')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching foods from Supabase:', error);
      throw error;
    }

    return (data || []).map((row: any) => ({
      ...row,
      category: row.food_categories?.name || 'General',
    })) as Food[];
  },

  async create(food: Omit<Food, 'id'>): Promise<Food> {
    const { data, error } = await supabase
      .from('foods')
      .insert({
        name: food.name,
        serving_label: food.serving_label,
        calories: food.calories,
        protein_g: food.protein_g,
        carbs_g: food.carbs_g,
        fat_g: food.fat_g,
        category_id: food.category_id || null,
        portion_grams: food.portion_grams || null,
        source: food.source || 'admin_manual',
      })
      .select('*, food_categories(name)')
      .single();

    if (error || !data) {
      console.error('Error creating food in Supabase:', error);
      throw error;
    }

    return {
      ...data,
      category: data.food_categories?.name || food.category || 'General',
    } as Food;
  },

  async update(id: string, updates: Partial<Food>): Promise<Food> {
    const updatePayload: Record<string, any> = {};
    if (updates.name !== undefined) updatePayload.name = updates.name;
    if (updates.serving_label !== undefined) updatePayload.serving_label = updates.serving_label;
    if (updates.calories !== undefined) updatePayload.calories = updates.calories;
    if (updates.protein_g !== undefined) updatePayload.protein_g = updates.protein_g;
    if (updates.carbs_g !== undefined) updatePayload.carbs_g = updates.carbs_g;
    if (updates.fat_g !== undefined) updatePayload.fat_g = updates.fat_g;
    if (updates.category_id !== undefined) updatePayload.category_id = updates.category_id || null;
    if (updates.portion_grams !== undefined) updatePayload.portion_grams = updates.portion_grams || null;
    updatePayload.updated_at = new Date().toISOString();

    const { data, error } = await supabase
      .from('foods')
      .update(updatePayload)
      .eq('id', id)
      .select('*, food_categories(name)')
      .single();

    if (error || !data) {
      console.error('Error updating food in Supabase:', error);
      throw error;
    }

    return {
      ...data,
      category: data.food_categories?.name || updates.category || 'General',
    } as Food;
  },

  async delete(id: string, reason?: string): Promise<boolean> {
    // 1. Fetch food info first to check if there is a corresponding food_request
    const { data: food } = await supabase
      .from('foods')
      .select('name, source')
      .eq('id', id)
      .maybeSingle();

    // 2. Delete the food from public.foods
    const { error } = await supabase
      .from('foods')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Error deleting food from Supabase:', error);
      throw error;
    }

    // 3. If there are any approved food_request with this name, update them to rejected with reason
    if (food && food.name) {
      try {
        const deletionNote = reason?.trim()
          ? `Makanan dihapus dari database publik: ${reason.trim()}`
          : 'Makanan telah dihapus oleh admin dari database publik.';

        await supabase
          .from('food_request')
          .update({
            status: 'rejected',
            notes: deletionNote,
          })
          .ilike('food_name', food.name)
          .eq('status', 'approved');
      } catch (reqUpdateErr) {
        console.warn('Could not update corresponding food_request:', reqUpdateErr);
      }
    }

    return true;
  },

  async deleteMultiple(ids: string[], reason?: string): Promise<boolean> {
    for (const id of ids) {
      await this.delete(id, reason);
    }
    return true;
  },
};
