const express = require('express');
const axios = require('axios');
const FoodLog = require('../models/FoodLog');
const Meal = require('../models/Meal');
const { requireUnifiedAuth: requireAuth } = require('../middleware/unifiedAuth');

const router = express.Router();

// ─── API Keys ───
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY || '';

// ─── Analysis Prompt (shared across all providers) ───
const ANALYSIS_PROMPT = `You are a professional nutritionist AI. Analyze the food in this image and return a JSON object with these exact fields:
{
  "foodName": "descriptive name of the food/dish",
  "calories": <number - estimated total calories in kcal>,
  "protein": <number - grams of protein>,
  "carbs": <number - grams of carbohydrates>,
  "fats": <number - grams of fat>,
  "fiber": <number - grams of fiber>,
  "confidence": <number between 0 and 1 - how confident you are>,
  "servingSize": "estimated serving size description"
}

Rules:
- Return ONLY the raw JSON object, no markdown, no explanation
- If you cannot identify food in the image, return: {"error": "No food detected in image"}
- Estimate for a single typical serving visible in the image
- Be as accurate as possible with nutritional estimates`;

// ─── Provider Definitions (ordered by priority) ───

/**
 * Each provider has:
 *   name     — human-readable label (for logging)
 *   enabled  — whether the required API key is present
 *   call     — async function(cleanBase64, mimeType) => raw text response
 */
function getProviders() {
  return [
    // 1. Gemini 2.5 Flash (best quality, free tier)
    {
      name: 'Gemini 2.5 Flash',
      enabled: !!GEMINI_API_KEY,
      call: (base64, mime) => callGemini('gemini-2.5-flash', base64, mime),
    },
    // 2. Gemini 2.5 Flash-Lite (lighter, free tier)
    {
      name: 'Gemini 2.5 Flash-Lite',
      enabled: !!GEMINI_API_KEY,
      call: (base64, mime) => callGemini('gemini-2.5-flash-lite', base64, mime),
    },
    // 3. OpenRouter free vision model (fallback)
    {
      name: 'black-forest-labs/flux.2-pro',
      enabled: !!OPENROUTER_API_KEY,
      call: (base64, mime) => callOpenRouter(base64, mime),
    },
  ];
}

// ─── Gemini API caller ───
async function callGemini(model, base64, mimeType) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`;

  const response = await axios.post(
    url,
    {
      contents: [
        {
          parts: [
            { text: ANALYSIS_PROMPT },
            {
              inline_data: {
                mime_type: mimeType,
                data: base64,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 1024,
      },
    },
    {
      headers: { 'Content-Type': 'application/json' },
      timeout: 60000,
    }
  );

  return response.data?.candidates?.[0]?.content?.parts?.[0]?.text || '';
}

// ─── OpenRouter API caller ───
async function callOpenRouter(base64, mimeType) {
  const dataUri = `data:${mimeType};base64,${base64}`;

  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'google/gemma-3-12b-it:free',
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: ANALYSIS_PROMPT },
            {
              type: 'image_url',
              image_url: { url: dataUri },
            },
          ],
        },
      ],
      temperature: 0.1,
      max_tokens: 1024,
    },
    {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${OPENROUTER_API_KEY}`,
        'HTTP-Referer': 'http://localhost:4000',
        'X-Title': 'NutriPal',
      },
      timeout: 60000,
    }
  );

  return response.data?.choices?.[0]?.message?.content || '';
}

// ─── Determine if error is a rate-limit (429) or quota-exceeded ───
function isRateLimitError(error) {
  const status = error.response?.status;
  if (status === 429) return true;
  // Gemini returns 429 or 403 for quota exceeded
  if (status === 403) {
    const msg = JSON.stringify(error.response?.data || '').toLowerCase();
    if (msg.includes('quota') || msg.includes('rate') || msg.includes('limit')) {
      return true;
    }
  }
  return false;
}

