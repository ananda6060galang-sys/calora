// Supabase Edge Function: scan-food
// AI Food Scanner Engine powered by Google Gemini Vision.
// Receives an image (base64) and uses Google Gemini Vision model
// to detect the food item and estimate portion & macronutrients.
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
 * Returns the authenticated user or null with an appropriate 401 error response.
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

// Server-side hard limit for incoming image payload: 2 MB
const MAX_IMAGE_BASE64_BYTES = 2 * 1024 * 1024; // 2,097,152 bytes (~2 MB)

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // 1. Enforce authentication first: only authenticated users may use AI scan quota
  const { user, errorResponse } = await authenticateUser(req);
  if (errorResponse) {
    return errorResponse;
  }

  // 2. Parse request body
  let body: any;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON payload" }, 400);
  }

  if (!body || typeof body !== "object") {
    return jsonResponse({ error: "Invalid request body" }, 400);
  }

  const rawImage = body.imageBase64 ?? body.image_base64;
  const mimeType = body.mimeType || body.mime_type || "image/jpeg";

  // 3. Validate image existence and type
  if (!rawImage) {
    return jsonResponse({ error: "Missing imageBase64 parameter" }, 400);
  }

  if (typeof rawImage !== "string") {
    return jsonResponse({ error: "Invalid imageBase64 parameter: expected string" }, 400);
  }

  // 4. Server-side payload size validation: reject payloads exceeding 2 MB before touching Gemini
  if (rawImage.length > MAX_IMAGE_BASE64_BYTES) {
    return jsonResponse({ error: "Image payload too large" }, 413);
  }

  // Strip data url prefix if present
  const cleanBase64 = rawImage.replace(/^data:image\/[a-z]+;base64,/, "");

  if (!cleanBase64) {
    return jsonResponse({ error: "Missing imageBase64 parameter" }, 400);
  }

  // 5. Verify Gemini API key is configured
  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiKey) {
    return jsonResponse(
      { error: "GEMINI_API_KEY is not configured in Supabase Edge Function secrets" },
      500
    );
  }

  try {

    // Explicit model IDs only — predictable routing & quota.
    // Primary model: gemini-3.1-flash-lite (15 RPM / 250K TPM / 500 RPD).
    // Explicit compatible fallback: gemini-3.1-flash-lite-preview.
    // Generic "latest" aliases removed (no gemini-flash-latest, gemini-flash-lite-latest).
    // Heavy models removed (no gemini-3.6-flash, gemini-3.5-flash).
    const candidateModels = [
      "gemini-3.1-flash-lite",
      "gemini-3.1-flash-lite-preview",
    ];

    const promptText = `You are a certified clinical nutritionist and food vision AI.
Analyze the provided food photo with high accuracy. Identify:
1. Primary food or dish name (in English, concise and descriptive).
2. Estimated portion size description (e.g. "1 medium plate", "1 bowl", "150g portion").
3. Estimated portion weight in grams (number only).
4. Estimated Calories (kcal, integer).
5. Estimated Protein in grams (number).
6. Estimated Carbohydrates in grams (number).
7. Estimated Fat in grams (number).
8. Confidence score between 0.0 and 1.0.
9. List of recognized ingredients.

Return ONLY a valid JSON object strictly matching this schema:
{
  "foodName": string,
  "portionDescription": string,
  "portionGrams": number,
  "calories": number,
  "proteinG": number,
  "carbsG": number,
  "fatG": number,
  "confidence": number,
  "ingredients": string[]
}`;

    const geminiPayload = {
      contents: [
        {
          parts: [
            { text: promptText },
            {
              inline_data: {
                mime_type: mimeType,
                data: cleanBase64,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.2,
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

        if (res.ok) {
          const result = await res.json();
          const candidate = result.candidates?.[0];
          const text = candidate?.content?.parts?.[0]?.text;
          if (text) {
            textOutput = text;
            successfulModel = model;
            break;
          }
        } else {
          lastError = await res.text();
          console.warn(`Model ${model} returned HTTP ${res.status}:`, lastError);
        }
      } catch (err: any) {
        lastError = err.message;
        console.warn(`Model ${model} invocation error:`, lastError);
      }
    }

    if (!textOutput || !successfulModel) {
      return jsonResponse(
        {
          error: "Gemini Vision API error across available models",
          details: lastError,
          isSimulator: false,
        },
        502
      );
    }

    let parsedNutrition: any;
    try {
      parsedNutrition = JSON.parse(textOutput);
    } catch {
      const jsonMatch = textOutput.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        parsedNutrition = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error("Unable to parse structured JSON from vision response");
      }
    }

    const foodName = parsedNutrition.foodName || "Recognized Meal";
    const portionGrams = Number(parsedNutrition.portionGrams) || 100;
    const calories = Math.round(Number(parsedNutrition.calories) || 0);
    const proteinG = Math.round((Number(parsedNutrition.proteinG) || 0) * 10) / 10;
    const carbsG = Math.round((Number(parsedNutrition.carbsG) || 0) * 10) / 10;
    const fatG = Math.round((Number(parsedNutrition.fatG) || 0) * 10) / 10;
    const confidence = Math.min(Math.max(Number(parsedNutrition.confidence) || 0.85, 0.1), 0.99);
    const ingredients = Array.isArray(parsedNutrition.ingredients) ? parsedNutrition.ingredients : [];
    const portionDescription = parsedNutrition.portionDescription || `${portionGrams}g`;

    const servingLabel = `${portionDescription} (${portionGrams}g)`;
    const foodId = `ai_${Date.now()}`;

    const normalizedFood = {
      id: foodId,
      name: foodName,
      servingLabel: servingLabel,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      category: "AI Scan",
      portionGrams: portionGrams,
      source: "ai_scan",
      servings: [
        {
          servingId: `${foodId}_s1`,
          servingDescription: servingLabel,
          metricServingAmount: portionGrams,
          metricServingUnit: "g",
          numberOfUnits: 1.0,
          measurementDescription: servingLabel,
          calories: calories,
          proteinG: proteinG,
          carbsG: carbsG,
          fatG: fatG,
        },
      ],
      confidence: confidence,
      ingredients: ingredients,
    };

    return jsonResponse({
      success: true,
      food: normalizedFood,
      provider: "gemini",
      model: successfulModel,
      isSimulator: false,
    });
  } catch (err: any) {
    console.error("Internal scan-food error:", err.message);
    return jsonResponse(
      {
        error: `Food scan failed: ${err.message}`,
        isSimulator: false,
      },
      500
    );
  }
});
