import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ai_insight_report.dart';
import '../../models/user_profile.dart';
import '../config/supabase_config.dart';

/// Service orchestrating AI Nutrition Insights with Gemini Edge Function
/// and persistent local caching.
class AiInsightsService {
  AiInsightsService({
    SupabaseClient? supabaseClient,
    http.Client? httpClient,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _http = httpClient ?? http.Client();

  final SupabaseClient _supabase;
  final http.Client _http;

  static const String _cacheKeyPrefix = 'calora_ai_insights_';

  Uri get _endpoint =>
      Uri.parse('${SupabaseConfig.url}/functions/v1/generate-insights');

  String _cacheKey(String userId) => '$_cacheKeyPrefix$userId';

  /// Retrieve cached report from local storage if available.
  Future<AiInsightReport?> getCachedReport(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(userId));
      return AiInsightReport.deserialize(raw);
    } catch (e) {
      debugPrint('[AiInsightsService] Failed to read cache: $e');
      return null;
    }
  }

  /// Save report to local storage cache.
  Future<void> saveReportToCache(String userId, AiInsightReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(userId), report.serialize());
    } catch (e) {
      debugPrint('[AiInsightsService] Failed to write cache: $e');
    }
  }

  /// Generate or retrieve AI Nutrition Coach report.
  Future<AiInsightReport> getOrGenerateReport({
    required UserProfile profile,
    required double avgCalories,
    required double avgProtein,
    required double avgCarbs,
    required double avgFat,
    required int loggedDaysCount,
    required List<String> recentFoods,
    required Map<String, int> mealDistribution,
    required String locale,
    bool forceRefresh = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id ?? 'anonymous';

    // 1. Check cache first unless forceRefresh is requested
    if (!forceRefresh) {
      final cached = await getCachedReport(userId);
      if (cached != null) {
        final age = DateTime.now().difference(cached.generatedAt);
        // Cache is valid for 24 hours if data hasn't drastically changed
        if (age.inHours < 24) {
          return cached;
        }
      }
    }

    // 2. Attempt remote Gemini Edge Function
    try {
      final session = _supabase.auth.currentSession;
      final accessToken = session?.accessToken;

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': SupabaseConfig.publishableKey,
      };

      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final payload = {
        'locale': locale,
        'profile': {
          'goal': profile.goal.name,
          'bmr': profile.bmr,
          'tdee': profile.tdee,
          'targetCalories': profile.dailyCalorieTarget,
          'targetProtein': profile.proteinTargetG,
          'targetCarbs': profile.carbsTargetG,
          'targetFat': profile.fatTargetG,
        },
        'weeklyData': {
          'avgCalories': avgCalories,
          'avgProtein': avgProtein,
          'avgCarbs': avgCarbs,
          'avgFat': avgFat,
          'loggedDaysCount': loggedDaysCount,
          'recentFoods': recentFoods,
          'mealDistribution': mealDistribution,
        },
      };

      final response = await _http
          .post(_endpoint, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['report'] != null) {
          final reportJson = data['report'] as Map<String, dynamic>;
          final report = AiInsightReport.fromJson(
            reportJson,
            model: data['model']?.toString() ?? 'gemini-3.1-flash-lite',
          );
          await saveReportToCache(userId, report);
          return report;
        }
      }
    } catch (e) {
      debugPrint('[AiInsightsService] Remote Gemini call failed, falling back to local clinical engine: $e');
    }

    // 3. Fallback: Local evidence-based clinical engine
    final localReport = _generateLocalClinicalReport(
      profile: profile,
      avgCalories: avgCalories,
      avgProtein: avgProtein,
      avgCarbs: avgCarbs,
      avgFat: avgFat,
      loggedDaysCount: loggedDaysCount,
      recentFoods: recentFoods,
      mealDistribution: mealDistribution,
      locale: locale,
    );

    await saveReportToCache(userId, localReport);
    return localReport;
  }

  /// High-accuracy local evidence-based clinical nutritionist generator
  AiInsightReport _generateLocalClinicalReport({
    required UserProfile profile,
    required double avgCalories,
    required double avgProtein,
    required double avgCarbs,
    required double avgFat,
    required int loggedDaysCount,
    required List<String> recentFoods,
    required Map<String, int> mealDistribution,
    required String locale,
  }) {
    final isId = locale == 'id';
    final targetCal = profile.dailyCalorieTarget > 0 ? profile.dailyCalorieTarget : 2000.0;
    final bmr = profile.bmr > 0 ? profile.bmr : 1500.0;
    final targetProtein = profile.proteinTargetG > 0 ? profile.proteinTargetG : 120.0;

    final proteinRatio = targetProtein > 0 ? (avgProtein / targetProtein) : 1.0;
    final calDiff = avgCalories - targetCal;
    final isUnderBmr = avgCalories > 0 && avgCalories < bmr;

    String grade = 'A';
    String statusBadge = isId ? 'Keseimbangan Metabolik' : 'Metabolic Balance';
    String headline;
    String executiveSummary;

    if (isUnderBmr) {
      grade = 'B-';
      statusBadge = isId ? 'Peringatan Asupan Energi' : 'Energy Intake Warning';
      headline = isId
          ? 'Asupan Kalori Berada di Bawah Angka BMR Minimal'
          : 'Caloric Intake Below Basal Metabolic Rate';
      executiveSummary = isId
          ? 'Rata-rata asupan kalorimu (${avgCalories.round()} kcal) jatuh di bawah BMR (${bmr.round()} kcal). Tubuh memerlukan minimal energi ini untuk kerja organ vital. Menjaga kalori di atas BMR sangat penting untuk mencegah perlambatan metabolisme.'
          : 'Your average caloric intake (${avgCalories.round()} kcal) is below your BMR (${bmr.round()} kcal). Chronic undereating below BMR risks muscle loss and metabolic slowdown.';
    } else if (proteinRatio >= 0.85 && calDiff.abs() <= targetCal * 0.12) {
      grade = 'A';
      statusBadge = isId ? 'Progres Sangat Konsisten' : 'Optimal Consistency';
      headline = isId
          ? 'Nutrisi Terjaga Stabil Sesuai Rencana Programmu'
          : 'Nutritional Intake Strongly Aligned with Goals';
      executiveSummary = isId
          ? 'Minggu ini performamu sangat memuaskan. Asupan kalori rata-rata (${avgCalories.round()} kcal) berada di rentang target ideal dengan pemenuhan protein ${(proteinRatio * 100).round()}%.'
          : 'Outstanding consistency this week. Average daily intake (${avgCalories.round()} kcal) tightly tracks your target with ${(proteinRatio * 100).round()}% protein compliance.';
    } else if (proteinRatio < 0.75) {
      grade = 'B';
      statusBadge = isId ? 'Fokus Asupan Protein' : 'Protein Focus Needed';
      headline = isId
          ? 'Konsumsi Protein Memerlukan Tambahan Nutrisi Berkualitas'
          : 'Protein Intake Trailing Behind Target';
      executiveSummary = isId
          ? 'Kalori harianmu cukup stabil, namun asupan protein rata-rata (${avgProtein.round()}g) baru mencapai ${(proteinRatio * 100).round()}% dari target ${targetProtein.round()}g. Menambah sumber protein lokal akan mempercepat pembentukan otot dan rasa kenyang.'
          : 'Caloric balance is steady, but protein intake (${avgProtein.round()}g) is only ${(proteinRatio * 100).round()}% of target. Incorporating dense protein staples will optimize satiety and recovery.';
    } else {
      grade = 'B+';
      statusBadge = isId ? 'Progres Terjaga' : 'Solid Progress';
      headline = isId
          ? 'Ritme Pencatatan Bagus dengan Sedikit Penyesuaian Makro'
          : 'Steady Logging Rhythm with Minor Macro Tweaks';
      executiveSummary = isId
          ? 'Kamu mencatatkan $loggedDaysCount dari 7 hari pekan ini. Rata-rata asupan ${avgCalories.round()} kcal sudah cukup terkontrol dengan variasi menu yang baik.'
          : 'You logged $loggedDaysCount of 7 days this week. Average intake of ${avgCalories.round()} kcal demonstrates solid dietary discipline.';
    }

    final pillars = <AiInsightPillar>[
      AiInsightPillar(
        category: isId ? 'Kesehatan Metabolisme' : 'Metabolic Health',
        status: isUnderBmr ? 'warning' : 'optimal',
        title: isUnderBmr
            ? (isId ? 'Perlindungan Laju Metabolisme' : 'Basal Metabolic Protection')
            : (isId ? 'Keseimbangan Energi Terkendali' : 'Energy Expenditure in Range'),
        detail: isUnderBmr
            ? (isId
                ? 'Asupan harianmu berada di bawah batas BMR ${bmr.round()} kcal. Jangan memotong kalori terlalu tajam saat diet.'
                : 'Intake is below your ${bmr.round()} kcal BMR baseline. Extreme deficits trigger metabolic adaptation.')
            : (isId
                ? 'Asupan energi berada dalam koridor aman di atas BMR (${bmr.round()} kcal) dan mendukung aktivitas harian.'
                : 'Intake is safely above your ${bmr.round()} kcal BMR baseline, fueling daily physical activities.'),
        action: isUnderBmr
            ? (isId ? 'Tingkatkan kalori minimal ke ${bmr.round()} kcal dengan camilan bernutrisi.' : 'Raise floor to ${bmr.round()} kcal with healthy dense snacks.')
            : (isId ? 'Pertahankan rentang kalori ini sepanjang pekan depan.' : 'Maintain this caloric window into next week.'),
      ),
      AiInsightPillar(
        category: isId ? 'Keseimbangan Makronutrisi' : 'Macronutrient Balance',
        status: proteinRatio >= 0.85 ? 'optimal' : 'needs_attention',
        title: proteinRatio >= 0.85
            ? (isId ? 'Kecukupan Protein Optimal' : 'Optimal Protein Target')
            : (isId ? 'Kebutuhan Protein Tambahan' : 'Sub-optimal Protein Synthesis'),
        detail: isId
            ? 'Rata-rata protein harian ${avgProtein.round()}g dari target ${targetProtein.round()}g.'
            : 'Average daily protein ${avgProtein.round()}g against ${targetProtein.round()}g target.',
        action: isId
            ? 'Pilih sumber protein kaya asam amino seperti tempe, ayam panggang, dan putih telur.'
            : 'Incorporate protein staples like chicken breast, eggs, and tempeh.',
      ),
      AiInsightPillar(
        category: isId ? 'Pola Waktu & Kebiasaan' : 'Meal Timing & Habit',
        status: (mealDistribution['dinner'] ?? 30) > 42 ? 'warning' : 'optimal',
        title: isId ? 'Distribusi Waktu Makan' : 'Chrononutrition & Timing',
        detail: isId
            ? 'Sebaran kalori harian: Sarapan ${mealDistribution['breakfast']}%, Makan Siang ${mealDistribution['lunch']}%, Makan Malam ${mealDistribution['dinner']}%, Camilan ${mealDistribution['snack']}%.'
            : 'Daily distribution: Breakfast ${mealDistribution['breakfast']}%, Lunch ${mealDistribution['lunch']}%, Dinner ${mealDistribution['dinner']}%, Snacks ${mealDistribution['snack']}%.',
        action: (mealDistribution['dinner'] ?? 30) > 42
            ? (isId ? 'Geser sebagian kalori makan malam ke sarapan atau makan siang.' : 'Shift 15% of dinner calories earlier to lunch.')
            : (isId ? 'Jadwal makan harianmu terbagi secara merata dan sehat.' : 'Your meal distribution promotes balanced circadian energy.'),
      ),
    ];

    final foodSwaps = <AiFoodSwap>[
      AiFoodSwap(
        context: isId ? 'Menambah 15g protein tanpa lonjakan lemak' : 'Add 15g protein without saturated fat',
        recommendation: isId
            ? '2 butir telur rebus atau 1 potong tempe panggang di sarapan'
            : '2 boiled eggs or 1 slice grilled tempeh at breakfast',
        macros: '+130 kcal | 13g P | 1g C | 8g F',
      ),
      AiFoodSwap(
        context: isId ? 'Camilan sore padat serat & energi' : 'Sustained energy afternoon snack',
        recommendation: isId
            ? '1 buah pisang atau apel potong dengan 1 sendok teh selai kacang'
            : '1 banana or apple slices with 1 tsp natural peanut butter',
        macros: '+120 kcal | 3g P | 22g C | 3g F',
      ),
    ];

    return AiInsightReport(
      weeklyGrade: grade,
      statusBadge: statusBadge,
      headline: headline,
      executiveSummary: executiveSummary,
      pillars: pillars,
      actionableFoodSwaps: foodSwaps,
      motivationalVerdict: isId
          ? 'Konsistensi adalah kunci transformasi tubuh. Kamu sudah memiliki fondasi yang kuat, lanjutkan ritme terbaikmu!'
          : 'Consistency drives physical transformation. Keep building on this strong momentum!',
      generatedAt: DateTime.now(),
      model: 'calora-clinical-engine',
    );
  }
}
