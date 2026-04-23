"""
LLM Planner Module (Simplified)

Generates workout plans using expert rules without requiring API keys.

PRODUCTION MODULE - Workout plan generation
"""

from model.expert_rules import generate_multiweek, schedule_exercises


def call_llm_for_plan(profile, predictions, weeks=4, natural_language=False):
    """
    Generate workout plan using expert rules (no API key required).
    
    Args:
        profile: User profile dict
        predictions: ML predictions from predict_sets
        weeks: Number of weeks to plan
        natural_language: Whether to format as natural language
    
    Returns:
        Dict with formatted workout plan
    """
    
    print("Generating plan using expert rules (no API key required)...")
    
    # First create a schedule for the base week
    days = profile.get('Days_per_Week', 4)
    base_schedule = schedule_exercises(predictions, days)
    
    # Generate multi-week progression using expert rules
    schedule_weeks = []
    for week in range(weeks):
        week_preds = {}
        for ex, v in predictions.items():
            sets = v['sets']
            reps = v['reps']
            intensity = v['intensity']
            # progression rules
            add_sets = (week // 2)  # add 1 set every 2 weeks
            add_int = (week // 2)   # add intensity step every 2 weeks
            week_preds[ex] = {
                'sets': max(1, sets + add_sets),
                'reps': reps,  # keep reps stable for simplicity
                'intensity': min(10, intensity + add_int)
            }
        
        # Create weekly schedule with progressed parameters
        week_schedule = {}
        for day, exercises in base_schedule.items():
            week_schedule[day] = []
            for ex_name, _ in exercises:
                if ex_name in week_preds:
                    week_schedule[day].append((ex_name, week_preds[ex_name]))
        
        schedule_weeks.append(week_schedule)
    
    if natural_language:
        # Format as natural language explanation
        explanation = _format_plan_as_natural_language(schedule_weeks, profile, weeks)
        return {
            'source': 'expert_rules',
            'explanation': explanation,
            'weeks': schedule_weeks
        }
    else:
        # Return structured data
        return {
            'source': 'expert_rules', 
            'weeks': schedule_weeks
        }


def _format_plan_as_natural_language(schedule_weeks, profile, weeks):
    """Format a structured workout plan as natural language explanation."""
    age = profile.get('Age', 30)
    goal = profile.get('Goal', 'fitness')
    days = profile.get('Days_per_Week', 4)
    gender = profile.get('Gender', 'person')
    experience = profile.get('Fitness_Level', 'intermediate')
    
    intro = f"Here's your {weeks}-week workout plan! As a {age}-year-old {gender.lower()} focused on {goal.lower()}, training {days} days per week at {experience.lower()} level:\n\n"
    
    explanation = intro
    
    # Add weekly breakdown
    for week_num in range(1, weeks + 1):
        if week_num <= len(schedule_weeks):
            schedule = schedule_weeks[week_num - 1]
            explanation += f"**Week {week_num}:**\n"
            
            # Show all 7 days of the week
            for day in range(1, 8):
                if day in schedule and schedule[day]:
                    explanation += f"Day {day}: "
                    exercises = []
                    for ex_name, ex_data in schedule[day]:
                        sets = ex_data.get('sets', 3)
                        reps = ex_data.get('reps', 10)
                        exercises.append(f"{ex_name} ({sets} sets x {reps} reps)")
                    explanation += ", ".join(exercises) + "\n"
                else:
                    explanation += f"Day {day}: Rest\n"
            explanation += "\n"
    
    # Add tips based on goal
    tips = {
        'Muscle Gain': "💪 Tips: Focus on progressive overload, eat adequate protein, and get enough rest between sessions.",
        'Weight Loss': "🔥 Tips: Maintain consistency, combine with cardio, and focus on compound movements for maximum calorie burn.",
        'Strength': "🏋️ Tips: Prioritize proper form, allow adequate recovery, and gradually increase weights.",
        'Endurance': "🏃 Tips: Build gradually, include variety in your training, and focus on consistency over intensity.",
        'Toning': "✨ Tips: Combine resistance training with light cardio, focus on higher reps, and maintain regular training."
    }
    
    explanation += tips.get(goal, "💡 Tips: Stay consistent, listen to your body, and adjust as needed.")
    explanation += "\n\nRemember to warm up before each session and cool down afterward. Good luck with your fitness journey! 🎯"
    
    return explanation


if __name__ == "__main__":
    # Test the simplified planner
    test_profile = {
        'Age': 28,
        'Gender': 'Male',
        'Goal': 'Muscle Gain',
        'Fitness_Level': 'Intermediate',
        'Days_per_Week': 4,
        'Equipment': 'Gym'
    }
    
    # Mock predictions for testing
    test_predictions = {
        'chest': [
            {'exercise': 'Bench Press', 'parameters': {'sets': 4, 'reps': 8}},
            {'exercise': 'Incline Dumbbell Press', 'parameters': {'sets': 3, 'reps': 10}}
        ],
        'back': [
            {'exercise': 'Pull-ups', 'parameters': {'sets': 4, 'reps': 8}},
            {'exercise': 'Barbell Rows', 'parameters': {'sets': 3, 'reps': 10}}
        ]
    }
    
    result = call_llm_for_plan(test_profile, test_predictions, weeks=2, natural_language=True)
    print(result['explanation'])
