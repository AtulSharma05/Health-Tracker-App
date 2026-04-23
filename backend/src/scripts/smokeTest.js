/**
 * Smoke Test — Phase 6
 *
 * Tests all critical user journeys against the running backend:
 *   1. Register (email/password)
 *   2. Email verification
 *   3. Login
 *   4. Profile / Onboarding
 *   5. Meal logging
 *   6. Workout logging
 *   7. Workout stats
 *   8. Meal plan generation
 *   9. AI planner status
 *  10. Pose service health
 *  11. Exercise search
 *  12. Google auth flow
 *
 * Usage:
 *   node src/scripts/smokeTest.js
 *   node src/scripts/smokeTest.js --base-url http://localhost:4000
 */

const BASE_URL = (() => {
  const idx = process.argv.indexOf('--base-url');
  return idx !== -1 ? process.argv[idx + 1] : 'http://localhost:4000';
})();

const API = `${BASE_URL}/api/v1`;

let passed = 0;
let failed = 0;
let skipped = 0;
const results = [];

function log(status, name, detail) {
  const icon = status === 'PASS' ? '✅' : status === 'FAIL' ? '❌' : '⏭️';
  console.log(`  ${icon}  ${name}${detail ? ' — ' + detail : ''}`);
  results.push({ status, name, detail });
  if (status === 'PASS') passed++;
  else if (status === 'FAIL') failed++;
  else skipped++;
}

