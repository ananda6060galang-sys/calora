import { createClient } from '@supabase/supabase-js';

const supabaseUrl =
  import.meta.env.VITE_SUPABASE_URL || 'https://kajalubgbedxmqezvdyd.supabase.co';
const supabaseAnonKey =
  import.meta.env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_dJ_6tou-GQsfMDjZWkXrRQ_yxYlt68X';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
