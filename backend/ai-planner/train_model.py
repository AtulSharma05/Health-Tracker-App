#!/usr/bin/env python3
"""
Model Training Script - Regenerates the AI Fitness Planner Model

This script trains the comprehensive fitness model from the workout data.
The resulting model file (comprehensive_model.pkl) is 219MB and excluded 
from GitHub due to size limits.

Usage:
    python train_model.py

Requirements:
    - pandas
    - scikit-learn
    - numpy

Output:
    - model/comprehensive_model.pkl (219MB)
    - model/model_info.json (feature specifications)
"""

import pandas as pd
import numpy as np
import json
import joblib
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.metrics import mean_squared_error, r2_score
import os

def train_comprehensive_model():
    """Train the comprehensive fitness model."""
    
    print("🤖 Training AI Fitness Planner Model...")
    print("=" * 50)
    
    # Load data
    print("📊 Loading training data...")
    data = pd.read_csv('data/workout_comprehensive.csv')
    print(f"   Dataset size: {len(data):,} records")
    
    # Define features and targets
    feature_columns = [
        'age', 'gender', 'goal', 'experience', 'training_days',
        'location', 'body_type', 'muscle_group', 'equipment', 'bodypart'
    ]
    target_columns = ['sets', 'reps', 'intensity', 'weight', 'rpe']
    
    # Prepare data
    X = data[feature_columns]
    y = data[target_columns]
    
    # Identify categorical and numerical features
    categorical_features = ['gender', 'goal', 'experience', 'location', 
                          'body_type', 'muscle_group', 'equipment', 'bodypart']
    numerical_features = ['age', 'training_days']
    
    # Create preprocessing pipeline
    preprocessor = ColumnTransformer(
        transformers=[
            ('num', StandardScaler(), numerical_features),
            ('cat', OneHotEncoder(drop='first', sparse_output=False), categorical_features)
        ]
    )
    
    # Create full pipeline with Random Forest
    model = Pipeline([
        ('preprocessor', preprocessor),
        ('regressor', RandomForestRegressor(
            n_estimators=100,
            max_depth=15,
            min_samples_split=10,
            random_state=42,
            n_jobs=-1
        ))
    ])
    
    # Split data
    print("🔄 Splitting data (80% train, 20% test)...")
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    
    print(f"   Training samples: {len(X_train):,}")
    print(f"   Test samples: {len(X_test):,}")
    
    # Train model
    print("🧠 Training Random Forest model...")
    print("   This may take several minutes...")
    model.fit(X_train, y_train)
    
    # Evaluate model
    print("📈 Evaluating model performance...")
    y_pred = model.predict(X_test)
    
    # Calculate R² scores for each target
    r2_scores = {}
    for i, target in enumerate(target_columns):
        r2 = r2_score(y_test.iloc[:, i], y_pred[:, i])
        r2_scores[target] = r2
        print(f"   {target.upper()}: R² = {r2:.4f} ({r2*100:.1f}%)")
    
    avg_r2 = np.mean(list(r2_scores.values()))
    print(f"   AVERAGE R²: {avg_r2:.4f} ({avg_r2*100:.1f}%)")
    
    # Save model
    print("💾 Saving model...")
    os.makedirs('model', exist_ok=True)
    joblib.dump(model, 'model/comprehensive_model.pkl')
    
    # Save model info
    model_info = {
        'feature_columns': feature_columns,
        'target_columns': target_columns,
        'categorical_features': categorical_features,
        'numerical_features': numerical_features,
        'r2_scores': r2_scores,
        'average_r2': avg_r2,
        'training_samples': len(X_train),
        'test_samples': len(X_test)
    }
    
    with open('model/model_info.json', 'w') as f:
        json.dump(model_info, f, indent=2)
    
    # Check model size
    model_size = os.path.getsize('model/comprehensive_model.pkl') / (1024 * 1024)
    print(f"   Model saved: comprehensive_model.pkl ({model_size:.1f} MB)")
    print(f"   Info saved: model_info.json")
    
    print("\n✅ Model training completed successfully!")
    print(f"🎯 Average performance: {avg_r2*100:.1f}% accuracy")
    print("🚀 Ready for predictions!")

if __name__ == "__main__":
    train_comprehensive_model()
