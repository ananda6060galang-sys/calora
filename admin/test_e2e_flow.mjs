import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://kajalubgbedxmqezvdyd.supabase.co';
const ANON_KEY = 'sb_publishable_dJ_6tou-GQsfMDjZWkXrRQ_yxYlt68X';

async function runE2E() {
  console.log('--- STARTING E2E VERIFICATION ---');

  // 1. Setup client for user
  const userClient = createClient(SUPABASE_URL, ANON_KEY);
  const testUserEmail = `testuser_${Date.now()}@calora.app`;
  const testPassword = 'Password123!';

  console.log(`1. Creating test mobile user: ${testUserEmail}...`);
  const { data: signUpData, error: signUpErr } = await userClient.auth.signUp({
    email: testUserEmail,
    password: testPassword,
  });

  if (signUpErr) {
    console.error('Sign up failed:', signUpErr);
    process.exit(1);
  }
  const userId = signUpData.user?.id;
  console.log('✓ Test user registered, id:', userId);

  // 2. Fetch categories as user
  console.log('2. Fetching food categories from Supabase...');
  const { data: categories, error: catErr } = await userClient
    .from('food_categories')
    .select('*')
    .order('name');

  if (catErr || !categories || categories.length === 0) {
    console.error('Failed to fetch categories:', catErr);
    process.exit(1);
  }
  console.log(`✓ Fetched ${categories.length} categories. First: ${categories[0].name} (${categories[0].id})`);
  const selectedCategory = categories.find(c => c.name.toLowerCase().includes('protein')) || categories[0];

  // 3. Submit food request from Mobile
  const testFoodName = `E2E Ayam Bakar Madu ${Date.now().toString().slice(-4)}`;
  console.log(`3. Mobile submitting food request: "${testFoodName}"...`);
  const { data: requestInsert, error: reqErr } = await userClient
    .from('food_request')
    .insert({
      user_id: userId,
      category_id: selectedCategory.id,
      food_name: testFoodName,
      serving_label: '1 porsi (150g)',
      calories: 320,
      protein_g: 32.5,
      carbs_g: 10.0,
      fat_g: 12.0,
      notes: 'Automated E2E Test Food Submission',
    })
    .select('*, food_categories(name)')
    .single();

  if (reqErr || !requestInsert) {
    console.error('Failed to submit food request:', reqErr);
    process.exit(1);
  }
  console.log(`✓ Food request submitted! ID: ${requestInsert.id}, Status: ${requestInsert.status}`);

  // 4. Verify My Submissions as user
  console.log('4. Verifying "My Submissions" reads real data...');
  const { data: mySubmissions, error: mySubErr } = await userClient
    .from('food_request')
    .select('*')
    .eq('user_id', userId);

  if (mySubErr || !mySubmissions || mySubmissions.length === 0) {
    console.error('Failed to read my submissions:', mySubErr);
    process.exit(1);
  }
  console.log(`✓ My Submissions returned ${mySubmissions.length} row(s).`);

  // 5. Authenticate Admin client
  console.log('5. Authenticating Admin Dashboard (admin@calora.app)...');
  const adminClient = createClient(SUPABASE_URL, ANON_KEY);
  const { data: adminAuth, error: adminAuthErr } = await adminClient.auth.signInWithPassword({
    email: 'admin@calora.app',
    password: 'admin123',
  });

  if (adminAuthErr || !adminAuth.session) {
    console.error('Admin authentication failed:', adminAuthErr);
    process.exit(1);
  }
  console.log('✓ Admin authenticated successfully.');

  // 6. Admin queries Food Requests
  console.log('6. Admin fetching food requests list...');
  const { data: adminReqs, error: adminReqErr } = await adminClient
    .from('food_request')
    .select('*, food_categories(name)')
    .eq('id', requestInsert.id)
    .single();

  if (adminReqErr || !adminReqs) {
    console.error('Admin failed to find food request:', adminReqErr);
    process.exit(1);
  }
  console.log(`✓ Admin retrieved request: ${adminReqs.food_name}, submitter user_id: ${adminReqs.user_id}`);

  // 7. Admin Approves request: Insert into foods + update status
  console.log('7. Admin approving request...');
  // Insert into public.foods
  const { data: approvedFood, error: foodInsertErr } = await adminClient
    .from('foods')
    .insert({
      category_id: adminReqs.category_id,
      name: adminReqs.food_name,
      serving_label: adminReqs.serving_label,
      calories: adminReqs.calories,
      protein_g: adminReqs.protein_g,
      carbs_g: adminReqs.carbs_g,
      fat_g: adminReqs.fat_g,
      portion_grams: 150,
      source: 'user_submission',
    })
    .select()
    .single();

  if (foodInsertErr || !approvedFood) {
    console.error('Admin failed to create approved food:', foodInsertErr);
    process.exit(1);
  }
  console.log(`✓ Food created in public.foods! ID: ${approvedFood.id}`);

  // Update status in public.food_request
  const { data: updatedReq, error: updateErr } = await adminClient
    .from('food_request')
    .update({ status: 'approved' })
    .eq('id', requestInsert.id)
    .select()
    .single();

  if (updateErr || updatedReq.status !== 'approved') {
    console.error('Admin failed to update request status:', updateErr);
    process.exit(1);
  }
  console.log(`✓ Food request status updated to: ${updatedReq.status}`);

  // 8. Mobile Food Search queries public.foods
  console.log(`8. Mobile user searching for "${testFoodName}" in public.foods...`);
  const { data: searchResults, error: searchErr } = await userClient
    .from('foods')
    .select('*, food_categories(name)')
    .ilike('name', `%${testFoodName}%`);

  if (searchErr || !searchResults || searchResults.length === 0) {
    console.error('Mobile food search failed to find approved food:', searchErr);
    process.exit(1);
  }
  console.log(`✓ Found ${searchResults.length} match: "${searchResults[0].name}" (${searchResults[0].calories} kcal, ${searchResults[0].protein_g}g P)`);

  // 9. Mobile user logs weight into public.weight_logs
  console.log('9. Testing Mobile Weight Logs (public.weight_logs)...');
  const todayStr = new Date().toISOString().substring(0, 10);
  const { data: weightLog, error: weightErr } = await userClient
    .from('weight_logs')
    .upsert({
      user_id: userId,
      weight_kg: 68.5,
      logged_date: todayStr,
      notes: 'E2E weight log test',
    }, { onConflict: 'user_id,logged_date' })
    .select()
    .single();

  if (weightErr || !weightLog) {
    console.error('Failed to log weight:', weightErr);
    process.exit(1);
  }
  console.log(`✓ Weight log recorded! Date: ${weightLog.logged_date}, Weight: ${weightLog.weight_kg} kg`);

  // Verify retrieval
  const { data: userLogs, error: fetchWeightErr } = await userClient
    .from('weight_logs')
    .select('*')
    .eq('user_id', userId);

  if (fetchWeightErr || !userLogs || userLogs.length === 0) {
    console.error('Failed to retrieve weight logs:', fetchWeightErr);
    process.exit(1);
  }
  console.log(`✓ Weight logs fetched: ${userLogs.length} entry found.`);

  // Cleanup test food & weight
  console.log('10. Cleaning up test data...');
  await adminClient.from('foods').delete().eq('id', approvedFood.id);
  await userClient.from('weight_logs').delete().eq('id', weightLog.id);
  await adminClient.from('food_request').delete().eq('id', requestInsert.id);
  console.log('✓ Cleanup completed.');

  console.log('\n========================================');
  console.log('  ALL E2E CHECKS PASSED SUCCESSFULLY!  ');
  console.log('========================================');
}

runE2E().catch(err => {
  console.error('Unhandled E2E error:', err);
  process.exit(1);
});
