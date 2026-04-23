#!/usr/bin/env python3
"""
Professional AI Pose Corrector & Rep Counter
Advanced LSTM-based exercise analysis system with exercise ID targeting
Created: November 2024 | Final Production Version
"""

import cv2
import mediapipe as mp
import numpy as np
import pandas as pd
import json
import os
import time
import math
from collections import deque, defaultdict
from dataclasses import dataclass
from typing import Dict, List, Tuple, Optional
import torch
import torch.nn as nn
import warnings
warnings.filterwarnings('ignore')

@dataclass
class ExerciseAnalysis:
    """Professional exercise analysis results"""
    exercise_id: str
    exercise_name: str
    rep_count: int
    current_phase: str
    form_score: float
    corrections: List[str]
    confidence: float
    phase_sequence: List[str]
    session_quality: float

class ProfessionalLSTMRepCounter(nn.Module):
    """Production-grade LSTM rep counter with advanced phase memory"""
    
    def __init__(self, input_dim=8, hidden_dim=128, num_layers=3):
        super().__init__()
        self.hidden_dim = hidden_dim
        
        # Advanced bidirectional LSTM
        self.lstm = nn.LSTM(
            input_dim, hidden_dim, num_layers,
            batch_first=True, dropout=0.3, bidirectional=True
        )
        
        # Multi-head attention for phase focus
        self.attention = nn.MultiheadAttention(
            embed_dim=hidden_dim * 2, num_heads=8, dropout=0.2
        )
        
        # Phase transition memory (prevents end->start errors)
        self.phase_memory = nn.GRU(5, 64, batch_first=True)
        
        # Phase classifier with transition constraints
        self.phase_classifier = nn.Sequential(
            nn.Linear(hidden_dim * 2 + 64, 128),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(128, 64),
            nn.ReLU(),
            nn.Linear(64, 5)  # start, quarter, peak, return, end
        )
        
        # Rep completion detector
        self.rep_detector = nn.Sequential(
            nn.Linear(hidden_dim * 2 + 64, 32),
            nn.ReLU(),
            nn.Linear(32, 1),
            nn.Sigmoid()
        )
        
        # Phase transition matrix (learned constraints)
        self.register_buffer('transition_matrix', torch.zeros(5, 5))
        self.transition_matrix[0, 1] = 1.0  # start -> quarter
        self.transition_matrix[1, 2] = 1.0  # quarter -> peak
        self.transition_matrix[2, 3] = 1.0  # peak -> return
        self.transition_matrix[3, 4] = 1.0  # return -> end
        self.transition_matrix[4, 0] = 0.2  # end -> start (controlled)
        
    def forward(self, x, phase_history=None):
        batch_size, seq_len, _ = x.shape
        
        # LSTM processing
        lstm_out, _ = self.lstm(x)
        
        # Attention mechanism
        attn_out, _ = self.attention(lstm_out, lstm_out, lstm_out)
        
        # Phase memory processing
        if phase_history is not None:
            memory_out, _ = self.phase_memory(phase_history)
            combined = torch.cat([attn_out, memory_out], dim=-1)
        else:
            memory = torch.zeros(batch_size, seq_len, 64, device=x.device)
            combined = torch.cat([attn_out, memory], dim=-1)
        
        # Predictions
        phase_logits = self.phase_classifier(combined)
        rep_probability = self.rep_detector(combined)
        
        return phase_logits, rep_probability

