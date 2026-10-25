import { supabase } from '../lib/supabase';
import { FoodRequest, Food } from '../types';

export const foodRequestService = {
  async getAll(): Promise<FoodRequest[]> {
    const { data, error } = await supabase
      .from('food_request')
      .select('*, food_categories(name)')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching food requests:', error);
      throw error;
    }

    const items = data || [];
    const userIds = [...new Set(items.map((r: any) => r.user_id).filter(Boolean))];
    let profileMap: Record<string, { name: string; avatar_url?: string }> = {};

    if (userIds.length > 0) {
      try {
        const { data: profiles } = await supabase
          .from('profiles')
          .select('id, full_name, avatar_url')
          .in('id', userIds);

        if (profiles) {
          profileMap = Object.fromEntries(
            profiles.map((p: any) => [
              p.id,
              {
                name: p.full_name || 'Calora User',
                avatar_url: p.avatar_url || undefined,
              },
            ])
          );
        }
      } catch (profileErr) {
        console.warn('Could not fetch submitter profile names and avatars:', profileErr);
      }
    }

    return items.map((r: any) => ({
      id: r.id,
      user_id: r.user_id,
      submitter_name: profileMap[r.user_id]?.name || 'Community Member',
      submitter_avatar: profileMap[r.user_id]?.avatar_url,
      image_url: r.image_url,
      category_id: r.category_id,
      category_name: r.food_categories?.name || 'General',
      category: r.food_categories?.name || 'General',
      food_name: r.food_name,
      serving_label: r.serving_label,
      calories: r.calories,
      protein_g: Number(r.protein_g) || 0,
      carbs_g: Number(r.carbs_g) || 0,
      fat_g: Number(r.fat_g) || 0,
      status: r.status,
      notes: r.notes,
      created_at: r.created_at,
    })) as FoodRequest[];
  },

  async approve(requestId: string): Promise<{ updatedRequest: FoodRequest; createdFood: Food }> {
    // 1. Fetch the request
    const { data: req, error: fetchErr } = await supabase
      .from('food_request')
      .select('*, food_categories(name)')
      .eq('id', requestId)
      .single();

    if (fetchErr || !req) {
      console.error('Error fetching request for approval:', fetchErr);
      throw fetchErr || new Error('Request not found');
    }

    // 2. Insert into public.foods
    const { data: createdFoodData, error: foodErr } = await supabase
      .from('foods')
      .insert({
        category_id: req.category_id || null,
        name: req.food_name,
        serving_label: req.serving_label || '1 serving',
        calories: Math.round(Number(req.calories) || 0),
        protein_g: Number(req.protein_g) || 0,
        carbs_g: Number(req.carbs_g) || 0,
        fat_g: Number(req.fat_g) || 0,
        portion_grams: 100,
        source: 'user_submission',
      })
      .select('*, food_categories(name)')
      .single();

    if (foodErr) {
      console.error('Error creating approved food:', foodErr);
      throw foodErr;
    }

    // 3. Update food_request status to 'approved'
    const { data: updatedReqData, error: updateErr } = await supabase
      .from('food_request')
      .update({ status: 'approved' })
      .eq('id', requestId)
      .select('*, food_categories(name)')
      .single();

    if (updateErr) {
      console.error('Error updating food request status:', updateErr);
      throw updateErr;
    }

    const updatedRequest: FoodRequest = {
      id: updatedReqData.id,
      user_id: updatedReqData.user_id,
      submitter_name: req.submitter_name || 'Community Member',
      image_url: updatedReqData.image_url,
      category_id: updatedReqData.category_id,
      category_name: updatedReqData.food_categories?.name || 'General',
      category: updatedReqData.food_categories?.name || 'General',
      food_name: updatedReqData.food_name,
      serving_label: updatedReqData.serving_label,
      calories: updatedReqData.calories,
      protein_g: Number(updatedReqData.protein_g) || 0,
      carbs_g: Number(updatedReqData.carbs_g) || 0,
      fat_g: Number(updatedReqData.fat_g) || 0,
      status: 'approved',
      notes: updatedReqData.notes,
      created_at: updatedReqData.created_at,
    };

    const createdFood: Food = {
      ...createdFoodData,
      category: createdFoodData.food_categories?.name || 'General',
    };

    return { updatedRequest, createdFood };
  },

  async reject(requestId: string, reason: string): Promise<FoodRequest> {
    const { data, error } = await supabase
      .from('food_request')
      .update({
        status: 'rejected',
        notes: reason,
      })
      .eq('id', requestId)
      .select('*, food_categories(name)')
      .single();

    if (error || !data) {
      console.error('Error rejecting food request:', error);
      throw error || new Error('Failed to reject request');
    }

    return {
      id: data.id,
      user_id: data.user_id,
      submitter_name: 'Community Member',
      image_url: data.image_url,
      category_id: data.category_id,
      category_name: data.food_categories?.name || 'General',
      category: data.food_categories?.name || 'General',
      food_name: data.food_name,
      serving_label: data.serving_label,
      calories: data.calories,
      protein_g: Number(data.protein_g) || 0,
      carbs_g: Number(data.carbs_g) || 0,
      fat_g: Number(data.fat_g) || 0,
      status: 'rejected',
      notes: data.notes,
      created_at: data.created_at,
    } as FoodRequest;
  },

  async delete(requestId: string): Promise<boolean> {
    const { error } = await supabase
      .from('food_request')
      .delete()
      .eq('id', requestId);

    if (error) {
      console.error('Error deleting food request:', error);
      throw error;
    }
    return true;
  },

  async deleteMultiple(ids: string[]): Promise<boolean> {
    const { error } = await supabase
      .from('food_request')
      .delete()
      .in('id', ids);

    if (error) {
      console.error('Error batch deleting food requests:', error);
      throw error;
    }
    return true;
  },

  async approveMultiple(ids: string[]): Promise<{ approvedIds: string[]; createdFoods: Food[] }> {
    const createdFoods: Food[] = [];
    const approvedIds: string[] = [];

    for (const id of ids) {
      try {
        const res = await this.approve(id);
        if (res) {
          approvedIds.push(id);
          if (res.createdFood) {
            createdFoods.push(res.createdFood);
          }
        }
      } catch (err) {
        console.error(`Failed to approve request ${id}:`, err);
      }
    }

    return { approvedIds, createdFoods };
  },

  async rejectMultiple(ids: string[], reason: string): Promise<string[]> {
    const rejectedIds: string[] = [];
    for (const id of ids) {
      try {
        await this.reject(id, reason);
        rejectedIds.push(id);
      } catch (err) {
        console.error(`Failed to reject request ${id}:`, err);
      }
    }
    return rejectedIds;
  },
};
