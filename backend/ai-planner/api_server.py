"""
AI Fitness Planner API Server

A comprehensive fitness planning API that uses machine learning and expert rules 
to generate personalized workout plans from natural language input.

Features:
- Natural language input parsing
- ML-based exercise parameter prediction 
- Expert rules for safety and progression
- 1,500+ exercise database
- Multi-week progressive planning
- Equipment and injury accommodation

Author: AI Fitness Team
Version: 1.0.0
"""

import sys
import os
from pathlib import Path
from typing import Optional

# FastAPI and server components
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Add project root to path for imports
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

# Import our modules
from model.nl_parser import parse_natural_language_input
from model.predict_sets import predict as predict_sets
from model.expert_rules import substitute_exercises, refine_predictions
from model.llm_planner import call_llm_for_plan

# Initialize FastAPI app
app = FastAPI(
    title="AI Fitness Planner",
    description="Intelligent workout planning through natural language processing and ML",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware for web app integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class FitnessRequest(BaseModel):
    message: str
    weeks: Optional[int] = 4
    use_natural_language: Optional[bool] = True


class FitnessResponse(BaseModel):
    plan: str
    profile: dict
    source: str
    structured_data: Optional[list] = None


@app.get("/")
async def root():
    return {"message": "AI Fitness Planner API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "ml_model": "available", "llm": "available"}


@app.post("/plan", response_model=FitnessResponse)
async def create_fitness_plan(request: FitnessRequest):
    """
    Main endpoint for creating personalized fitness plans from natural language input.
    
    Example request:
    {
        "message": "I'm a 28 year old male looking to build muscle. I can work out 4 days a week at the gym.",
        "weeks": 4,
        "use_natural_language": true
    }
    """
    try:
        # Step 1: Parse natural language input
        profile = parse_natural_language_input(request.message)
        
        # Step 2: Get ML model predictions
        raw_preds = predict_sets(profile)
        
        # Step 3: Transform predictions to expert rules format
        preds = {}
        for muscle_group, exercises in raw_preds.items():
            for exercise_data in exercises:
                exercise_name = exercise_data['exercise']
                params = exercise_data['parameters']
                preds[exercise_name] = {
                    'sets': params['sets'],
                    'reps': params['reps'], 
                    'intensity': params['intensity']
                }
        
        # Step 4: Apply expert rules and substitutions
        equipment = profile.get('Equipment', 'Gym')
        injuries = profile.get('Injuries', [])
        preds = substitute_exercises(preds, equipment, injuries)
        preds = refine_predictions(preds, profile)
        
        # Step 5: Generate plan with LLM or fallback
        result = call_llm_for_plan(profile, preds, weeks=request.weeks, natural_language=request.use_natural_language)
        
        # Step 6: Format response
        if request.use_natural_language and 'explanation' in result:
            plan_text = result['explanation']
        else:
            # Format structured data as readable text
            plan_text = _format_structured_plan(result['weeks'], profile, request.weeks)
        
        return FitnessResponse(
            plan=plan_text,
            profile=profile,
            source=result.get('source', 'unknown'),
            structured_data=result['weeks'] if not request.use_natural_language else None
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating plan: {str(e)}")


@app.post("/parse")
async def parse_message(request: dict):
    """
    Parse natural language input into structured profile data.
    
    Example: {"message": "25 year old female, wants to lose weight, 3 days per week"}
    """
    try:
        message = request.get('message', '')
        if not message:
            raise HTTPException(status_code=400, detail="Message is required")
        
        profile = parse_natural_language_input(message)
        return {"profile": profile}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error parsing message: {str(e)}")


def _format_structured_plan(weeks_data, profile, num_weeks):
    """Format structured workout data as readable text."""
    age = profile.get('Age', 30)
    gender = profile.get('Gender', 'person')
    goal = profile.get('Goal', 'fitness')
    days = profile.get('Days_per_Week', 4)
    
    plan = f"Personalized {num_weeks}-week workout plan for {age}-year-old {gender.lower()}\n"
    plan += f"Goal: {goal} | Training Days: {days} per week\n\n"
    
    for week_num, week_data in enumerate(weeks_data[:num_weeks], 1):
        plan += f"Week {week_num}:\n"
        for day, exercises in week_data.items():
            if exercises:
                plan += f"  Day {day}: "
                exercise_list = []
                for ex_name, params in exercises:
                    sets = params.get('sets', 3)
                    reps = params.get('reps', 10)
                    exercise_list.append(f"{ex_name} ({sets}x{reps})")
                plan += ", ".join(exercise_list) + "\n"
            else:
                plan += f"  Day {day}: Rest\n"
        plan += "\n"
    
    return plan


if __name__ == "__main__":
    print("Starting AI Fitness Planner server...")
    print("API docs available at: http://localhost:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8000)
