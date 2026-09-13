// Supabase Edge Function: fatsecret-food
// Multi-Source Food Database Engine:
// 1. Primary: FatSecret REST API (OAuth 2.0 Client Credentials)
// 2. Fallback: USDA FoodData Central REST API (Recoverable external fallback)
// Keeps FATSECRET_CLIENT_ID, FATSECRET_CLIENT_SECRET, and USDA_API_KEY secure on the server.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

interface TokenCache {
  accessToken: string;
  expiresAt: number; // unix timestamp ms
}

let cachedToken: TokenCache | null = null;

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
 * Safely parses a number, fallback to defaultValue or 0.
 */
function parseNum(val: unknown, defaultValue = 0): number {
  if (val === undefined || val === null) return defaultValue;
  const num = Number(val);
  return isNaN(num) ? defaultValue : num;
}

/**
 * Obtains a valid FatSecret OAuth 2.0 access token using client_credentials grant.
 * Reuses cached token if valid.
 */
async function getFatSecretToken(): Promise<string> {
  const now = Date.now();
  if (cachedToken && cachedToken.expiresAt > now + 60000) {
    return cachedToken.accessToken;
  }

  const clientId = Deno.env.get("FATSECRET_CLIENT_ID");
  const clientSecret = Deno.env.get("FATSECRET_CLIENT_SECRET");

  if (!clientId || !clientSecret) {
    throw new Error("FATSECRET_CLIENT_ID or FATSECRET_CLIENT_SECRET is not configured");
  }

  const credentials = btoa(`${clientId}:${clientSecret}`);
  const body = new URLSearchParams({
    grant_type: "client_credentials",
    scope: "basic",
  });

  const res = await fetch("https://oauth.fatsecret.com/connect/token", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: body.toString(),
  });

  if (!res.ok) {
    const errorText = await res.text();
    console.error("FatSecret token error:", res.status, errorText);
    throw new Error(`Failed to obtain FatSecret token: ${res.status}`);
  }

  const data = await res.json();
  const expiresInSec = data.expires_in || 86400;
  cachedToken = {
    accessToken: data.access_token,
    expiresAt: now + expiresInSec * 1000,
  };

  return cachedToken.accessToken;
}

/**
 * Normalizes FatSecret serving object.
 */
function normalizeServing(s: any): any {
  return {
    servingId: String(s.serving_id || ""),
    servingDescription: String(s.serving_description || "1 serving"),
    metricServingAmount: s.metric_serving_amount !== undefined ? parseNum(s.metric_serving_amount) : null,
    metricServingUnit: s.metric_serving_unit ? String(s.metric_serving_unit) : null,
    numberOfUnits: parseNum(s.number_of_units, 1),
    measurementDescription: String(s.measurement_description || s.serving_description || "serving"),
    calories: Math.round(parseNum(s.calories, 0)),
    proteinG: parseNum(s.protein, 0),
    carbsG: parseNum(s.carbohydrate, 0),
    fatG: parseNum(s.fat, 0),
  };
}

/**
 * Normalizes a FatSecret food item from food.get.v2 or search.
 */
function normalizeFatSecretFood(item: any): any {
  const rawId = String(item.food_id || "");
  const foodId = rawId.startsWith("fatsecret_") ? rawId : `fatsecret_${rawId}`;
  const foodName = String(item.food_name || "Unknown Food");
  const brandName = item.brand_name ? String(item.brand_name) : null;
  const foodType = String(item.food_type || "Generic");

  let servingsList: any[] = [];
  if (item.servings && item.servings.serving) {
    const raw = item.servings.serving;
    if (Array.isArray(raw)) {
      servingsList = raw.map(normalizeServing);
    } else {
      servingsList = [normalizeServing(raw)];
    }
  }

  let defaultCalories = 0;
  let defaultProtein = 0;
  let defaultCarbs = 0;
  let defaultFat = 0;
  let defaultServingLabel = "1 serving";
  let defaultGrams: number | null = null;

  if (servingsList.length > 0) {
    const first = servingsList[0];
    defaultCalories = first.calories;
    defaultProtein = first.proteinG;
    defaultCarbs = first.carbsG;
    defaultFat = first.fatG;
    defaultServingLabel = first.servingDescription;
    if (first.metricServingUnit?.toLowerCase() === "g" && first.metricServingAmount) {
      defaultGrams = first.metricServingAmount;
    }
  } else if (item.food_description) {
    const desc = String(item.food_description);
    const parts = desc.split("-");
    if (parts.length > 0) {
      defaultServingLabel = parts[0].replace(/Per\s*/i, "").trim();
    }
    const calMatch = desc.match(/Calories:\s*(\d+)/i);
    if (calMatch) defaultCalories = parseInt(calMatch[1], 10);

    const fatMatch = desc.match(/Fat:\s*([\d.]+)/i);
    if (fatMatch) defaultFat = parseFloat(fatMatch[1]);

    const carbMatch = desc.match(/Carbs:\s*([\d.]+)/i);
    if (carbMatch) defaultCarbs = parseFloat(carbMatch[1]);

    const proMatch = desc.match(/Protein:\s*([\d.]+)/i);
    if (proMatch) defaultProtein = parseFloat(proMatch[1]);

    const gramMatch = defaultServingLabel.match(/(\d+(?:\.\d+)?)\s*g\b/i);
    if (gramMatch) defaultGrams = parseFloat(gramMatch[1]);
  }

  return {
    id: foodId,
    name: brandName ? `${foodName} (${brandName})` : foodName,
    servingLabel: defaultServingLabel,
    calories: defaultCalories,
    proteinG: defaultProtein,
    carbsG: defaultCarbs,
    fatG: defaultFat,
    category: foodType === "Brand" ? "Brand" : "General",
    portionGrams: defaultGrams,
    source: "fatsecret",
    servings: servingsList,
  };
}

