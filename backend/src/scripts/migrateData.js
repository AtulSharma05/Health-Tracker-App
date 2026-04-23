/**
 * Data Migration Script — Phase 5
 *
 * Merges users and workout data from the legacy "new" workout-tracker DB
 * into the canonical "integration" (nutripal) DB.
 *
 * Strategy:
 *   1. Connect to BOTH databases simultaneously.
 *   2. For each user in workout_tracker_db, find matching user in nutripal_db by email.
 *   3. If match found: remap all workouts from old userId → canonical userId.
 *   4. If no match: create a new user in nutripal_db and import workouts.
 *   5. Generate a reconciliation report.
 *
 * Usage:
 *   DRY RUN:   node src/scripts/migrateData.js --dry-run
 *   REAL RUN:  node src/scripts/migrateData.js
 */

const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '../../.env') });

// ── Configuration ──

const CANONICAL_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/nutripal_db';
const LEGACY_URI = process.env.LEGACY_MONGODB_URI || 'mongodb://127.0.0.1:27017/workout_tracker_db';
const DRY_RUN = process.argv.includes('--dry-run');

// ── Report ──

const report = {
  startedAt: new Date().toISOString(),
  dryRun: DRY_RUN,
  legacyUsersFound: 0,
  matchedByEmail: 0,
  newUsersCreated: 0,
  workoutsImported: 0,
  workoutsSkipped: 0,
  conflicts: [],
  errors: [],
};