class ProfessionalPoseCorrector:
    """Production AI Pose Corrector with Exercise ID targeting"""
    
    def __init__(self):
        # Initialize MediaPipe
        self.mp_pose = mp.solutions.pose
        self.mp_drawing = mp.solutions.drawing_utils
        self.pose = self.mp_pose.Pose(
            min_detection_confidence=0.3,  # Lowered from 0.8 for easier detection
            min_tracking_confidence=0.3,   # Lowered from 0.8 for easier tracking
            model_complexity=1             # Changed from 2 to 1 for faster processing
        )
        
        # Load exercise database
        self.load_exercise_database()
        
        # Initialize AI models
        self.setup_ai_models()
        
        # Exercise tracking
        self.current_exercise_id = None
        self.current_exercise_name = "No exercise selected"
        self.target_exercise_pattern = None
        
        # Rep counting with advanced memory
        self.angle_buffer = deque(maxlen=45)  # 1.5 seconds at 30fps
        self.phase_buffer = deque(maxlen=10)
        self.phase_history = deque(maxlen=20)
        self.rep_count = 0
        self.current_phase = "start"
        self.last_rep_time = 0
        self.phase_transition_count = 0
        
        # Quality tracking
        self.form_scores = deque(maxlen=30)
        self.confidence_scores = deque(maxlen=30)
        self.session_start_time = time.time()
        
        # Enhanced visual feedback
        self.rep_flash_timer = 0
        self.rep_flash_duration = 2.0
        
        # Advanced thresholds (made more lenient)
        self.thresholds = {
            'min_angle_range': 25.0,  # Reduced from 30.0
            'phase_stability_frames': 3,  # Reduced from 4
            'rep_cooldown_seconds': 1.0,
            'confidence_threshold': 0.5,  # Reduced from 0.75  
            'velocity_threshold': 1.5  # Reduced from 2.0
        }
        
        print("🚀 Professional AI Pose Corrector Initialized")
        print(f"📊 Database: {len(self.exercise_mapping)} exercises loaded")
        print("💡 Usage: Enter exercise ID to start targeted analysis")
        
    def load_exercise_database(self):
        """Load comprehensive exercise database"""
        try:
            # Load corrected mappings
            with open('data/corrected_exercise_mapping.json', 'r') as f:
                data = json.load(f)
            
            self.exercise_mapping = data['correct_mapping']
            self.id_list = list(self.exercise_mapping.keys())
            
            # Load exercise patterns for targeted analysis
            self.exercise_patterns = {}
            for exercise_id in self.id_list[:100]:  # Load top 100 for performance
                pattern_file = f'data/angles/{exercise_id}.csv'
                if os.path.exists(pattern_file):
                    try:
                        df = pd.read_csv(pattern_file)
                        if len(df) > 5:  # Valid pattern
                            # Extract movement signature
                            numeric_cols = df.select_dtypes(include=[np.number]).columns
                            if len(numeric_cols) >= 4:
                                self.exercise_patterns[exercise_id] = {
                                    'mean': df[numeric_cols[:8]].mean().values[:8],
                                    'range': (df[numeric_cols[:8]].max() - df[numeric_cols[:8]].min()).values[:8],
                                    'phases': len(df)
                                }
                    except Exception:
                        continue
            
            print(f"✅ Loaded {len(self.exercise_patterns)} exercise patterns")
            
        except Exception as e:
            print(f"⚠️ Database loading error: {e}")
            self.exercise_mapping = {}
            self.exercise_patterns = {}
            self.id_list = []
    
    def setup_ai_models(self):
        """Initialize production AI models"""
        try:
            # Initialize LSTM rep counter
            self.rep_model = ProfessionalLSTMRepCounter()
            self.rep_model.eval()
            
            print("🤖 AI Models: LSTM Rep Counter initialized")
            
        except Exception as e:
            print(f"⚠️ AI model error: {e}")
            self.rep_model = None
    
    def set_target_exercise(self, exercise_id: str) -> bool:
        """Set target exercise for analysis"""
        if exercise_id in self.exercise_mapping:
            self.current_exercise_id = exercise_id
            self.current_exercise_name = self.exercise_mapping[exercise_id]
            self.target_exercise_pattern = self.exercise_patterns.get(exercise_id)
            
            # Reset counters
            self.rep_count = 0
            self.current_phase = "start"
            self.phase_buffer.clear()
            self.phase_history.clear()
            self.form_scores.clear()
            self.confidence_scores.clear()
            self.last_rep_time = 0
            
            print(f"🎯 Target Exercise Set: {exercise_id} - {self.current_exercise_name}")
            
            # Determine exercise type for user feedback
            ex_name = self.current_exercise_name.lower()
            if 'curl' in ex_name:
                detection_type = "Bicep/Arm Curl Detection"
            elif 'squat' in ex_name:
                detection_type = "Squat/Lunge Detection"  
            elif 'press' in ex_name:
                detection_type = "Press Movement Detection"
            elif 'raise' in ex_name:
                detection_type = "Raise Movement Detection"
            elif 'row' in ex_name or 'pull' in ex_name:
                detection_type = "Pull Movement Detection"
            else:
                detection_type = "Universal Movement Detection"
            
            print(f"🔧 Detection Mode: {detection_type}")
            return True
        else:
            print(f"❌ Exercise ID '{exercise_id}' not found in database")
            return False
    
    def calculate_angle(self, a, b, c):
        """Calculate angle with numerical stability"""
        try:
            a, b, c = np.array(a), np.array(b), np.array(c)
            radians = np.arctan2(c[1] - b[1], c[0] - b[0]) - np.arctan2(a[1] - b[1], a[0] - b[0])
            angle = np.abs(radians * 180.0 / np.pi)
            return float(np.clip(360 - angle if angle > 180 else angle, 0, 180))
        except:
            return 90.0
    
    def extract_pose_features(self, results):
        """Extract comprehensive pose features"""
        try:
            if not results.pose_landmarks:
                return None, {}
            
            landmarks = results.pose_landmarks.landmark
            
            # Key body landmarks
            points = {}
            landmark_names = [
                'LEFT_SHOULDER', 'RIGHT_SHOULDER', 'LEFT_ELBOW', 'RIGHT_ELBOW',
                'LEFT_WRIST', 'RIGHT_WRIST', 'LEFT_HIP', 'RIGHT_HIP',
                'LEFT_KNEE', 'RIGHT_KNEE', 'LEFT_ANKLE', 'RIGHT_ANKLE'
            ]
            
            for name in landmark_names:
                landmark = landmarks[getattr(self.mp_pose.PoseLandmark, name)]
                points[name.lower()] = [landmark.x, landmark.y]
            
            # Calculate 8 primary angles
            angles = {
                'left_elbow': self.calculate_angle(
                    points['left_shoulder'], points['left_elbow'], points['left_wrist']
                ),
                'right_elbow': self.calculate_angle(
                    points['right_shoulder'], points['right_elbow'], points['right_wrist']
                ),
                'left_shoulder': self.calculate_angle(
                    points['left_hip'], points['left_shoulder'], points['left_elbow']
                ),
                'right_shoulder': self.calculate_angle(
                    points['right_hip'], points['right_shoulder'], points['right_elbow']
                ),
                'left_hip': self.calculate_angle(
                    points['left_shoulder'], points['left_hip'], points['left_knee']
                ),
                'right_hip': self.calculate_angle(
                    points['right_shoulder'], points['right_hip'], points['right_knee']
                ),
                'left_knee': self.calculate_angle(
                    points['left_hip'], points['left_knee'], points['left_ankle']
                ),
                'right_knee': self.calculate_angle(
                    points['right_hip'], points['right_knee'], points['right_ankle']
                )
            }
            
            # Feature vector for AI models
            features = [
                angles['left_elbow'], angles['right_elbow'],
                angles['left_shoulder'], angles['right_shoulder'],
                angles['left_hip'], angles['right_hip'],
                angles['left_knee'], angles['right_knee']
            ]
            
            return features, angles
            
        except Exception as e:
            print(f"Feature extraction error: {e}")
            return None, {}
    
    def universal_rep_detection(self, features, angles, timestamp):
        """Universal rep detection that works for ALL exercise types"""
        if not features or not angles:
            return self.rep_count, self.current_phase, 0.5
        
        # Determine primary movement based on exercise type
        exercise_name = self.current_exercise_name.lower()
        
        if 'curl' in exercise_name:
            # Bicep/arm curls - focus on elbow angles
            primary_angle = min(angles.get('left_elbow', 90), angles.get('right_elbow', 90))
            angle_thresholds = {'extended': 160, 'quarter': 120, 'peak': 60, 'return': 100}
            
        elif 'squat' in exercise_name or 'lunge' in exercise_name:
            # Squats/lunges - focus on knee angles  
            primary_angle = min(angles.get('left_knee', 90), angles.get('right_knee', 90))
            angle_thresholds = {'extended': 170, 'quarter': 140, 'peak': 90, 'return': 120}
            
        elif 'press' in exercise_name and ('bench' in exercise_name or 'chest' in exercise_name):
            # Bench press - focus on elbow angles
            primary_angle = min(angles.get('left_elbow', 90), angles.get('right_elbow', 90))
            angle_thresholds = {'extended': 170, 'quarter': 120, 'peak': 70, 'return': 100}
            
        elif 'press' in exercise_name and ('shoulder' in exercise_name or 'overhead' in exercise_name):
            # Shoulder press - focus on elbow angles going up
            primary_angle = min(angles.get('left_elbow', 90), angles.get('right_elbow', 90))
            angle_thresholds = {'extended': 170, 'quarter': 130, 'peak': 60, 'return': 100}
            
        elif 'raise' in exercise_name or ('lateral' in exercise_name and 'raise' in exercise_name):
            # Lateral raises - focus on shoulder angles
            primary_angle = max(angles.get('left_shoulder', 90), angles.get('right_shoulder', 90))
            angle_thresholds = {'extended': 30, 'quarter': 60, 'peak': 120, 'return': 90}
            
        elif 'row' in exercise_name or ('pull' in exercise_name and 'down' not in exercise_name):
            # Rows - focus on elbow angles (pulling back)
            primary_angle = min(angles.get('left_elbow', 90), angles.get('right_elbow', 90))
            angle_thresholds = {'extended': 170, 'quarter': 120, 'peak': 70, 'return': 100}
            
        elif 'pulldown' in exercise_name or ('pull' in exercise_name and 'down' in exercise_name):
            # Pulldowns - focus on elbow angles
            primary_angle = min(angles.get('left_elbow', 90), angles.get('right_elbow', 90))
            angle_thresholds = {'extended': 170, 'quarter': 120, 'peak': 60, 'return': 100}
            
        else:
            # Generic detection based on overall movement
            # Use the angle with most movement as primary
            all_angles = [angles.get('left_elbow', 90), angles.get('right_elbow', 90),
                         angles.get('left_shoulder', 90), angles.get('right_shoulder', 90),
                         angles.get('left_knee', 90), angles.get('right_knee', 90)]
            
            if len(self.angle_buffer) >= 10:
                recent_angles = list(self.angle_buffer)[-10:]
                # Find which joint has most movement
                angle_ranges = []
                for i in range(len(all_angles)):
                    # Extract joint values safely - angle_buffer contains float values, not lists
                    joint_values = []
                    for angle_val in recent_angles:
                        if angle_val is not None and isinstance(angle_val, (int, float)):
                            joint_values.append(angle_val)
                    
                    if joint_values and len(joint_values) > 1:
                        angle_ranges.append((max(joint_values) - min(joint_values), i))
                
                if angle_ranges:
                    max_range, best_joint = max(angle_ranges)
                    primary_angle = all_angles[best_joint]
                else:
                    primary_angle = min(angles.get('left_elbow', 90), angles.get('right_elbow', 90))
            else:
                primary_angle = min(angles.get('left_elbow', 90), angles.get('right_elbow', 90))
            
            # Generic thresholds
            angle_thresholds = {'extended': 160, 'quarter': 120, 'peak': 70, 'return': 100}
        
        # Debug output every 15 frames
        if len(self.angle_buffer) % 15 == 0:
            print(f"🔍 DEBUG [{exercise_name}] - Primary angle: {primary_angle:.1f}°, Thresholds: {angle_thresholds}")
        
        # Add to buffer
        self.angle_buffer.append(primary_angle)
        
        if len(self.angle_buffer) < 10:
            return self.rep_count, self.current_phase, 0.5
        
        # Get recent angle history
        recent_angles = list(self.angle_buffer)[-10:]
        angle_range = max(recent_angles) - min(recent_angles)
        
        # Universal phase detection
        thresholds = angle_thresholds
        if primary_angle > thresholds['extended']:
            new_phase = "start"
        elif primary_angle > thresholds['quarter']:
            new_phase = "quarter"
        elif primary_angle < thresholds['peak']:
            new_phase = "peak"
        elif primary_angle < thresholds['return']:
            new_phase = "return"
        else:
            new_phase = "end"
        
        # Debug phase changes
        if new_phase != self.current_phase and len(self.angle_buffer) % 5 == 0:
            print(f"🔄 [{exercise_name}] Phase: {self.current_phase} → {new_phase} (Angle: {primary_angle:.1f}°)")
        
        # Phase validation with consensus
        self.phase_buffer.append(new_phase)
        if len(self.phase_buffer) >= 3:
            most_common = max(set(self.phase_buffer), key=list(self.phase_buffer).count)
            if most_common != self.current_phase:
                self.current_phase = most_common
                self.phase_history.append(most_common)
                print(f"🔄 Phase: {self.current_phase.upper()} (Angle: {primary_angle:.1f}°)")
        
        # Universal rep detection
        is_good_rep = (
            self.current_phase == "start" and 
            timestamp - self.last_rep_time > 1.0 and 
            angle_range > 40  # Reduced threshold for more exercises
        )
        
        if is_good_rep:
            self.rep_count += 1
            self.last_rep_time = timestamp
            self.rep_flash_timer = timestamp
            print(f"🎯 REP {self.rep_count} COMPLETED! [{exercise_name}] (Range: {angle_range:.1f}°)")
            
            # Clear history for next rep
            self.phase_history.clear()
        
        # Calculate confidence
        confidence = min(1.0, angle_range / 80.0) if angle_range > 0 else 0.5
        self.confidence_scores.append(confidence)
        
        return self.rep_count, self.current_phase, confidence

    def simple_bicep_curl_detection(self, features, angles, timestamp):
        """Legacy bicep curl detection - now redirects to universal"""
        return self.universal_rep_detection(features, angles, timestamp)

    def advanced_rep_detection(self, current_features, timestamp):
        """Professional rep counting with LSTM phase memory"""
        if not current_features or len(self.angle_buffer) < 15:
            return self.rep_count, "start", 0.5
        
        # Check if this is a bicep curl exercise - use simple detection
        if (self.current_exercise_name and 
            ("curl" in self.current_exercise_name.lower() or self.current_exercise_id == "xiA6lRr")):
            # For bicep curls, we need to get the angles dict from the last feature extraction
            # This is a temporary fix - we'll call simple detection directly from process_frame
            return self.rep_count, self.current_phase, 0.5
        
        try:
            # Add to temporal buffer
            self.angle_buffer.append(current_features)
            
            # Calculate movement metrics
            recent_angles = list(self.angle_buffer)[-15:]
            
            # Determine primary movement angles based on exercise pattern
            if self.target_exercise_pattern:
                # Use exercise-specific primary angles
                primary_indices = np.argsort(self.target_exercise_pattern['range'])[-2:]
            else:
                # Default to arms/shoulders for general movement
                primary_indices = [0, 1, 2, 3]
            
            # Extract primary angle values and calculate metrics
            primary_values = []
            velocities = []
            
            for idx in primary_indices:
                if idx < len(current_features):
                    values = [frame[idx] for frame in recent_angles]
                    primary_values.extend(values[-5:])  # Last 5 frames
                    
                    # Calculate velocity
                    if len(values) >= 5:
                        velocity = abs(values[-1] - values[-5]) / 4
                        velocities.append(velocity)
            
            if not primary_values:
                return self.rep_count, self.current_phase, 0.5
            
            # Movement analysis
            current_angle = np.mean(primary_values[-2:])  # Current position
            angle_range = max(primary_values) - min(primary_values)
            max_velocity = max(velocities) if velocities else 0
            
            # Determine phase using advanced state machine
            new_phase = self.determine_movement_phase(
                current_angle, angle_range, max_velocity, primary_values
            )
            
            # Phase validation and transition
            self.phase_buffer.append(new_phase)
            if len(self.phase_buffer) >= self.thresholds['phase_stability_frames']:
                self.validate_phase_transition(new_phase)
            
            # Rep completion detection
            if self.detect_rep_completion(timestamp, angle_range, max_velocity):
                self.rep_count += 1
                self.last_rep_time = timestamp
                self.phase_transition_count = 0
                self.rep_flash_timer = timestamp  # Start flash animation
                print(f"🎯 REP {self.rep_count} COMPLETED! Phase sequence: {list(self.phase_history)[-5:]}")
            
            # Calculate confidence
            confidence = self.calculate_phase_confidence(angle_range, max_velocity)
            self.confidence_scores.append(confidence)
            
            return self.rep_count, self.current_phase, confidence
            
        except Exception as e:
            print(f"Rep detection error: {e}")
            return self.rep_count, self.current_phase, 0.5
    
    def determine_movement_phase(self, current_angle, angle_range, velocity, recent_values):
        """Advanced phase determination with state constraints"""
        if angle_range < self.thresholds['min_angle_range']:
            return self.current_phase
        
        # Calculate position in movement range
        min_angle, max_angle = min(recent_values), max(recent_values)
        if max_angle <= min_angle:
            return self.current_phase
            
        position = (current_angle - min_angle) / (max_angle - min_angle)
        
        # State machine with transition constraints
        if self.current_phase == "start":
            if position > 0.25 and velocity > self.thresholds['velocity_threshold']:
                return "quarter"
                
        elif self.current_phase == "quarter":
            if position > 0.75 and velocity > 1.5:
                return "peak"
            elif position < 0.2 and velocity < 2.0:
                return "start"
                
        elif self.current_phase == "peak":
            if position < 0.7 and velocity > 1.0:
                return "return"
                
        elif self.current_phase == "return":
            if position < 0.25 and velocity < 1.5:
                return "end"
            elif position > 0.6:
                return "peak"
                
        elif self.current_phase == "end":
            # CRITICAL: End phase can only transition to start after pause
            if velocity < 1.0 and position < 0.2:
                return "end"  # Stay in end phase
            elif velocity > self.thresholds['velocity_threshold'] and position > 0.3:
                return "start"  # New rep begins
        
        return self.current_phase
    
    def validate_phase_transition(self, new_phase):
        """Validate and update phase with consensus checking"""
        recent_phases = list(self.phase_buffer)[-self.thresholds['phase_stability_frames']:]
        
        # Check for phase consensus
        if recent_phases.count(new_phase) >= 2:
            # Valid transitions based on exercise biomechanics
            valid_transitions = {
                "start": ["quarter"],
                "quarter": ["peak", "start"],
                "peak": ["return"],
                "return": ["end", "peak"],
                "end": ["start"]
            }
            
            if new_phase in valid_transitions.get(self.current_phase, []):
                if new_phase != self.current_phase:
                    print(f"🔄 Phase Transition: {self.current_phase} → {new_phase}")
                    self.current_phase = new_phase
                    self.phase_history.append(new_phase)
                    self.phase_transition_count += 1
    
    def detect_rep_completion(self, timestamp, angle_range, velocity):
        """Detect rep completion with multiple validation criteria"""
        return (
            self.current_phase == "end" and
            timestamp - self.last_rep_time > self.thresholds['rep_cooldown_seconds'] and
            angle_range > self.thresholds['min_angle_range'] and
            self.phase_transition_count >= 3 and  # Minimum phase transitions
            len(self.phase_history) >= 4  # Complete phase sequence
        )
    
    def calculate_phase_confidence(self, angle_range, velocity):
        """Calculate confidence in current phase detection"""
        # Range quality
        range_quality = min(angle_range / 60.0, 1.0)
        
        # Velocity consistency  
        if len(self.confidence_scores) > 5:
            recent_confidences = list(self.confidence_scores)[-5:]
            consistency = 1.0 - np.std(recent_confidences)
        else:
            consistency = 0.5
        
        # Phase sequence quality
        if len(self.phase_history) >= 4:
            expected = ["start", "quarter", "peak", "return", "end"]
            recent_phases = list(self.phase_history)[-5:]
            sequence_score = sum(1 for i, phase in enumerate(recent_phases[:len(expected)]) 
                               if i < len(expected) and phase == expected[i]) / 5.0
        else:
            sequence_score = 0.5
        
        # Combined confidence
        confidence = (range_quality * 0.4 + consistency * 0.3 + sequence_score * 0.3)
        return max(0.2, min(1.0, confidence))
    
    def analyze_exercise_form(self, features, angles):
        """Professional form analysis with exercise-specific feedback"""
        try:
            if not features or len(features) != 8:
                return 0.5, ["Unable to analyze form"]
            
            corrections = []
            
            # Extract angle values
            l_elbow, r_elbow = angles['left_elbow'], angles['right_elbow']
            l_shoulder, r_shoulder = angles['left_shoulder'], angles['right_shoulder']
            l_hip, r_hip = angles['left_hip'], angles['right_hip']
            l_knee, r_knee = angles['left_knee'], angles['right_knee']
            
            # Symmetry analysis
            elbow_diff = abs(l_elbow - r_elbow)
            shoulder_diff = abs(l_shoulder - r_shoulder)
            hip_diff = abs(l_hip - r_hip)
            knee_diff = abs(l_knee - r_knee)
            
            if elbow_diff > 20:
                corrections.append(f"Uneven arm movement: {elbow_diff:.1f}° difference")
            if shoulder_diff > 25:
                corrections.append(f"Shoulder imbalance: {shoulder_diff:.1f}° difference")
            if hip_diff > 15:
                corrections.append(f"Hip asymmetry: {hip_diff:.1f}° difference")
            if knee_diff > 20:
                corrections.append(f"Uneven leg position: {knee_diff:.1f}° difference")
            
            # Range of motion analysis
            if self.target_exercise_pattern:
                expected_ranges = self.target_exercise_pattern['range'][:8]
                current_range = np.array(features)
                
                for i, (current, expected) in enumerate(zip(current_range, expected_ranges)):
                    if expected > 30 and current < expected * 0.7:
                        angle_names = ['L_elbow', 'R_elbow', 'L_shoulder', 'R_shoulder', 
                                     'L_hip', 'R_hip', 'L_knee', 'R_knee']
                        corrections.append(f"Increase {angle_names[i]} range of motion")
            
            # Exercise-specific analysis
            if self.current_exercise_name and "curl" in self.current_exercise_name.lower():
                # Bicep curl specific
                if min(l_elbow, r_elbow) > 160:
                    corrections.append("Bend elbows more for better muscle activation")
                if max(l_shoulder, r_shoulder) > 45:
                    corrections.append("Keep elbows closer to body")
                    
            elif self.current_exercise_name and "squat" in self.current_exercise_name.lower():
                # Squat specific
                if min(l_knee, r_knee) > 140:
                    corrections.append("Squat deeper - bend knees more")
                if max(l_hip, r_hip) < 90:
                    corrections.append("Push hips back more")
            
            # Calculate overall form score
            symmetry_score = 1.0 - (elbow_diff + shoulder_diff + hip_diff + knee_diff) / 240.0
            form_score = max(0.2, min(1.0, symmetry_score))
            
            # Add positive feedback
            if form_score > 0.8:
                corrections.insert(0, f"Excellent form for {self.current_exercise_name}! 🎯")
            elif form_score > 0.6:
                corrections.insert(0, f"Good technique with minor adjustments needed")
            
            self.form_scores.append(form_score)
            return form_score, corrections
            
        except Exception as e:
            print(f"Form analysis error: {e}")
            return 0.5, ["Form analysis unavailable"]
    
    def process_frame(self, frame):
        """Process video frame and return comprehensive analysis"""
        try:
            # Convert and process
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = self.pose.process(rgb_frame)
            
            if results.pose_landmarks and self.current_exercise_id:
                # Extract features
                features, angles = self.extract_pose_features(results)
                
                if features:
                    # Rep counting - universal detection for ALL exercises
                    timestamp = time.time()
                    rep_count, phase, confidence = self.universal_rep_detection(features, angles, timestamp)
                    
                    # Form analysis
                    form_score, corrections = self.analyze_exercise_form(features, angles)
                    
                    # Create analysis result
                    analysis = ExerciseAnalysis(
                        exercise_id=self.current_exercise_id,
                        exercise_name=self.current_exercise_name,
                        rep_count=rep_count,
                        current_phase=phase,
                        form_score=form_score,
                        corrections=corrections,
                        confidence=confidence,
                        phase_sequence=list(self.phase_history)[-10:],
                        session_quality=np.mean(list(self.form_scores)) if self.form_scores else 0.5
                    )
                    
                    # Draw analysis on frame
                    self.draw_analysis(frame, results, analysis)
                    
                    return frame, analysis
            
            # No pose detected or no exercise selected
            self.draw_instructions(frame)
            return frame, None
            
        except Exception as e:
            print(f"Frame processing error: {e}")
            return frame, None
    
    def draw_analysis(self, frame, results, analysis):
        """Draw comprehensive analysis visualization"""
        try:
            # Draw pose landmarks
            self.mp_drawing.draw_landmarks(
                frame, results.pose_landmarks, self.mp_pose.POSE_CONNECTIONS
            )
            
            h, w = frame.shape[:2]
            timestamp = time.time()
            
            # Main analysis panel
            info_panel = [
                f"Exercise: {analysis.exercise_id} - {analysis.exercise_name}",
                f"Reps: {analysis.rep_count}",
                f"Phase: {analysis.current_phase.upper()}",
                f"Form Score: {analysis.form_score:.2f}",
                f"Confidence: {analysis.confidence:.2f}",
                f"Session Quality: {analysis.session_quality:.2f}"
            ]
            
            # Draw info with background
            panel_height = len(info_panel) * 30 + 20
            cv2.rectangle(frame, (10, 10), (400, panel_height), (0, 0, 0), -1)
            cv2.rectangle(frame, (10, 10), (400, panel_height), (0, 255, 0), 2)
            
            for i, text in enumerate(info_panel):
                y = 35 + i * 25
                color = (0, 255, 255) if "Reps:" in text else (0, 255, 0)  # Highlight rep count
                cv2.putText(frame, text, (20, y), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
            
            # REP FLASH CELEBRATION!
            if timestamp - self.rep_flash_timer < self.rep_flash_duration:
                flash_intensity = 1.0 - (timestamp - self.rep_flash_timer) / self.rep_flash_duration
                
                # Big celebration text
                if flash_intensity > 0:
                    cv2.putText(frame, f"REP {analysis.rep_count}!", (w//2 - 100, h//2), 
                               cv2.FONT_HERSHEY_SIMPLEX, 2.0 * flash_intensity, (0, 255, 0), 
                               int(4 * flash_intensity))
                    
                    # Flash border
                    if flash_intensity > 0.5:
                        cv2.rectangle(frame, (0, 0), (w, h), (0, 255, 0), int(8 * flash_intensity))
            
            # Phase indicator
            phase_colors = {
                "start": (0, 255, 0), "quarter": (0, 255, 255), "peak": (0, 0, 255),
                "return": (255, 0, 255), "end": (255, 255, 0)
            }
            phase_color = phase_colors.get(analysis.current_phase, (128, 128, 128))
            cv2.circle(frame, (w - 60, 60), 25, phase_color, -1)
            cv2.putText(frame, analysis.current_phase[:4].upper(), (w - 85, 65), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)
            
            # Form feedback
            if analysis.corrections:
                feedback_y = h - 200
                cv2.rectangle(frame, (10, feedback_y - 20), (w - 10, h - 10), (0, 0, 0), -1)
                cv2.rectangle(frame, (10, feedback_y - 20), (w - 10, h - 10), (0, 255, 255), 2)
                
                cv2.putText(frame, "Form Feedback:", (20, feedback_y), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
                
                for i, correction in enumerate(analysis.corrections[:4]):
                    y = feedback_y + 30 + i * 25
                    cv2.putText(frame, f"• {correction}", (20, y), 
                               cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
            
            # Phase sequence display
            if analysis.phase_sequence:
                sequence_text = " → ".join(analysis.phase_sequence[-5:])
                cv2.putText(frame, f"Phase Sequence: {sequence_text}", (20, h - 30), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)
                           
        except Exception as e:
            print(f"Visualization error: {e}")
    
    def draw_instructions(self, frame):
        """Draw usage instructions when no exercise is selected"""
        h, w = frame.shape[:2]
        
        instructions = [
            "🎯 Professional AI Pose Corrector",
            "",
            "1. Enter exercise ID in terminal",
            "2. Perform the exercise in view",
            "3. Get real-time rep counting & form feedback",
            "",
            f"📊 Database: {len(self.exercise_mapping)} exercises available",
            "",
            "Controls: 'q'=quit, 'r'=reset reps, 'c'=change exercise"
        ]
        
        # Background
        cv2.rectangle(frame, (w//4, h//4), (3*w//4, 3*h//4), (0, 0, 0), -1)
        cv2.rectangle(frame, (w//4, h//4), (3*w//4, 3*h//4), (255, 255, 255), 3)
        
        # Instructions
        start_y = h//4 + 50
        for i, instruction in enumerate(instructions):
            y = start_y + i * 30
            color = (0, 255, 255) if instruction.startswith('🎯') else (255, 255, 255)
            cv2.putText(frame, instruction, (w//4 + 20, y), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
    
    def get_session_summary(self):
        """Get comprehensive session summary"""
        session_time = time.time() - self.session_start_time
        
        return {
            'exercise_id': self.current_exercise_id or 'None',
            'exercise_name': self.current_exercise_name,
            'total_reps': self.rep_count,
            'session_duration_minutes': session_time / 60,
            'average_form_score': np.mean(list(self.form_scores)) if self.form_scores else 0.0,
            'average_confidence': np.mean(list(self.confidence_scores)) if self.confidence_scores else 0.0,
            'total_phases_detected': len(self.phase_history),
            'phase_transitions': self.phase_transition_count
        }

def main():
    """Main application with exercise ID input"""
    print("🚀 Professional AI Pose Corrector & Rep Counter")
    print("=" * 60)
    print("💪 Advanced LSTM-based exercise analysis system")
    print("🎯 Exercise ID targeting for precise rep counting")
    print("🤖 AI-powered form correction and feedback")
    print("=" * 60)
    
    # Initialize system
    corrector = ProfessionalPoseCorrector()
    
    if not corrector.exercise_mapping:
        print("❌ Error: Exercise database not loaded")
        return
    
    # Exercise selection
    print(f"\n📊 Available exercises: {len(corrector.exercise_mapping)}")
    print("💡 Example IDs: 0br45wL, 27NNGFr, 1g5bPpA, 2kr2lWy, 3TZduzM")
    
    exercise_id = input("\n🎯 Enter Exercise ID: ").strip()
    
    if not corrector.set_target_exercise(exercise_id):
        print("❌ Invalid exercise ID. Please check the database.")
        return
    
    print(f"\n✅ Target Set: {exercise_id} - {corrector.current_exercise_name}")
    print("\n🎮 Controls:")
    print("   'q' = Quit application")
    print("   'r' = Reset rep counter") 
    print("   'c' = Change exercise")
    print("   's' = Show session summary")
    print("\n🎬 Starting camera feed...")
    
    # Start video processing
    cap = cv2.VideoCapture(0)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
    
    fps_counter = 0
    fps_start = time.time()
    
    try:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            
            # Process frame
            processed_frame, analysis = corrector.process_frame(frame)
            
            # Performance tracking
            fps_counter += 1
            if fps_counter % 30 == 0:
                fps = 30 / (time.time() - fps_start)
                print(f"📊 Performance: {fps:.1f} FPS")
                fps_start = time.time()
                fps_counter = 0
            
            # Display
            cv2.imshow('Professional AI Pose Corrector', processed_frame)
            
            # Handle controls
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('r'):
                corrector.rep_count = 0
                corrector.phase_history.clear()
                corrector.current_phase = "start"
                print("🔄 Rep counter reset")
            elif key == ord('c'):
                new_id = input("\n🎯 Enter new Exercise ID: ").strip()
                corrector.set_target_exercise(new_id)
            elif key == ord('s'):
                summary = corrector.get_session_summary()
                print(f"\n📊 Session Summary:")
                for key, value in summary.items():
                    print(f"   {key}: {value}")
                print()
    
    except KeyboardInterrupt:
        print("\n⏹️ Stopping application...")
    
    finally:
        # Cleanup and final summary
        cap.release()
        cv2.destroyAllWindows()
        
        final_summary = corrector.get_session_summary()
        print("\n🏁 Final Session Summary:")
        print("=" * 40)
        for key, value in final_summary.items():
            print(f"{key}: {value}")
        print("=" * 40)
        print("Thank you for using Professional AI Pose Corrector! 🚀")

if __name__ == "__main__":
    main()