/**
 * Normalizes USDA food item from foods/search or food details.
 */
function normalizeUsdaFood(item: any): any {
  const fdcId = String(item.fdcId || "");
  const foodId = `usda_${fdcId}`;
  const description = String(item.description || "Unknown Food");
  const brandOwner = item.brandOwner || item.brandName ? String(item.brandOwner || item.brandName) : null;

  let calories = 0;
  let protein = 0;
  let carbs = 0;
  let fat = 0;

  const nutrients = item.foodNutrients || [];
  for (const n of nutrients) {
    const name = String(n.nutrientName || n.nutrient?.name || "").toLowerCase();
    const val = parseNum(n.value ?? n.amount, 0);

    if (name.includes("energy") && (n.unitName === "KCAL" || n.nutrient?.unitName === "kcal" || !calories)) {
      calories = Math.round(val);
    } else if (name.startsWith("protein")) {
      protein = Math.round(val * 10) / 10;
    } else if (name.includes("carbohydrate")) {
      carbs = Math.round(val * 10) / 10;
    } else if (name.includes("total lipid") || name === "fat") {
      fat = Math.round(val * 10) / 10;
    }
  }

  const servingSize = parseNum(item.servingSize, 0);
  const servingSizeUnit = item.servingSizeUnit ? String(item.servingSizeUnit).toLowerCase() : "";
  const householdServing = item.householdServingFullText ? String(item.householdServingFullText) : "";

  let servingLabel = "1 serving";
  let portionGrams: number | null = null;

  if (servingSize > 0 && servingSizeUnit === "g") {
    portionGrams = servingSize;
    servingLabel = householdServing ? `${householdServing} (${servingSize}g)` : `${servingSize}g`;
  } else if (servingSize > 0) {
    servingLabel = `${servingSize} ${servingSizeUnit}`;
  } else if (householdServing) {
    servingLabel = householdServing;
  } else {
    servingLabel = "100 g";
    portionGrams = 100;
  }

  const servingsList = [
    {
      servingId: `${foodId}_s1`,
      servingDescription: servingLabel,
      metricServingAmount: portionGrams,
      metricServingUnit: portionGrams != null ? "g" : null,
      numberOfUnits: 1.0,
      measurementDescription: servingLabel,
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    }
  ];

  return {
    id: foodId,
    name: brandOwner ? `${description} (${brandOwner})` : description,
    servingLabel: servingLabel,
    calories: calories,
    proteinG: protein,
    carbsG: carbs,
    fatG: fat,
    category: item.foodCategory || "General",
    portionGrams: portionGrams,
    source: "usda",
    servings: servingsList,
  };
}

/**
 * Searches FatSecret API. Returns null if error is recoverable.
 */
async function searchFatSecret(query: string, pageNumber: number, maxResults: number): Promise<any[] | null> {
  try {
    const token = await getFatSecretToken();
    const params = new URLSearchParams({
      method: "foods.search.v2",
      search_expression: query,
      page_number: String(pageNumber),
      max_results: String(maxResults),
      format: "json",
    });

    const fsRes = await fetch("https://platform.fatsecret.com/rest/server.api", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params.toString(),
    });

    if (!fsRes.ok) {
      console.warn("FatSecret search HTTP non-ok:", fsRes.status);
      return null;
    }

    const fsData = await fsRes.json();
    if (fsData.error) {
      console.warn("FatSecret search returned API error:", fsData.error.code, fsData.error.message);
      return null;
    }

    const foodsContainer = fsData.foods_search || fsData.foods;
    if (!foodsContainer) return [];

    const foodField = foodsContainer.results?.food || foodsContainer.food;
    let rawList: any[] = [];
    if (Array.isArray(foodField)) {
      rawList = foodField;
    } else if (foodField) {
      rawList = [foodField];
    }

    return rawList.map(normalizeFatSecretFood);
  } catch (err: any) {
    console.warn("FatSecret search exception:", err.message);
    return null;
  }
}

