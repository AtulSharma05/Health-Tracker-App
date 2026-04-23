#!/usr/bin/env python3
"""
Pose Corrector REST API with WebSocket Support
FastAPI wrapper for real-time pose analysis
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import cv2
import numpy as np
import base64
import json
import asyncio
from typing import Optional, Dict, Any
import uvicorn

# Import the pose corrector
from professional_pose_corrector import ProfessionalPoseCorrector

app = FastAPI(
    title="Pose Corrector API",
    description="Real-time exercise form analysis and rep counting",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global pose corrector instance (one per session in production)
pose_corrector = ProfessionalPoseCorrector()

class ExerciseStartRequest(BaseModel):
    exercise_id: str

class ExerciseResponse(BaseModel):
    status: str
    exercise_id: str
    exercise_name: str
    message: str

@app.get("/")
async def root():
    """API health check"""
    return {
        "status": "active",
        "service": "Pose Corrector API",
        "version": "1.0.0",
        "endpoints": {
            "websocket": "/ws/pose-analysis",
            "start_exercise": "/api/start-exercise",
            "session_summary": "/api/session-summary",
            "reset": "/api/reset"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "pose_corrector_api",
        "mediapipe": "loaded",
        "model": "ready"
    }

@app.post("/api/start-exercise", response_model=ExerciseResponse)
async def start_exercise(request: ExerciseStartRequest):
    """
    Start a new exercise session with specified exercise ID
    """
    try:
        pose_corrector.set_target_exercise(request.exercise_id)
        
        return ExerciseResponse(
            status="started",
            exercise_id=request.exercise_id,
            exercise_name=pose_corrector.current_exercise_name,
            message=f"Exercise session started: {pose_corrector.current_exercise_name}"
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to start exercise: {str(e)}")

@app.post("/api/reset")
async def reset_session():
    """Reset the current exercise session"""
    try:
        pose_corrector.rep_count = 0
        pose_corrector.phase_history.clear()
        pose_corrector.current_phase = "start"
        pose_corrector.session_start_time = None
        
        return {
            "status": "reset",
            "message": "Session reset successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to reset session: {str(e)}")

@app.get("/api/session-summary")
async def get_session_summary():
    """Get current session summary and statistics"""
    try:
        summary = pose_corrector.get_session_summary()
        return {
            "status": "success",
            "data": summary
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get summary: {str(e)}")

def base64_to_frame(base64_str: str) -> np.ndarray:
    """Convert base64 string to OpenCV frame"""
    try:
        # Remove data URL prefix if present
        if ',' in base64_str:
            base64_str = base64_str.split(',')[1]
        
        # Decode base64
        img_bytes = base64.b64decode(base64_str)
        
        # Convert to numpy array
        nparr = np.frombuffer(img_bytes, np.uint8)
        
        # Decode image
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        return frame
    except Exception as e:
        print(f"Error decoding frame: {e}")
        return None

def frame_to_base64(frame: np.ndarray) -> str:
    """Convert OpenCV frame to base64 string"""
    try:
        # Encode frame to JPEG
        _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
        
        # Convert to base64
        base64_str = base64.b64encode(buffer).decode('utf-8')
        
        return f"data:image/jpeg;base64,{base64_str}"
    except Exception as e:
        print(f"Error encoding frame: {e}")
        return ""

@app.websocket("/ws/pose-analysis")
async def websocket_pose_analysis(websocket: WebSocket):
    """
    WebSocket endpoint for real-time pose analysis
    
    Client sends: base64-encoded video frames
    Server responds: JSON with analysis results
    """
    await websocket.accept()
    print("✅ WebSocket client connected")
    
    try:
        while True:
            # Receive frame from client
            data = await websocket.receive_text()
            
            # Parse incoming data
            try:
                message = json.loads(data)
                
                if message.get('type') == 'frame':
                    frame_base64 = message.get('frame')
                    
                    # Convert base64 to frame
                    frame = base64_to_frame(frame_base64)
                    
                    if frame is not None:
                        print(f"📸 Frame received: {frame.shape}, dtype={frame.dtype}")
                        
                        # Save first frame for debugging
                        import os
                        debug_path = "debug_frame.jpg"
                        if not os.path.exists(debug_path):
                            cv2.imwrite(debug_path, frame)
                            print(f"💾 Saved debug frame to {debug_path}")
                        
                        # Process frame
                        processed_frame, analysis = pose_corrector.process_frame(frame)
                        
                        # Check if pose was detected
                        if analysis and hasattr(analysis, 'landmarks_detected'):
                            print(f"🎯 Pose detected: {analysis.landmarks_detected} landmarks")
                        else:
                            print(f"⚠️ No pose detected in frame")
                        
                        # Prepare response in Flutter-expected format
                        response = {
                            "type": "analysis",
                            "data": {
                                "rep_count": pose_corrector.rep_count,
                                "phase": pose_corrector.current_phase,
                                "confidence": analysis.confidence if analysis else 0.0,
                                "feedback": analysis.corrections if analysis else [],
                                "form_analysis": {
                                    "form_score": analysis.form_score if analysis else 0.0,
                                    "session_quality": analysis.session_quality if analysis else 0.0,
                                    "exercise_name": pose_corrector.current_exercise_name,
                                },
                                "fps": 25.0  # Placeholder, calculate actual FPS if needed
                            }
                        }
                        
                        # Send analysis results
                        await websocket.send_json(response)
                        print(f"✅ Sent analysis: Reps={pose_corrector.rep_count}, Phase={pose_corrector.current_phase}")
                    else:
                        print(f"❌ Failed to decode frame from base64")
                        await websocket.send_json({
                            "type": "error",
                            "message": "Failed to decode frame"
                        })
                
                elif message.get('type') == 'set_exercise':
                    exercise_name = message.get('exercise_name')
                    exercise_id = message.get('exercise_id')
                    
                    # Use exercise_name or exercise_id
                    if exercise_id:
                        pose_corrector.set_target_exercise(exercise_id)
                        print(f"📝 Exercise set by ID: {exercise_id}")
                    elif exercise_name:
                        # Set exercise by name - create ID from name and set both
                        exercise_id_generated = exercise_name.lower().replace(' ', '_') + '_001'
                        pose_corrector.current_exercise_name = exercise_name.lower()
                        pose_corrector.current_exercise_id = exercise_id_generated
                        print(f"📝 Exercise set by name: {exercise_name} (ID: {exercise_id_generated})")
                    
                    await websocket.send_json({
                        "type": "exercise_set",
                        "exercise_id": pose_corrector.current_exercise_id,
                        "exercise_name": pose_corrector.current_exercise_name
                    })
                
                elif message.get('type') == 'reset':
                    pose_corrector.rep_count = 0
                    pose_corrector.phase_history.clear()
                    pose_corrector.current_phase = "start"
                    
                    await websocket.send_json({
                        "type": "reset",
                        "message": "Session reset"
                    })
                
                elif message.get('type') == 'get_summary':
                    summary = pose_corrector.get_session_summary()
                    
                    await websocket.send_json({
                        "type": "summary",
                        "data": summary
                    })
                
            except json.JSONDecodeError:
                # Legacy support: raw base64 string
                frame = base64_to_frame(data)
                
                if frame is not None:
                    processed_frame, analysis = pose_corrector.process_frame(frame)
                    
                    response = {
                        "type": "analysis",
                        "rep_count": pose_corrector.rep_count,
                        "current_phase": pose_corrector.current_phase,
                        "exercise_name": pose_corrector.current_exercise_name,
                        "corrections": analysis.corrections if analysis else [],
                        "form_score": analysis.form_score if analysis else 0.0
                    }
                    
                    await websocket.send_json(response)
    
    except WebSocketDisconnect:
        print("❌ WebSocket client disconnected")
    except Exception as e:
        print(f"❌ WebSocket error: {e}")
        try:
            await websocket.send_json({
                "type": "error",
                "message": str(e)
            })
        except:
            pass

@app.get("/api/exercises/available")
async def get_available_exercises():
    """Get list of available exercises with pose tracking"""
    # This would return exercises from the CSV database
    return {
        "status": "success",
        "message": "Exercise database contains 1,451 exercises",
        "note": "Use exercise ID from your workout database to start tracking"
    }

if __name__ == "__main__":
    print("=" * 60)
    print("🤖 POSE CORRECTOR API SERVER")
    print("=" * 60)
    print(f"📍 HTTP Endpoint: http://localhost:8001")
    print(f"📍 WebSocket: ws://localhost:8001/ws/pose-analysis")
    print(f"📍 API Docs: http://localhost:8001/docs")
    print(f"📍 Health Check: http://localhost:8001/health")
    print("=" * 60)
    print("\n🎯 Available Endpoints:")
    print("   POST /api/start-exercise - Start exercise session")
    print("   GET  /api/session-summary - Get session stats")
    print("   POST /api/reset - Reset session")
    print("   WS   /ws/pose-analysis - Real-time pose analysis")
    print("\n✨ Press Ctrl+C to stop\n")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8001,
        log_level="info"
    )
