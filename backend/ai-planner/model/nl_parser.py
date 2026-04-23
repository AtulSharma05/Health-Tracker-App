"""
Natural Language Parser Module

Parses natural language fitness requests into structured profile data.
Works without API keys using smart keyword extraction.

PRODUCTION MODULE - Natural language processing
"""

import re
from typing import Dict


def parse_natural_language_input(user_message: str) -> Dict:
    """
    Parse natural language fitness goals into structured profile data.
    Works without API key using smart keyword extraction.
    
    Args:
        user_message: Natural language input like "28 year old male, muscle gain, gym access, 4 days per week"
    
    Returns:
        Structured profile dict with Age, Gender, Goal, etc.
    """
    
    message_lower = user_message.lower()
    
    # Default profile
    profile = {
        'Age': 30,
        'Gender': 'Male',
        'Goal': 'Muscle Gain',
        'Fitness_Level': 'Intermediate',
        'Days_per_Week': 4,
        'Duration': 60,  # Default 60 minutes per workout
        'Equipment': 'Gym',
        'Body_Type': 'Mesomorph',
        'Injuries': []
    }
    
    # Extract age
    age_match = re.search(r'(\d+)\s*year', message_lower)
    if age_match:
        age = int(age_match.group(1))
        if 16 <= age <= 80:
            profile['Age'] = age
    
    # Extract gender
    if any(word in message_lower for word in ['female', 'woman', 'girl', 'she', 'her']):
        profile['Gender'] = 'Female'
    elif any(word in message_lower for word in ['male', 'man', 'boy', 'he', 'him']):
        profile['Gender'] = 'Male'
    
    # Extract goal
    if any(word in message_lower for word in ['weight loss', 'lose weight', 'fat loss', 'cutting']):
        profile['Goal'] = 'Weight Loss'
    elif any(word in message_lower for word in ['muscle', 'build', 'gain', 'bulk', 'mass']):
        profile['Goal'] = 'Muscle Gain'
    elif any(word in message_lower for word in ['strength', 'strong', 'powerlifting', 'lifting']):
        profile['Goal'] = 'Strength'
    elif any(word in message_lower for word in ['endurance', 'cardio', 'running', 'marathon']):
        profile['Goal'] = 'Endurance'
    elif any(word in message_lower for word in ['tone', 'toning', 'lean', 'definition']):
        profile['Goal'] = 'Toning'
    
    # Extract days per week
    days_match = re.search(r'(\d+)\s*day', message_lower)
    if days_match:
        days = int(days_match.group(1))
        if 1 <= days <= 7:  # Allow 1-7 days per week
            profile['Days_per_Week'] = days
    
    # Extract workout duration (in minutes)
    duration_match = re.search(r'(\d+)\s*(?:min|minute)', message_lower)
    if duration_match:
        duration = int(duration_match.group(1))
        if 20 <= duration <= 180:  # 20 minutes to 3 hours
            profile['Duration'] = duration
    
    # Extract equipment/location
    if any(word in message_lower for word in ['bodyweight', 'body weight', 'no equipment', 'equipment free']):
        profile['Equipment'] = 'Body Weight'
    elif any(word in message_lower for word in ['home', 'house', 'apartment']):
        profile['Equipment'] = 'Home'
    elif any(word in message_lower for word in ['gym', 'fitness center', 'health club']):
        profile['Equipment'] = 'Gym'
    elif any(word in message_lower for word in ['park', 'outdoor', 'outside']):
        profile['Equipment'] = 'Park'
    
    # Extract experience level
    if any(word in message_lower for word in ['beginner', 'new', 'start', 'never', 'first time']):
        profile['Fitness_Level'] = 'Beginner'
    elif any(word in message_lower for word in ['advanced', 'expert', 'experienced', 'competitive']):
        profile['Fitness_Level'] = 'Advanced'
    else:
        profile['Fitness_Level'] = 'Intermediate'
    
    # Extract injuries
    injury_words = ['knee', 'back', 'shoulder', 'ankle', 'wrist', 'injury', 'hurt', 'pain', 'problem']
    injuries = []
    for word in injury_words:
        if word in message_lower:
            injuries.append(word)
    profile['Injuries'] = list(set(injuries))  # Remove duplicates
    
    print(f"Parsed profile from '{user_message}': {profile}")
    return profile


if __name__ == "__main__":
    # Test cases
    test_cases = [
        "28 year old male, muscle gain, gym access, 4 days per week",
        "25 year old female, weight loss, home workouts, 3 days",
        "35 year old advanced male, strength training, 5 days gym",
        "beginner woman, toning, home equipment, knee injury"
    ]
    
    for test in test_cases:
        print(f"\nTest: {test}")
        result = parse_natural_language_input(test)
        print(f"Result: {result}")
