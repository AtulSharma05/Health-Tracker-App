#!/usr/bin/env python3
"""
Comprehensive Workout Prediction Module

This module provides ML-based predictions for workout parameters using
the comprehensive exercise database with thousands of exercises.

PRODUCTION MODULE - Core ML prediction functionality
"""

import joblib
import pandas as pd
import json
from pathlib import Path
import numpy as np

class ComprehensiveFitnessPredictor:
    """Enhanced fitness predictor using comprehensive exercise database."""
    
    def __init__(self):
        """Initialize the predictor by loading model artifacts."""
        self.model_dir = Path(__file__).parent
        self.data_dir = self.model_dir.parent / "data"
        
        # Load model and metadata
        self._load_model_artifacts()
        self._load_exercise_database()
    
    def _load_model_artifacts(self):
        """Load all model-related files."""
        try:
            # Try loading comprehensive model first
            model_file = self.model_dir / "comprehensive_model.pkl"
            if model_file.exists():
                self.model = joblib.load(model_file)
                
                # Load metadata
                with open(self.model_dir / "model_info.json", 'r') as f:
                    self.model_info = json.load(f)
                
                self.feature_columns = self.model_info['feature_columns']
                self.target_columns = self.model_info['target_columns']
                print("Loaded comprehensive model successfully")
                
            else:
                # Fallback to old model if comprehensive model doesn't exist
                print("Comprehensive model not found, falling back to old model...")
                self.model = joblib.load(self.model_dir / "sets_model.pkl")
                self.feature_columns = joblib.load(self.model_dir / "feature_cols.pkl")
                self.target_columns = joblib.load(self.model_dir / "target_cols.pkl")
                self.model_info = {
                    'categorical_features': ['gender', 'goal', 'experience', 'location', 'body_type'],
                    'numerical_features': ['age', 'training_days']
                }
                
        except Exception as e:
            print(f"Error loading model: {e}")
            raise
    
    def _load_exercise_database(self):
        """Load the exercise database."""
        try:
            with open(self.data_dir / "exercises.json", 'r') as f:
                self.exercises = json.load(f)
            
            # Create lookup dictionaries
            self.exercises_by_name = {ex['name']: ex for ex in self.exercises}
            self.exercises_by_muscle = {}
            
            # Group exercises by target muscle
            for exercise in self.exercises:
                for muscle in exercise.get('targetMuscles', []):
                    if muscle not in self.exercises_by_muscle:
                        self.exercises_by_muscle[muscle] = []
                    self.exercises_by_muscle[muscle].append(exercise)
            
            print(f"Loaded {len(self.exercises)} exercises from database")
            
        except Exception as e:
            print(f"Error loading exercise database: {e}")
            # Create fallback exercise list
            self.exercises = []
            self.exercises_by_name = {}
            self.exercises_by_muscle = {}
    
    def get_exercise_recommendations(self, user_profile, muscle_groups, available_equipment=None):
        """Get exercise recommendations based on user profile and muscle groups."""
        
        if available_equipment is None:
            # Default equipment based on location
            equipment_map = {
                'Home': ['body weight', 'dumbbell', 'resistance band'],
                'Gym': ['barbell', 'dumbbell', 'machine', 'cable', 'kettlebell'],
                'Park': ['body weight', 'resistance band']
            }
            available_equipment = equipment_map.get(user_profile.get('location', 'Gym'), 
                                                  ['body weight', 'dumbbell'])
        
        # Map muscle groups to exercise database muscles
        muscle_map = {
            'chest': ['chest', 'pectorals', 'upper chest', 'lower chest'],
            'back': ['latissimus dorsi', 'rhomboids', 'middle trapezius', 'lower trapezius'],
            'shoulders': ['deltoids', 'anterior deltoids', 'lateral deltoids', 'posterior deltoids'],
            'biceps': ['biceps', 'brachialis', 'brachioradialis'],
            'triceps': ['triceps'],
            'legs': ['quadriceps', 'hamstrings', 'glutes', 'calves'],
            'core': ['abdominals', 'obliques', 'lower abs', 'core'],
            'forearms': ['forearm flexors', 'forearm extensors', 'grip muscles']
        }
        
        recommendations = {}
        
        for muscle_group in muscle_groups:
            target_muscles = muscle_map.get(muscle_group, [muscle_group])
            suitable_exercises = []
            
            # Find exercises for this muscle group
            for muscle in target_muscles:
                if muscle in self.exercises_by_muscle:
                    for exercise in self.exercises_by_muscle[muscle]:
                        # Check if exercise uses available equipment
                        exercise_equipment = exercise.get('equipments', ['body weight'])
                        if any(eq in available_equipment for eq in exercise_equipment):
                            suitable_exercises.append(exercise)
            
            # Remove duplicates
            seen_names = set()
            unique_exercises = []
            for ex in suitable_exercises:
                if ex['name'] not in seen_names:
                    unique_exercises.append(ex)
                    seen_names.add(ex['name'])
            
            recommendations[muscle_group] = unique_exercises[:10]  # Limit to top 10
        
        return recommendations
    
    def predict_exercise_parameters(self, user_profile, exercise_name, muscle_group=None):
        """Predict sets, reps, intensity, weight, RPE for a specific exercise."""
        
        # Get exercise info
        exercise = self.exercises_by_name.get(exercise_name)
        if not exercise:
            print(f"Exercise '{exercise_name}' not found in database")
            return self._get_default_parameters(user_profile)
        
        # Prepare input features
        features = {
            'age': user_profile.get('age', 30),
            'gender': user_profile.get('gender', 'Male'),
            'goal': user_profile.get('goal', 'Muscle Gain'),
            'experience': user_profile.get('experience', 'Intermediate'),
            'training_days': user_profile.get('training_days', 4),
            'location': user_profile.get('location', 'Gym'),
            'body_type': user_profile.get('body_type', 'Mesomorph')
        }
        
        # Add exercise-specific features if using comprehensive model
        if 'muscle_group' in self.feature_columns:
            features['muscle_group'] = muscle_group or 'chest'
            features['equipment'] = exercise.get('equipments', ['body weight'])[0]
            features['bodypart'] = exercise.get('bodyParts', ['chest'])[0]
        
        # Create DataFrame with correct column order
        input_df = pd.DataFrame([features])
        
        # Make prediction
        try:
            prediction = self.model.predict(input_df)[0]
            
            # Map prediction to named results
            result = {}
            for i, target in enumerate(self.target_columns):
                value = prediction[i]
                
                # Round appropriately
                if target in ['sets', 'reps']:
                    result[target] = max(1, int(round(value)))
                elif target == 'intensity':
                    result[target] = max(50, min(100, int(round(value))))
                elif target == 'weight':
                    result[target] = max(0, round(value, 1))
                elif target == 'rpe':
                    result[target] = max(5, min(10, round(value, 1)))
                else:
                    result[target] = round(value, 2)
            
            return result
            
        except Exception as e:
            print(f"Error making prediction: {e}")
            return self._get_default_parameters(user_profile)
    
    def _get_default_parameters(self, user_profile):
        """Get default parameters when prediction fails."""
        goal = user_profile.get('goal', 'Muscle Gain')
        experience = user_profile.get('experience', 'Intermediate')
        
        defaults = {
            'Muscle Gain': {'sets': 3, 'reps': 10, 'intensity': 75, 'weight': 5.0, 'rpe': 7.5},
            'Strength': {'sets': 4, 'reps': 5, 'intensity': 85, 'weight': 7.0, 'rpe': 8.5},
            'Endurance': {'sets': 3, 'reps': 15, 'intensity': 65, 'weight': 3.0, 'rpe': 6.5},
            'Weight Loss': {'sets': 3, 'reps': 12, 'intensity': 70, 'weight': 4.0, 'rpe': 7.0},
            'Toning': {'sets': 3, 'reps': 12, 'intensity': 65, 'weight': 3.5, 'rpe': 6.5}
        }
        
        base_params = defaults.get(goal, defaults['Muscle Gain'])
        
        # Adjust for experience
        if experience == 'Beginner':
            base_params = base_params.copy()
            base_params['sets'] = max(2, base_params['sets'] - 1)
            base_params['intensity'] *= 0.9
            base_params['weight'] *= 0.7
        elif experience == 'Advanced':
            base_params = base_params.copy()
            base_params['sets'] += 1
            base_params['intensity'] = min(95, base_params['intensity'] * 1.1)
            base_params['weight'] *= 1.3
        
        return base_params

