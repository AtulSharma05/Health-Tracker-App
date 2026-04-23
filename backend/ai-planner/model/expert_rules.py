"""Expert-rule overlay to refine model predictions and produce better weekly schedules.

This is a core production module that provides:
- Exercise substitution based on equipment and injuries
- Safety constraints and volume caps
- Multi-week progression planning
- Smart exercise scheduling (push/pull/legs splits)
"""
from collections import defaultdict
import os
import json


def choose_split(days, goal):
    # Return a split type string based on days and goal
    if days <= 2:
        return "full_body"
    if days == 3:
        return "full_body_plus"
    if days == 4:
        return "upper_lower"
    if days == 5:
        return "push_pull_legs_plus"
    return "push_pull_legs"


def refine_predictions(preds, profile):
    # preds: {Exercise: {sets,reps,intensity}}
    # Apply simple expert rules:
    # - If goal is Strength => increase intensity by 1 and lower reps by 1-2
    # - If goal is Endurance => increase reps by 2 and lower intensity
    # - Cap weekly sets per muscle group to a safe limit (e.g., 20)
    goal = profile.get('Goal', '')
    days = profile.get('Days_per_Week', 4)

    # Adjustments
    for ex, v in preds.items():
        if goal == 'Strength':
            v['intensity'] = min(10, v['intensity'] + 1)
            v['reps'] = max(3, v['reps'] - 1)
        elif goal == 'Endurance':
            v['reps'] = v['reps'] + 2
            v['intensity'] = max(1, v['intensity'] - 1)
        elif goal == 'Muscle Gain':
            # small bump in sets for hypertrophy
            v['sets'] = int(round(v['sets'] * 1.05))

    # Safety caps: simple muscle group mapping and weekly set cap
    muscle_map = {
        'Bench': 'chest', 'OverheadPress': 'shoulders', 'Row': 'back',
        'Squat': 'legs', 'Deadlift': 'posterior_chain'
    }
    weekly_cap = {'legs': 25, 'chest': 20, 'back': 20, 'shoulders': 15, 'posterior_chain': 20}

    # Compute weekly total sets per muscle
    weekly_sets = defaultdict(int)
    for ex, v in preds.items():
        mg = muscle_map.get(ex, 'other')
        weekly_sets[mg] += v['sets']

    # If over cap, scale down proportionally
    for mg, total in list(weekly_sets.items()):
        cap = weekly_cap.get(mg, 30)
        if total > cap:
            scale = cap / total
            for ex, v in preds.items():
                if muscle_map.get(ex) == mg:
                    v['sets'] = max(1, int(round(v['sets'] * scale)))

    return preds


def schedule_exercises(preds, days):
    # Better scheduler: distribute exercises across week with proper spacing
    exercises = list(preds.keys())
    
    # Create schedule for a full week (7 days) with proper rest day spacing
    schedule = {d: [] for d in range(1, 8)}
    
    if days <= 2:
        # For 1-2 days, space them out in the week
        training_days = [1, 4] if days == 2 else [3]
        for i, ex in enumerate(exercises):
            day = training_days[i % days]
            schedule[day].append((ex, preds[ex]))
        return schedule
    
    # For 3+ days, use optimal spacing throughout the week
    if days == 3:
        training_days = [1, 3, 5]  # Mon, Wed, Fri
    elif days == 4:
        training_days = [1, 2, 4, 5]  # Mon, Tue, Thu, Fri
    elif days == 5:
        training_days = [1, 2, 3, 5, 6]  # Mon-Wed, Fri-Sat
    elif days == 6:
        training_days = [1, 2, 3, 4, 5, 6]  # Mon-Sat
    else:  # 7 days
        training_days = [1, 2, 3, 4, 5, 6, 7]  # All days
    
    # Clear the schedule and only use training days
    schedule = {d: [] for d in range(1, 8)}
    
    # Categorize exercises by type for better distribution
    push = {'Bench','OverheadPress', 'bench press', 'overhead press', 'push', 'press', 'dip', 'handstand'}
    pull = {'Row', 'row', 'pull', 'curl'}
    legs = {'Squat','Deadlift', 'squat', 'deadlift', 'leg', 'femoral', 'hamstring'}
    stretch = {'stretch', 'runners stretch', 'hamstring stretch'}
    
    # Categorize all exercises
    push_exercises = [ex for ex in exercises if any(p in ex.lower() for p in push)]
    pull_exercises = [ex for ex in exercises if any(p in ex.lower() for p in pull)]
    leg_exercises = [ex for ex in exercises if any(l in ex.lower() for l in legs)]
    stretch_exercises = [ex for ex in exercises if any(s in ex.lower() for s in stretch)]
    other_exercises = [ex for ex in exercises if ex not in push_exercises + pull_exercises + leg_exercises + stretch_exercises]
    
    # Distribute exercises evenly across all training days using round-robin
    all_workout_exercises = [ex for ex in exercises if ex not in stretch_exercises]
    
    # Round-robin distribution to ensure all days get exercises
    day_idx = 0
    for ex in all_workout_exercises:
        schedule[training_days[day_idx]].append((ex, preds[ex]))
        day_idx = (day_idx + 1) % len(training_days)
    
    # Add stretches to each training day
    for day in training_days:
        for ex in stretch_exercises:
            schedule[day].append((ex, preds[ex]))
    
    return schedule