/**
 * Searches USDA FoodData Central API.
 */
async function searchUsda(query: string, maxResults: number): Promise<any[] | null> {
  try {
    const apiKey = Deno.env.get("USDA_API_KEY") || "DEMO_KEY";
    const url = new URL("https://api.nal.usda.gov/fdc/v1/foods/search");
    url.searchParams.set("query", query);
    url.searchParams.set("pageSize", String(maxResults));
    url.searchParams.set("api_key", apiKey);

    const res = await fetch(url.toString(), {
      headers: { "Accept": "application/json" },
    });

    if (!res.ok) {
      console.warn("USDA search HTTP non-ok:", res.status);
      return null;
    }

    const data = await res.json();
    const foods = data.foods || [];
    return foods.map(normalizeUsdaFood);
  } catch (err: any) {
    console.warn("USDA search exception:", err.message);
    return null;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await req.json();
    const action = body.action;

    if (!action) {
      return jsonResponse({ error: "Missing 'action' parameter" }, 400);
    }

    // 1. ACTION: SEARCH
    if (action === "search") {
      const query = (body.query || "").trim();
      const pageNumber = parseNum(body.pageNumber, 0);
      const maxResults = Math.min(parseNum(body.maxResults, 20), 50);

      if (!query) {
        return jsonResponse({ foods: [], totalResults: 0 });
      }

      // Step 1 — Primary: FatSecret
      const fsFoods = await searchFatSecret(query, pageNumber, maxResults);
      if (fsFoods !== null && fsFoods.length > 0) {
        return jsonResponse({
          foods: fsFoods,
          totalResults: fsFoods.length,
          source: "fatsecret",
          attribution: "Powered by fatsecret nutrition API (www.fatsecret.com)",
        });
      }

      // Step 2 — Secondary Fallback: USDA FoodData Central
      console.log(`Fallback to USDA search for query: "${query}"`);
      const usdaFoods = await searchUsda(query, maxResults);
      if (usdaFoods !== null && usdaFoods.length > 0) {
        return jsonResponse({
          foods: usdaFoods,
          totalResults: usdaFoods.length,
          source: "usda",
          attribution: "Data provided by USDA FoodData Central (fdc.nal.usda.gov)",
        });
      }

      // Step 3 — Both external returned empty or failed -> Signal local fallback cleanly
      return jsonResponse({
        foods: [],
        totalResults: 0,
        source: "local",
        useLocalFallback: true,
        attribution: null,
      });
    }

    // 2. ACTION: DETAILS
    if (action === "details") {
      const foodId = String(body.foodId || "").trim();
      if (!foodId) {
        return jsonResponse({ error: "Missing 'foodId' parameter" }, 400);
      }

      // Route A: USDA Food Details
      if (foodId.startsWith("usda_")) {
        const fdcId = foodId.replace("usda_", "");
        const apiKey = Deno.env.get("USDA_API_KEY") || "DEMO_KEY";
        const res = await fetch(`https://api.nal.usda.gov/fdc/v1/food/${fdcId}?api_key=${apiKey}`, {
          headers: { "Accept": "application/json" },
        });

        if (res.ok) {
          const data = await res.json();
          return jsonResponse({
            food: normalizeUsdaFood(data),
            attribution: "Data provided by USDA FoodData Central (fdc.nal.usda.gov)",
          });
        }
        return jsonResponse({ error: "USDA food details not found" }, 404);
      }

      // Route B: FatSecret Food Details
      const rawFsId = foodId.replace("fatsecret_", "");
      try {
        const token = await getFatSecretToken();
        const params = new URLSearchParams({
          method: "food.get.v2",
          food_id: rawFsId,
          format: "json",
        });

        const fsRes = await fetch("https://platform.fatsecret.com/rest/server.api", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${token}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: params.toString(),
        });

        if (fsRes.ok) {
          const fsData = await fsRes.json();
          if (fsData.food && !fsData.error) {
            return jsonResponse({
              food: normalizeFatSecretFood(fsData.food),
              attribution: "Powered by fatsecret nutrition API (www.fatsecret.com)",
            });
          }
        }
      } catch (err: any) {
        console.warn("FatSecret details exception:", err.message);
      }

      return jsonResponse({ error: "Food details not found" }, 404);
    }

    return jsonResponse({ error: `Unknown action: ${action}` }, 400);
  } catch (err: any) {
    console.error("Internal Edge Function error:", err.message);
    return jsonResponse(
      {
        error: `Food service temporarily unavailable: ${err.message}`,
        useLocalFallback: true,
      },
      200
    );
  }
});
