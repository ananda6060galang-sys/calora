// Supabase Edge Function: generate-insights
// AI Smart Nutrition Insights Engine powered by Google Gemini.
// Analyzes user nutritional telemetry, BMR/TDEE goals, and weekly meal logs
// to generate an evidence-based clinical nutritionist report with actionable local food swaps.
// Zero client credentials: GEMINI_API_KEY is read securely from server-side environment.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...CORS_HEADERS,
      "Content-Type": "application/json",
    },
  });
}

/**
 * Validates the Authorization header and verifies the caller is an authenticated Supabase user.
 */
async function authenticateUser(req: Request): Promise<{ user: any; errorResponse?: Response }> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return {
      user: null,
      errorResponse: jsonResponse({ error: "Unauthorized" }, 401),
    };
  }

  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    return {
      user: null,
      errorResponse: jsonResponse({ error: "Unauthorized" }, 401),
    };
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

  if (!supabaseUrl || !supabaseAnonKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY environment variables");
    return {
      user: null,
      errorResponse: jsonResponse({ error: "Server configuration error" }, 500),
    };
  }

  try {
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const { data: { user }, error } = await supabaseClient.auth.getUser(token);

    if (error || !user) {
      return {
        user: null,
        errorResponse: jsonResponse({ error: "Unauthorized" }, 401),
      };
    }

    return { user };
  } catch (err: any) {
    console.error("Auth verification failed:", err.message);
    return {
      user: null,
      errorResponse: jsonResponse({ error: "Unauthorized" }, 401),
    };
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // 1. Authenticate user
  const { user, errorResponse } = await authenticateUser(req);
  if (errorResponse) {
    return errorResponse;
  }

  // 2. Parse request telemetry
  let body: any;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON payload" }, 400);
  }

  const profile = body.profile || {};
  const weeklyData = body.weeklyData || {};
  const locale = (body.locale === "id" || body.locale === "id_ID") ? "id" : "en";

  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiKey) {
    return jsonResponse(
      { error: "GEMINI_API_KEY is not configured in Supabase Edge Function secrets" },
      500
    );
  }

  // Build telemetry summary for prompt
  const goal = profile.goal || "maintain";
  const bmr = Math.round(profile.bmr || 1500);
  const tdee = Math.round(profile.tdee || 2000);
  const targetCalories = Math.round(profile.targetCalories || 2000);
  const targetProtein = Math.round(profile.targetProtein || 120);
  const targetCarbs = Math.round(profile.targetCarbs || 250);
  const targetFat = Math.round(profile.targetFat || 65);

  const avgCalories = Math.round(weeklyData.avgCalories || 0);
  const avgProtein = Math.round(weeklyData.avgProtein || 0);
  const avgCarbs = Math.round(weeklyData.avgCarbs || 0);
  const avgFat = Math.round(weeklyData.avgFat || 0);
  const loggedDaysCount = weeklyData.loggedDaysCount || 0;
  const recentFoods = Array.isArray(weeklyData.recentFoods) ? weeklyData.recentFoods.slice(0, 10).join(", ") : "N/A";
  const mealDistribution = weeklyData.mealDistribution || { breakfast: 25, lunch: 40, dinner: 30, snack: 5 };

  const promptLanguageInstruction = locale === "id"
    ? "Tulis seluruh teks (headline, summary, detail, action, food swaps, verdict) dalam Bahasa Indonesia yang segar, profesional, empatik, dan mudah dimengerti."
    : "Write all text (headline, summary, detail, action, food swaps, verdict) in clear, professional, empathetic, and engaging English.";

  const promptText = `You are a certified Clinical Sports Nutritionist and AI Diet Coach for Calora, an evidence-based metabolic nutrition app.
Analyze the user's weekly nutritional telemetry and generate a highly personalized, structured coaching report.

User Profile:
- Goal: ${goal} (e.g. lose weight, maintain, build muscle)
- BMR: ${bmr} kcal (Basal Metabolic Rate - minimum energy needed for organ survival)
- TDEE: ${tdee} kcal (Total Daily Energy Expenditure)
- Daily Target: ${targetCalories} kcal (Protein: ${targetProtein}g, Carbs: ${targetCarbs}g, Fat: ${targetFat}g)

Weekly Log Performance:
- Logged Days: ${loggedDaysCount} of 7 days
- Weekly Average Intake: ${avgCalories} kcal/day
- Weekly Average Macros: Protein: ${avgProtein}g/day, Carbs: ${avgCarbs}g/day, Fat: ${avgFat}g/day
- Top Logged Foods: ${recentFoods}
- Meal Distribution (% of calories): Breakfast ~${mealDistribution.breakfast}%, Lunch ~${mealDistribution.lunch}%, Dinner ~${mealDistribution.dinner}%, Snack ~${mealDistribution.snack}%

Clinical Rules:
1. BMR Safety Gate: If avgCalories < BMR, flag a metabolic warning. The human body should not chronically undereat below BMR because it triggers adaptive thermogenesis (metabolic slowdown) and muscle wasting.
2. Protein Adequacy: Compare avgProtein against targetProtein. If protein is low, suggest high-protein practical food swaps (favoring accessible Indonesian staples like tempeh, tofu, eggs, chicken breast, steamed fish).
3. Meal Timing: Check dinner percentage. If dinner > 40%, advise shifting calories earlier in the day for improved circadian alignment and sleep quality.
4. Tone: Encouraging, non-judgmental, scientific yet easy to understand. No clinical jargon without simple explanation.
5. ${promptLanguageInstruction}

Return ONLY a valid JSON object strictly matching this schema:
{
  "weeklyGrade": "A" | "A-" | "B+" | "B" | "B-" | "C+" | "Solid Progress",
  "statusBadge": string,
  "headline": string,
  "executiveSummary": string,
  "pillars": [
    {
      "category": "Metabolic Health" | "Kesehatan Metabolisme",
      "status": "optimal" | "warning" | "needs_attention",
      "title": string,
      "detail": string,
      "action": string
    },
    {
      "category": "Macronutrient Balance" | "Keseimbangan Makronutrisi",
      "status": "optimal" | "warning" | "needs_attention",
      "title": string,
      "detail": string,
      "action": string
    },
    {
      "category": "Meal Timing & Habit" | "Pola Waktu & Kebiasaan",
      "status": "optimal" | "warning" | "needs_attention",
      "title": string,
      "detail": string,
      "action": string
    }
  ],
  "actionableFoodSwaps": [
    {
      "context": string,
      "recommendation": string,
      "macros": string
    },
    {
      "context": string,
      "recommendation": string,
      "macros": string
    }
  ],
  "motivationalVerdict": string
}`;

  const candidateModels = [
    "gemini-3.1-flash-lite",
    "gemini-3.1-flash-lite-preview",
  ];

  const geminiPayload = {
    contents: [
      {
        parts: [{ text: promptText }],
      },
    ],
    generationConfig: {
      temperature: 0.3,
      response_mime_type: "application/json",
    },
  };

  let textOutput: string | null = null;
  let successfulModel: string | null = null;
  let lastError: string = "";

  for (const model of candidateModels) {
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;
    try {
      const res = await fetch(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(geminiPayload),
      });

      if (!res.ok) {
        const errText = await res.text();
        lastError = `Model ${model} returned HTTP ${res.status}: ${errText}`;
        console.warn(`[generate-insights] ${lastError}`);
        continue;
      }

      const geminiData = await res.json();
      const rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
      if (rawText && typeof rawText === "string" && rawText.trim().length > 0) {
        textOutput = rawText;
        successfulModel = model;
        break;
      }
    } catch (e: any) {
      lastError = `Exception with ${model}: ${e.message}`;
      console.warn(`[generate-insights] ${lastError}`);
    }
  }

  if (!textOutput) {
    return jsonResponse(
      {
        success: false,
        error: `Gemini inference failed across candidate models: ${lastError}`,
      },
      502
    );
  }

  try {
    const parsed = JSON.parse(textOutput);
    return jsonResponse({
      success: true,
      model: successfulModel,
      report: parsed,
    });
  } catch (parseErr: any) {
    console.error("[generate-insights] Failed to parse JSON:", parseErr.message, textOutput);
    return jsonResponse(
      {
        success: false,
        error: "Failed to parse structured JSON from AI response",
        raw: textOutput,
      },
      500
    );
  }
});