def predict(user_profile, target_exercises=None):
    """Main prediction function for backward compatibility."""
    predictor = ComprehensiveFitnessPredictor()
    
    # Handle both old and new profile formats
    def get_profile_value(profile, new_key, old_key, default):
        return profile.get(new_key) or profile.get(old_key, default)
    
    # Normalize profile format
    normalized_profile = {
        'age': get_profile_value(user_profile, 'age', 'Age', 30),
        'gender': get_profile_value(user_profile, 'gender', 'Gender', 'Male'),
        'goal': get_profile_value(user_profile, 'goal', 'Goal', 'Muscle Gain'),
        'experience': get_profile_value(user_profile, 'experience', 'Fitness_Level', 'Intermediate'),
        'training_days': get_profile_value(user_profile, 'training_days', 'Days_per_Week', 4),
        'duration': get_profile_value(user_profile, 'duration', 'Duration', 60),  # Workout duration in minutes
        'location': get_profile_value(user_profile, 'location', 'Equipment', 'Gym'),
        'body_type': get_profile_value(user_profile, 'body_type', 'Body_Type', 'Mesomorph')
    }
    
    # Get muscle groups from exercises or use defaults
    if target_exercises:
        muscle_groups = []
        for exercise_name in target_exercises:
            exercise = predictor.exercises_by_name.get(exercise_name)
            if exercise:
                target_muscles = exercise.get('targetMuscles', [])
                # Map to main muscle groups
                for muscle in target_muscles:
                    if muscle in ['chest', 'pectorals']:
                        muscle_groups.append('chest')
                    elif muscle in ['latissimus dorsi', 'rhomboids', 'trapezius']:
                        muscle_groups.append('back')
                    elif muscle in ['deltoids']:
                        muscle_groups.append('shoulders')
                    elif muscle in ['biceps']:
                        muscle_groups.append('biceps')
                    elif muscle in ['triceps']:
                        muscle_groups.append('triceps')
                    elif muscle in ['quadriceps', 'hamstrings', 'glutes']:
                        muscle_groups.append('legs')
                    elif muscle in ['abdominals', 'obliques']:
                        muscle_groups.append('core')
        
        muscle_groups = list(set(muscle_groups))  # Remove duplicates
    else:
        # Default workout split
        muscle_groups = ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'legs', 'core']
    
    # Get exercise recommendations
    recommendations = predictor.get_exercise_recommendations(normalized_profile, muscle_groups)
    
    # Get predictions for each recommended exercise
    results = {}
    for muscle_group, exercises in recommendations.items():
        results[muscle_group] = []
        
        # Adjust number of exercises based on training days AND duration
        duration = normalized_profile.get('duration', 60)  # Default 60 minutes
        
        # Base count from training days
        if normalized_profile['training_days'] >= 7:
            base_exercises = 5
        elif normalized_profile['training_days'] >= 5:
            base_exercises = 4
        else:
            base_exercises = 3
        
        # Scale by duration (30min=0.5x, 60min=1x, 90min=1.5x, 120min=2x)
        duration_multiplier = duration / 60.0
        num_exercises = round(base_exercises * duration_multiplier)  # Use round instead of int
        num_exercises = min(num_exercises, len(exercises))  # Don't exceed available exercises
        num_exercises = max(2, num_exercises)  # At least 2 exercises per muscle group
        
        for exercise in exercises[:num_exercises]:  # Scale with training days and duration
            try:
                params = predictor.predict_exercise_parameters(
                    normalized_profile, exercise['name'], muscle_group
                )
                
                exercise_result = {
                    'exercise': exercise['name'],
                    'muscle_group': muscle_group,
                    'equipment': exercise.get('equipments', [''])[0],
                    'target_muscles': exercise.get('targetMuscles', []),
                    'parameters': params
                }
                
                results[muscle_group].append(exercise_result)
            except Exception as e:
                print(f"Error predicting for {exercise['name']}: {e}")
                continue
    
    return results

# For testing
if __name__ == "__main__":
    # Test the updated predictor
    test_profile = {
        'age': 28,
        'gender': 'Male',
        'goal': 'Muscle Gain',
        'experience': 'Intermediate',
        'training_days': 4,
        'location': 'Gym',
        'body_type': 'Mesomorph'
    }
    
    print("Testing comprehensive predictor...")
    results = predict(test_profile)
    
    for muscle_group, exercises in results.items():
        print(f"\n{muscle_group.upper()}:")
        for exercise in exercises:
            params = exercise['parameters']
            print(f"  {exercise['exercise']}: {params['sets']} sets x {params['reps']} reps "
                  f"@ {params['intensity']}% intensity (Weight: {params['weight']}, RPE: {params['rpe']})")