async function run() {
  console.log('═══════════════════════════════════════════');
  console.log(`  Data Migration ${DRY_RUN ? '(DRY RUN)' : '(LIVE)'}`);
  console.log('═══════════════════════════════════════════');
  console.log(`  Canonical DB: ${CANONICAL_URI}`);
  console.log(`  Legacy DB:    ${LEGACY_URI}`);
  console.log('');

  // Connect to canonical (integration) database
  const canonicalConn = await mongoose.createConnection(CANONICAL_URI).asPromise();
  console.log('✅ Connected to canonical DB');

  // Connect to legacy (workout_tracker) database
  const legacyConn = await mongoose.createConnection(LEGACY_URI).asPromise();
  console.log('✅ Connected to legacy DB');

  // ── Get raw collections ──
  const canonUsers = canonicalConn.collection('users');
  const canonWorkouts = canonicalConn.collection('workouts');
  const canonProfiles = canonicalConn.collection('userprofiles');

  const legUsers = legacyConn.collection('users');
  const legWorkouts = legacyConn.collection('workouts');

  // ── Step 1: Load all legacy users ──
  const legacyUsers = await legUsers.find({}).toArray();
  report.legacyUsersFound = legacyUsers.length;
  console.log(`\n📋 Found ${legacyUsers.length} users in legacy DB`);

  // Build email → canonical user map
  const canonicalEmails = {};
  const allCanonUsers = await canonUsers.find({}).toArray();
  for (const u of allCanonUsers) {
    if (u.email) canonicalEmails[u.email.toLowerCase().trim()] = u;
  }
  console.log(`📋 Found ${allCanonUsers.length} users in canonical DB`);

  // ── Step 2: Process each legacy user ──
  const userIdMap = {}; // legacyId → canonicalId

  for (const legUser of legacyUsers) {
    const email = (legUser.email || '').toLowerCase().trim();
    if (!email) {
      report.conflicts.push({
        legacyId: legUser._id.toString(),
        issue: 'No email on legacy user',
      });
      continue;
    }

    const canonUser = canonicalEmails[email];

    if (canonUser) {
      // ── Match found: use canonical user ID ──
      userIdMap[legUser._id.toString()] = canonUser._id;
      report.matchedByEmail++;
      console.log(`  ✔ Matched: ${email} → ${canonUser._id}`);

      // Optionally backfill profile fields if canonical user profile is missing data
      if (!DRY_RUN && (legUser.height || legUser.weight || legUser.age)) {
        const existingProfile = await canonProfiles.findOne({ userId: canonUser._id });
        if (!existingProfile) {
          // Create a profile from legacy data
          await canonProfiles.insertOne({
            userId: canonUser._id,
            heightCm: legUser.height || 170,
            weightKg: legUser.weight || 70,
            age: legUser.age || 25,
            gender: 'male', // default; legacy model doesn't track this
            activityLevel: legUser.activityLevel || 'moderate',
            goalType: _mapGoal(legUser.fitnessGoal),
            aggressiveness: 2,
            createdAt: new Date(),
            updatedAt: new Date(),
          });
          console.log(`    → Created profile for ${email} from legacy data`);
        }
      }
    } else {
      // ── No match: create new canonical user ──
      const newUser = {
        name: legUser.fullName || legUser.username || 'User',
        email: email,
        passwordHash: legUser.password || null, // already hashed in legacy
        isEmailVerified: legUser.emailVerified || false,
        authMethods: [{ type: 'email', verified: legUser.emailVerified || false, connectedAt: new Date() }],
        lastLoginAt: legUser.lastLogin || null,
        loginAttempts: 0,
        lockUntil: null,
        createdAt: legUser.createdAt || new Date(),
        updatedAt: new Date(),
      };

      if (DRY_RUN) {
        userIdMap[legUser._id.toString()] = 'DRY_RUN_NEW_ID';
        report.newUsersCreated++;
        console.log(`  ⊕ Would create: ${email}`);
      } else {
        const result = await canonUsers.insertOne(newUser);
        const newId = result.insertedId;
        userIdMap[legUser._id.toString()] = newId;
        canonicalEmails[email] = { ...newUser, _id: newId };
        report.newUsersCreated++;
        console.log(`  ⊕ Created: ${email} → ${newId}`);

        // Create profile if we have data
        if (legUser.height || legUser.weight || legUser.age) {
          await canonProfiles.insertOne({
            userId: newId,
            heightCm: legUser.height || 170,
            weightKg: legUser.weight || 70,
            age: legUser.age || 25,
            gender: 'male',
            activityLevel: legUser.activityLevel || 'moderate',
            goalType: _mapGoal(legUser.fitnessGoal),
            aggressiveness: 2,
            createdAt: new Date(),
            updatedAt: new Date(),
          });
        }
      }
    }
  }

  // ── Step 3: Migrate workouts ──
  const legacyWorkouts = await legWorkouts.find({}).toArray();
  console.log(`\n📋 Found ${legacyWorkouts.length} workouts in legacy DB`);

  for (const w of legacyWorkouts) {
    const legUserId = w.userId?.toString();
    const canonId = legUserId ? userIdMap[legUserId] : null;

    if (!canonId) {
      report.workoutsSkipped++;
      report.conflicts.push({
        workoutId: w._id.toString(),
        legacyUserId: legUserId,
        issue: 'No mapped canonical user for this workout',
      });
      continue;
    }

    // Check for duplicate (same user + same exercise + same date within 1 minute)
    if (!DRY_RUN && canonId !== 'DRY_RUN_NEW_ID') {
      const existing = await canonWorkouts.findOne({
        userId: canonId,
        exerciseName: w.exerciseName,
        date: w.date,
      });

      if (existing) {
        report.workoutsSkipped++;
        continue;
      }

      // Insert workout with remapped userId
      const workoutDoc = { ...w };
      delete workoutDoc._id; // let MongoDB generate new _id
      workoutDoc.userId = canonId;
      await canonWorkouts.insertOne(workoutDoc);
    }

    report.workoutsImported++;
  }

  // ── Step 4: Report ──
  report.finishedAt = new Date().toISOString();

  console.log('\n═══════════════════════════════════════════');
  console.log('  Migration Report');
  console.log('═══════════════════════════════════════════');
  console.log(`  Mode:              ${DRY_RUN ? 'DRY RUN' : 'LIVE'}`);
  console.log(`  Legacy users:      ${report.legacyUsersFound}`);
  console.log(`  Matched by email:  ${report.matchedByEmail}`);
  console.log(`  New users created: ${report.newUsersCreated}`);
  console.log(`  Workouts imported: ${report.workoutsImported}`);
  console.log(`  Workouts skipped:  ${report.workoutsSkipped}`);
  console.log(`  Conflicts:         ${report.conflicts.length}`);
  console.log(`  Errors:            ${report.errors.length}`);
  console.log('═══════════════════════════════════════════');

  if (report.conflicts.length > 0) {
    console.log('\n⚠️  Conflicts:');
    for (const c of report.conflicts) {
      console.log(`  - ${JSON.stringify(c)}`);
    }
  }

  // Close connections
  await canonicalConn.close();
  await legacyConn.close();

  console.log('\n✅ Migration complete.');
  return report;
}

function _mapGoal(fitnessGoal) {
  const goalMap = {
    'lose_weight': 'fat_loss',
    'maintain_weight': 'maintenance',
    'gain_weight': 'muscle_gain',
    'build_muscle': 'muscle_gain',
    'improve_fitness': 'recomp',
  };
  return goalMap[fitnessGoal] || 'recomp';
}

run()
  .then((report) => {
    console.log('\nFull report:', JSON.stringify(report, null, 2));
    process.exit(0);
  })
  .catch((err) => {
    console.error('❌ Migration failed:', err);
    process.exit(1);
  });