// ─── Cascading analysis: try providers in order ───
async function analyzeWithFallback(cleanBase64, mimeType) {
  const providers = getProviders().filter((p) => p.enabled);

  if (providers.length === 0) {
    throw new Error('No AI API keys configured. Set GEMINI_API_KEY and/or OPENROUTER_API_KEY in .env');
  }

  const errors = [];

  for (const provider of providers) {
    try {
      console.log(`[FoodLog] Trying ${provider.name}...`);
      const textResponse = await provider.call(cleanBase64, mimeType);

      // Parse JSON from response (handle markdown wrapping)
      const jsonStr = textResponse.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      const parsed = JSON.parse(jsonStr);

      if (parsed.error) {
        // AI identified no food — not a rate-limit, propagate immediately
        throw new Error(parsed.error);
      }

      console.log(`[FoodLog] ✅ Success with ${provider.name}`);

      return {
        foodName: parsed.foodName || 'Unknown Food',
        calories: Math.round(Number(parsed.calories) || 0),
        protein: Math.round(Number(parsed.protein) || 0),
        carbs: Math.round(Number(parsed.carbs) || 0),
        fats: Math.round(Number(parsed.fats) || 0),
        fiber: Math.round(Number(parsed.fiber) || 0),
        confidence: Math.min(1, Math.max(0, Number(parsed.confidence) || 0)),
        servingSize: parsed.servingSize || '',
        provider: provider.name,
      };
    } catch (err) {
      const providerError = {
        provider: provider.name,
        message: err.response?.data?.error?.message || err.message,
        status: err.response?.status,
      };
      errors.push(providerError);

      if (isRateLimitError(err)) {
        console.warn(`[FoodLog] ⚠️  ${provider.name} rate-limited (${err.response?.status}), trying next...`);
        continue; // try next provider
      }

      // For non-rate-limit errors (bad JSON, no food, network), still try next
      console.warn(`[FoodLog] ⚠️  ${provider.name} failed: ${providerError.message}`);
      continue;
    }
  }

  // All providers failed
  const summary = errors.map((e) => `${e.provider}: ${e.message}`).join(' | ');
  throw new Error(`All AI providers failed — ${summary}`);
}

// ─── POST /analyze — Analyze food image with AI (cascading fallback) ───
router.post('/analyze', requireAuth, async (req, res) => {
  try {
    const { imageBase64, mimeType } = req.body;

    if (!imageBase64) {
      return res.status(400).json({ message: 'imageBase64 is required' });
    }

    // Clean base64 — strip data URL prefix if present
    const cleanBase64 = imageBase64.replace(/^data:image\/\w+;base64,/, '');
    const resolvedMime = mimeType || 'image/jpeg';

    const result = await analyzeWithFallback(cleanBase64, resolvedMime);

    return res.json({ analysis: result });
  } catch (error) {
    console.error('Food analysis error:', error.message);
    return res.status(500).json({
      message: 'Failed to analyze food image',
      error: error.message,
    });
  }
});

// ─── POST /save — Save AI analysis as a food log + meal ───
router.post('/save', requireAuth, async (req, res) => {
  try {
    const { foodName, mealType, calories, protein, carbs, fats, fiber, confidence } = req.body;

    if (!foodName) {
      return res.status(400).json({ message: 'foodName is required' });
    }

    // Create the meal entry (reuses existing Meal model)
    const meal = await Meal.create({
      userId: req.user.id || req.user._id,
      mealName: foodName,
      mealType: mealType || 'Snack',
      calories: Math.round(Number(calories) || 0),
      protein: Math.round(Number(protein) || 0),
      carbs: Math.round(Number(carbs) || 0),
      fats: Math.round(Number(fats) || 0),
    });

    // Also create food log for history
    const foodLog = await FoodLog.create({
      userId: req.user.id || req.user._id,
      foodName,
      mealType: mealType || 'Snack',
      calories: Math.round(Number(calories) || 0),
      protein: Math.round(Number(protein) || 0),
      carbs: Math.round(Number(carbs) || 0),
      fats: Math.round(Number(fats) || 0),
      fiber: Math.round(Number(fiber) || 0),
      confidence: Number(confidence) || 0,
      savedToMeals: true,
      mealId: meal._id,
    });

    return res.status(201).json({ meal, foodLog });
  } catch (error) {
    console.error('Save food log error:', error.message);
    return res.status(500).json({ message: 'Failed to save food log' });
  }
});

// ─── GET / — Get user's AI food log history ───
router.get('/', requireAuth, async (req, res) => {
  const logs = await FoodLog.find({ userId: req.user.id || req.user._id })
    .sort({ createdAt: -1 })
    .limit(50);
  return res.json({ logs });
});

module.exports = router;