async function json(url, opts = {}) {
  const res = await fetch(url, {
    ...opts,
    headers: { 'Content-Type': 'application/json', ...(opts.headers || {}) },
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  return { status: res.status, data, ok: res.ok };
}

async function run() {
  console.log('═══════════════════════════════════════════');
  console.log('  NutriPal Integration Smoke Test');
  console.log('═══════════════════════════════════════════');
  console.log(`  Target: ${BASE_URL}`);
  console.log('');

  const ts = Date.now();
  const email = `smoketest${ts}@test.com`;
  const password = 'smoke1234';
  const name = 'SmokeTestUser';
  let token = '';
  let devVerificationToken = '';

  // ── 1. Health ──
  try {
    const r = await json(`${BASE_URL}/health`);
    r.status === 200 && r.data.status === 'ok'
      ? log('PASS', 'Health check', `status=${r.data.status}`)
      : log('FAIL', 'Health check', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'Health check', `Server unreachable: ${e.message}`);
    console.log('\n❌ Cannot reach server. Aborting.');
    return;
  }

  // ── 2. Register ──
  try {
    const r = await json(`${API}/auth/register`, {
      method: 'POST',
      body: { name, email, password },
    });
    if (r.status === 201 && r.data.token) {
      token = r.data.token;
      devVerificationToken = r.data.devVerificationToken || '';
      log('PASS', 'Register', `email=${email}`);
    } else {
      log('FAIL', 'Register', `status=${r.status} ${r.data.message || ''}`);
    }
  } catch (e) {
    log('FAIL', 'Register', e.message);
  }

  const authHeaders = { Authorization: `Bearer ${token}` };

  // ── 3. Email verification (using dev token) ──
  if (devVerificationToken) {
    try {
      const r = await json(`${API}/auth/verify-email`, {
        method: 'POST',
        body: { token: devVerificationToken },
      });
      r.ok
        ? log('PASS', 'Email verification', 'verified via dev token')
        : log('FAIL', 'Email verification', `status=${r.status}`);
    } catch (e) {
      log('FAIL', 'Email verification', e.message);
    }
  } else {
    log('SKIP', 'Email verification', 'No dev token (email sent instead)');
  }

  // ── 4. Login ──
  try {
    const r = await json(`${API}/auth/login`, {
      method: 'POST',
      body: { email, password },
    });
    if (r.ok && r.data.token) {
      token = r.data.token; // use fresh token
      authHeaders.Authorization = `Bearer ${token}`;
      log('PASS', 'Login', `isEmailVerified=${r.data.user?.isEmailVerified}`);
    } else {
      log('FAIL', 'Login', `status=${r.status}`);
    }
  } catch (e) {
    log('FAIL', 'Login', e.message);
  }

  // ── 5. GET /auth/me ──
  try {
    const r = await json(`${API}/auth/me`, { headers: authHeaders });
    r.ok && r.data.user?.email === email
      ? log('PASS', 'GET /auth/me', `email=${r.data.user.email}`)
      : log('FAIL', 'GET /auth/me', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'GET /auth/me', e.message);
  }

  // ── 6. Onboarding (PUT /profile) ──
  try {
    const r = await json(`${API}/profile`, {
      method: 'PUT',
      headers: authHeaders,
      body: {
        weightKg: 75,
        heightCm: 178,
        age: 28,
        gender: 'male',
        activityLevel: 'moderate',
        goalType: 'recomp',
      },
    });
    r.ok
      ? log('PASS', 'Onboarding (PUT /profile)', `TDEE=${r.data.calculations?.targetCalories || '?'}`)
      : log('FAIL', 'Onboarding (PUT /profile)', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'Onboarding (PUT /profile)', e.message);
  }

  // ── 7. GET /profile ──
  try {
    const r = await json(`${API}/profile`, { headers: authHeaders });
    r.ok && r.data.profile
      ? log('PASS', 'GET /profile', `weight=${r.data.profile.weightKg}kg`)
      : log('FAIL', 'GET /profile', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'GET /profile', e.message);
  }

  // ── 8. Log a meal ──
  try {
    const r = await json(`${API}/meals`, {
      method: 'POST',
      headers: authHeaders,
      body: {
        mealName: 'Smoke Test Oatmeal',
        mealType: 'Breakfast',
        calories: 350,
        protein: 12,
        carbs: 55,
        fats: 8,
      },
    });
    r.status === 201
      ? log('PASS', 'Log meal', `id=${r.data.meal?._id}`)
      : log('FAIL', 'Log meal', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'Log meal', e.message);
  }

  // ── 9. GET /meals ──
  try {
    const r = await json(`${API}/meals`, { headers: authHeaders });
    r.ok && Array.isArray(r.data.meals)
      ? log('PASS', 'GET /meals', `count=${r.data.meals.length}`)
      : log('FAIL', 'GET /meals', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'GET /meals', e.message);
  }

  // ── 10. Log a workout ──
  try {
    const r = await json(`${API}/workouts`, {
      method: 'POST',
      headers: authHeaders,
      body: {
        exerciseName: 'Smoke Test Push-ups',
        workoutType: 'strength',
        duration: 25,
        caloriesBurned: 150,
        intensityLevel: 'moderate',
      },
    });
    r.status === 201
      ? log('PASS', 'Log workout', `id=${r.data.data?.workout?._id}`)
      : log('FAIL', 'Log workout', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'Log workout', e.message);
  }

  // ── 11. GET /workouts ──
  try {
    const r = await json(`${API}/workouts`, { headers: authHeaders });
    r.ok && r.data.success
      ? log('PASS', 'GET /workouts', `count=${r.data.data?.workouts?.length}`)
      : log('FAIL', 'GET /workouts', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'GET /workouts', e.message);
  }

  // ── 12. Workout stats ──
  try {
    const r = await json(`${API}/workouts/stats`, { headers: authHeaders });
    r.ok && r.data.success
      ? log('PASS', 'Workout stats', `total=${r.data.data?.overview?.totalWorkouts}`)
      : log('FAIL', 'Workout stats', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'Workout stats', e.message);
  }

  // ── 13. Meal plan generation ──
  try {
    const r = await json(`${API}/plans/generate`, {
      method: 'POST',
      headers: authHeaders,
      body: { planName: 'Smoke Test Plan' },
    });
    r.status === 201
      ? log('PASS', 'Generate meal plan', `planId=${r.data.planId}`)
      : log('FAIL', 'Generate meal plan', `status=${r.status} ${r.data.message || ''}`);
  } catch (e) {
    log('FAIL', 'Generate meal plan', e.message);
  }

  // ── 14. AI planner status (optional — may not be running) ──
  try {
    const r = await json(`${API}/workout-plans/status`, { headers: authHeaders });
    if (r.ok) {
      const status = r.data.data?.status || 'unknown';
      log(status === 'online' ? 'PASS' : 'SKIP', 'AI planner status', `status=${status}`);
    } else {
      log('FAIL', 'AI planner status', `status=${r.status}`);
    }
  } catch (e) {
    log('SKIP', 'AI planner status', 'Service not available');
  }

  // ── 15. Pose service health (optional — may not be running) ──
  try {
    const r = await json(`${API}/pose/health`);
    const status = r.data.status || 'unknown';
    log(status === 'available' ? 'PASS' : 'SKIP', 'Pose service health', `status=${status}`);
  } catch (e) {
    log('SKIP', 'Pose service health', 'Service not available');
  }

  // ── 16. Exercise search ──
  try {
    const r = await json(`${API}/exercises/search?name=bench+press`);
    r.ok && r.data.success
      ? log('PASS', 'Exercise search', `found=${r.data.data?.exercise?.name}`)
      : log('FAIL', 'Exercise search', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'Exercise search', e.message);
  }

  // ── 17. Google auth (simulated) ──
  try {
    const r = await json(`${API}/auth/google`, {
      method: 'POST',
      body: {
        googleId: `smoke_google_${ts}`,
        email: `smokegoogle${ts}@test.com`,
        name: 'Google Smoke User',
      },
    });
    r.ok && r.data.token
      ? log('PASS', 'Google auth', `userId=${r.data.user?.id}`)
      : log('FAIL', 'Google auth', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'Google auth', e.message);
  }

  // ── 18. 404 handler ──
  try {
    const r = await json(`${API}/nonexistent-path`);
    r.status === 404
      ? log('PASS', '404 handler', 'Proper error response')
      : log('FAIL', '404 handler', `status=${r.status}`);
  } catch (e) {
    log('FAIL', '404 handler', e.message);
  }

  // ── 19. Auth rejection (no token) ──
  try {
    const r = await json(`${API}/meals`);
    r.status === 401
      ? log('PASS', 'Auth rejection (no token)', '401 returned')
      : log('FAIL', 'Auth rejection (no token)', `status=${r.status}`);
  } catch (e) {
    log('FAIL', 'Auth rejection (no token)', e.message);
  }

  // ══════════════════════════════════════════
  //  Summary
  // ══════════════════════════════════════════
  console.log('\n═══════════════════════════════════════════');
  console.log('  Smoke Test Results');
  console.log('═══════════════════════════════════════════');
  console.log(`  ✅ Passed:  ${passed}`);
  console.log(`  ❌ Failed:  ${failed}`);
  console.log(`  ⏭️  Skipped: ${skipped}`);
  console.log(`  Total:     ${passed + failed + skipped}`);
  console.log('═══════════════════════════════════════════');

  if (failed > 0) {
    console.log('\n❌ SMOKE TEST FAILED — check failures above.');
    process.exit(1);
  } else {
    console.log('\n✅ ALL CRITICAL FLOWS PASSED.');
    process.exit(0);
  }
}

run().catch((err) => {
  console.error('❌ Smoke test crashed:', err);
  process.exit(1);
});