def generate_multiweek(preds, weeks=4, progression='linear'):
    # preds: base week predictions; return list of week-wise preds
    # progression: 'linear' increases intensity by +1 every 2 weeks and adds a set every 2 weeks
    weeks_out = []
    for w in range(weeks):
        week_preds = {}
        for ex, v in preds.items():
            sets = v['sets']
            reps = v['reps']
            intensity = v['intensity']
            # progression rules
            add_sets = (w // 2)  # add 1 set every 2 weeks
            add_int = (w // 2)   # add intensity step every 2 weeks
            week_preds[ex] = {
                'sets': max(1, sets + add_sets),
                'reps': reps,  # keep reps stable for simplicity
                'intensity': min(10, intensity + add_int)
            }
        weeks_out.append(week_preds)
    return weeks_out


def load_exercises_db(path=None):
    if path is None:
        project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
        path = os.path.join(project_root, 'data', 'exercises.json')
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def substitute_exercises(preds, available_equipment, injuries=None, exercises_path=None):
    """Return preds with substitutions for unavailable equipment or injuries.

    preds: {Exercise: {sets,reps,intensity,...}}
    available_equipment: set or 'gym' to allow all
    injuries: list of body parts to avoid (strings)
    """
    if injuries is None:
        injuries = []
    injuries = [i.strip().lower() for i in injuries if i]

    db = load_exercises_db(exercises_path)

    # simple muscle mapping for our canonical exercises
    muscle_map = {
        'Bench': 'chest', 'OverheadPress': 'shoulders', 'Row': 'back',
        'Squat': 'legs', 'Deadlift': 'posterior_chain'
    }

    # Normalize available_equipment into a set of keywords or 'gym' flag
    if isinstance(available_equipment, str):
        eq = available_equipment.lower()
        if eq == 'gym':
            allowed_all = True
            allowed = set()
        elif eq == 'home':
            # Home workouts can include body weight, dumbbells, and resistance bands
            allowed_all = False
            allowed = {'dumbbell', 'body weight', 'band', 'resistance band', 'kettlebell', 'exercise ball'}
        elif eq == 'body weight':
            # Pure body weight workouts only
            allowed_all = False
            allowed = {'body weight'}
        elif eq == 'dumbbells':
            allowed_all = False
            allowed = {'dumbbell', 'body weight', 'band', 'kettlebell'}
        elif eq == 'park':
            # Park/outdoor workouts are typically body weight only
            allowed_all = False
            allowed = {'body weight'}
        else:
            allowed_all = False
            allowed = {'body weight'}
    else:
        allowed_all = False
        allowed = set(available_equipment)

    new_preds = {}
    for ex, v in preds.items():
        mg = muscle_map.get(ex, None)
        # determine if ex is contraindicated by injury via body part match
        contraindicated = False
        # We will look for an exact name match in db to determine bodyParts/equipment
        found_exact = None
        for item in db:
            # basic name match: check if ex name in item name (case-insensitive)
            if ex.lower() in item.get('name','').lower():
                found_exact = item
                break
        if found_exact:
            bodyparts = [b.lower() for b in found_exact.get('bodyParts',[])]
            if any(b in injuries for b in bodyparts):
                contraindicated = True
            # check equipment availability
            item_eqs = [e.lower() for e in found_exact.get('equipments',[])]
            if not allowed_all and not any(e in allowed for e in item_eqs):
                unavailable = True
            else:
                unavailable = False
        else:
            # unknown exact exercise - if it contains equipment keywords, check if allowed
            contraindicated = False
            unavailable = False
            
            # Check if exercise name contains equipment keywords that aren't allowed
            ex_lower = ex.lower()
            if 'dumbbell' in ex_lower and 'dumbbell' not in allowed and not allowed_all:
                unavailable = True
            elif 'barbell' in ex_lower and 'barbell' not in allowed and not allowed_all:
                unavailable = True
            elif 'cable' in ex_lower and 'cable' not in allowed and not allowed_all:
                unavailable = True
            elif 'machine' in ex_lower and 'machine' not in allowed and not allowed_all:
                unavailable = True
            elif 'kettlebell' in ex_lower and 'kettlebell' not in allowed and not allowed_all:
                unavailable = True

        if contraindicated or unavailable:
            # Try to find a substitute that targets the same muscle or bodypart and is allowed
            substitute = None
            
            # First, try to find body weight alternatives for common muscle groups
            ex_lower = ex.lower()
            if 'biceps' in ex_lower or 'curl' in ex_lower:
                # Look for body weight bicep exercises
                for item in db:
                    item_eqs = [e.lower() for e in item.get('equipments',[])]
                    if 'body weight' in item_eqs and any(word in item.get('name','').lower() for word in ['pull', 'chin']):
                        substitute = item
                        break
            elif 'triceps' in ex_lower or 'press' in ex_lower:
                # Look for body weight tricep exercises
                for item in db:
                    item_eqs = [e.lower() for e in item.get('equipments',[])]
                    if 'body weight' in item_eqs and any(word in item.get('name','').lower() for word in ['push', 'dip']):
                        substitute = item
                        break
            elif 'chest' in ex_lower or 'push' in ex_lower:
                # Look for body weight chest exercises
                for item in db:
                    item_eqs = [e.lower() for e in item.get('equipments',[])]
                    if 'body weight' in item_eqs and 'push' in item.get('name','').lower():
                        substitute = item
                        break
            
            # If no specific substitute found, try general matching
            if not substitute:
                for item in db:
                    item_body = [b.lower() for b in item.get('bodyParts',[])]
                    item_target = [t.lower() for t in item.get('targetMuscles',[])]
                    # match by muscle group or body part
                    match_muscle = False
                    if mg and (mg in item_body or mg in item_target):
                        match_muscle = True
                    # skip exercises that hit injured body parts
                    if any(b in injuries for b in item_body):
                        continue
                    item_eqs = [e.lower() for e in item.get('equipments',[])]
                    if not allowed_all and not any(e in allowed for e in item_eqs):
                        continue
                    if match_muscle:
                        substitute = item
                        break

            if substitute:
                name = substitute.get('name')
                new_preds[name] = v.copy()
            else:
                # No substitute found - skip this exercise entirely for bodyweight-only workouts
                if allowed == {'body weight'}:
                    continue  # Skip dumbbell exercises when only body weight is allowed
                else:
                    # For other equipment restrictions, reduce volume/intensity as fallback
                    v2 = v.copy()
                    v2['sets'] = max(1, int(round(v2['sets'] * 0.7)))
                    v2['intensity'] = max(1, int(round(v2['intensity'] * 0.7)))
                    new_preds[ex] = v2
        else:
            new_preds[ex] = v

    return new_preds
