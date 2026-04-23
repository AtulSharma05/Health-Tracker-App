"""
Exercise GIF Angle Extractor for Pose Correction System
Processes exercise GIFs and extracts key joint angles for form analysis
"""

import json
import cv2
import mediapipe as mp
import numpy as np
import pandas as pd
import requests
import os
import tempfile
from urllib.parse import urlparse
from typing import Dict, List, Tuple, Optional
import time

class ExerciseAngleExtractor:
    def __init__(self):
        """Initialize MediaPipe Pose and angle extraction utilities."""
        self.mp_pose = mp.solutions.pose
        self.mp_drawing = mp.solutions.drawing_utils
        
        # Create angles directory
        self.angles_dir = '/Users/aliabbas/model/data/angles'
        os.makedirs(self.angles_dir, exist_ok=True)
        
        # Joint angle mappings
        self.angle_definitions = {
            'left_elbow_angle': (11, 13, 15),    # shoulder-elbow-wrist
            'right_elbow_angle': (12, 14, 16),   # shoulder-elbow-wrist
            'left_shoulder_angle': (23, 11, 13), # hip-shoulder-elbow
            'right_shoulder_angle': (24, 12, 14), # hip-shoulder-elbow
            'left_hip_angle': (11, 23, 25),      # shoulder-hip-knee
            'right_hip_angle': (12, 24, 26),     # shoulder-hip-knee
            'left_knee_angle': (23, 25, 27),     # hip-knee-ankle
            'right_knee_angle': (24, 26, 28),    # hip-knee-ankle
            'left_ankle_angle': (25, 27, 31),    # knee-ankle-foot
            'right_ankle_angle': (26, 28, 32),   # knee-ankle-foot
        }
        
        # Exercise category angle mapping
        self.exercise_angle_map = {
            'chest': ['left_elbow_angle', 'right_elbow_angle', 'left_shoulder_angle', 'right_shoulder_angle'],
            'shoulders': ['left_shoulder_angle', 'right_shoulder_angle', 'left_elbow_angle', 'right_elbow_angle'],
            'upper arms': ['left_elbow_angle', 'right_elbow_angle', 'left_shoulder_angle', 'right_shoulder_angle'],
            'lower arms': ['left_elbow_angle', 'right_elbow_angle'],
            'upper legs': ['left_hip_angle', 'right_hip_angle', 'left_knee_angle', 'right_knee_angle'],
            'lower legs': ['left_knee_angle', 'right_knee_angle', 'left_ankle_angle', 'right_ankle_angle'],
            'back': ['left_shoulder_angle', 'right_shoulder_angle', 'torso_angle'],
            'waist': ['left_hip_angle', 'right_hip_angle', 'torso_angle'],
            'cardio': ['left_hip_angle', 'right_hip_angle', 'left_knee_angle', 'right_knee_angle']
        }
        
    def calculate_angle(self, point1: List[float], point2: List[float], point3: List[float]) -> float:
        """Calculate angle between three points in degrees."""
        try:
            a = np.array(point1)
            b = np.array(point2)
            c = np.array(point3)
            
            # Calculate vectors
            ba = a - b
            bc = c - b
            
            # Calculate cosine angle
            cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
            cosine_angle = np.clip(cosine_angle, -1.0, 1.0)
            
            # Calculate angle in degrees
            angle = np.arccos(cosine_angle)
            return np.degrees(angle)
            
        except Exception as e:
            print(f"Error calculating angle: {e}")
            return 0.0
    
    def download_gif(self, url: str) -> Optional[str]:
        """Download GIF to temporary file."""
        try:
            print(f"Downloading GIF from: {url}")
            response = requests.get(url, timeout=30, stream=True)
            response.raise_for_status()
            
            # Create temporary file
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.gif')
            
            # Download in chunks
            for chunk in response.iter_content(chunk_size=8192):
                temp_file.write(chunk)
            
            temp_file.close()
            print(f"✅ Downloaded to: {temp_file.name}")
            return temp_file.name
            
        except Exception as e:
            print(f"❌ Error downloading GIF from {url}: {e}")
            return None
    
    def extract_key_frames(self, gif_path: str) -> List[Tuple[np.ndarray, int, str]]:
        """Extract key frames representing exercise phases."""
        cap = cv2.VideoCapture(gif_path)
        frames = []
        
        # Read all frames
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            frames.append(frame)
        
        cap.release()
        
        if len(frames) < 4:
            print(f"⚠️ Only {len(frames)} frames found, using all available")
            return [(frame, i, f"frame_{i}") for i, frame in enumerate(frames)]
        
        total_frames = len(frames)
        key_frames = []
        
        # Extract key phases of exercise movement
        phases = [
            (0, "start"),                          # Starting position (0%)
            (total_frames // 4, "quarter"),       # Quarter movement (25%)
            (total_frames // 2, "peak"),          # Peak position (50%)
            ((total_frames * 3) // 4, "return"),  # Return phase (75%)
            (total_frames - 1, "end")             # End position (100%)
        ]
        
        for frame_idx, phase_name in phases:
            if frame_idx < len(frames):
                key_frames.append((frames[frame_idx], frame_idx, phase_name))
        
        print(f"✅ Extracted {len(key_frames)} key frames from {total_frames} total frames")
        return key_frames
    
    def get_relevant_angles(self, exercise_data: Dict) -> List[str]:
        """Determine which angles are relevant for this exercise."""
        body_parts = exercise_data.get('bodyParts', [])
        target_muscles = exercise_data.get('targetMuscles', [])
        exercise_name = exercise_data.get('name', '').lower()
        
        relevant_angles = set()
        
        # Add angles based on body parts
        for body_part in body_parts:
            if body_part in self.exercise_angle_map:
                relevant_angles.update(self.exercise_angle_map[body_part])
        
        # Add exercise-specific angles based on name
        if any(keyword in exercise_name for keyword in ['curl', 'raise', 'press', 'extension']):
            relevant_angles.update(['left_elbow_angle', 'right_elbow_angle'])
        
        if any(keyword in exercise_name for keyword in ['squat', 'lunge', 'deadlift']):
            relevant_angles.update(['left_hip_angle', 'right_hip_angle', 'left_knee_angle', 'right_knee_angle'])
        
        if any(keyword in exercise_name for keyword in ['push', 'chest', 'bench']):
            relevant_angles.update(['left_shoulder_angle', 'right_shoulder_angle', 'left_elbow_angle', 'right_elbow_angle'])
        
        if any(keyword in exercise_name for keyword in ['plank', 'crunch', 'twist']):
            relevant_angles.add('torso_angle')
        
        # Always include core angles for full-body exercises
        if 'cardio' in body_parts:
            relevant_angles.update(['left_hip_angle', 'right_hip_angle', 'left_knee_angle', 'right_knee_angle'])
        
        return list(relevant_angles)
    
    def compute_torso_angle(self, landmarks) -> float:
        """Calculate torso inclination angle."""
        try:
            # Get shoulder and hip midpoints
            left_shoulder = landmarks[11]
            right_shoulder = landmarks[12]
            left_hip = landmarks[23]
            right_hip = landmarks[24]
            
            shoulder_midpoint = np.array([
                (left_shoulder.x + right_shoulder.x) / 2,
                (left_shoulder.y + right_shoulder.y) / 2
            ])
            
            hip_midpoint = np.array([
                (left_hip.x + right_hip.x) / 2,
                (left_hip.y + right_hip.y) / 2
            ])
            
            # Calculate angle with vertical
            torso_vector = shoulder_midpoint - hip_midpoint
            vertical = np.array([0, -1])  # Upward direction
            
            dot_product = np.dot(torso_vector, vertical)
            norms = np.linalg.norm(torso_vector) * np.linalg.norm(vertical)
            
            if norms == 0:
                return 90.0
            
            cos_angle = dot_product / norms
            cos_angle = np.clip(cos_angle, -1.0, 1.0)
            
            return np.degrees(np.arccos(cos_angle))
            
        except Exception as e:
            print(f"Error computing torso angle: {e}")
            return 90.0
    
    def compute_angles_from_landmarks(self, landmarks, relevant_angles: List[str]) -> Dict[str, float]:
        """Compute specified angles from pose landmarks."""
        angles = {}
        
        try:
            # Standard joint angles
            for angle_name in relevant_angles:
                if angle_name == 'torso_angle':
                    angles[angle_name] = self.compute_torso_angle(landmarks)
                elif angle_name in self.angle_definitions:
                    p1_idx, p2_idx, p3_idx = self.angle_definitions[angle_name]
                    
                    # Check if landmarks exist and are visible
                    if (p1_idx < len(landmarks) and p2_idx < len(landmarks) and 
                        p3_idx < len(landmarks)):
                        
                        p1 = landmarks[p1_idx]
                        p2 = landmarks[p2_idx]
                        p3 = landmarks[p3_idx]
                        
                        # Check visibility
                        if p1.visibility > 0.5 and p2.visibility > 0.5 and p3.visibility > 0.5:
                            point1 = [p1.x, p1.y]
                            point2 = [p2.x, p2.y]
                            point3 = [p3.x, p3.y]
                            
                            angle = self.calculate_angle(point1, point2, point3)
                            angles[angle_name] = round(angle, 2)
                        
        except Exception as e:
            print(f"Error computing angles from landmarks: {e}")
        
        return angles
    
    def process_exercise(self, exercise_data: Dict) -> bool:
        """Process a single exercise and generate angle CSV."""
        exercise_id = exercise_data.get('exerciseId')
        exercise_name = exercise_data.get('name', 'Unknown')
        gif_url = exercise_data.get('gifUrl')
        
        if not gif_url or not exercise_id:
            print(f"❌ Missing data for exercise: {exercise_name}")
            return False
        
        print(f"\n🏋️ Processing exercise: {exercise_name} (ID: {exercise_id})")
        
        # Download GIF
        gif_path = self.download_gif(gif_url)
        if not gif_path:
            return False
        
        try:
            # Extract key frames
            key_frames = self.extract_key_frames(gif_path)
            if not key_frames:
                print("❌ No frames extracted from GIF")
                return False
            
            # Get relevant angles for this exercise
            relevant_angles = self.get_relevant_angles(exercise_data)
            print(f"📐 Analyzing angles: {relevant_angles}")
            
            # Process frames with MediaPipe
            csv_data = []
            
            with self.mp_pose.Pose(
                min_detection_confidence=0.5,
                min_tracking_confidence=0.5,
                model_complexity=1
            ) as pose:
                
                for frame, frame_number, phase in key_frames:
                    # Convert BGR to RGB
                    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    
                    # Process with MediaPipe
                    results = pose.process(rgb_frame)
                    
                    if results.pose_landmarks:
                        # Compute angles
                        angles = self.compute_angles_from_landmarks(
                            results.pose_landmarks.landmark,
                            relevant_angles
                        )
                        
                        # Add to CSV data
                        for angle_name, angle_value in angles.items():
                            # Get landmark coordinates for reference
                            landmark_coords = ""
                            if angle_name in self.angle_definitions:
                                p1_idx, p2_idx, p3_idx = self.angle_definitions[angle_name]
                                if p2_idx < len(results.pose_landmarks.landmark):
                                    landmark = results.pose_landmarks.landmark[p2_idx]
                                    landmark_coords = f"({landmark.x:.3f},{landmark.y:.3f})"
                            
                            csv_data.append({
                                'exerciseId': exercise_id,
                                'frameNumber': frame_number,
                                'angleName': angle_name,
                                'angleValue': angle_value,
                                'landmarkCoordinates': landmark_coords,
                                'phase': phase
                            })
                    else:
                        print(f"⚠️ No pose detected in frame {frame_number} ({phase})")
            
            # Save CSV if we have data
            if csv_data:
                df = pd.DataFrame(csv_data)
                csv_path = os.path.join(self.angles_dir, f'{exercise_id}.csv')
                df.to_csv(csv_path, index=False)
                
                print(f"✅ Generated {csv_path}")
                print(f"📊 Extracted {len(csv_data)} angle measurements across {len(key_frames)} frames")
                
                # Show summary
                unique_angles = df['angleName'].unique()
                print(f"🎯 Key angles detected: {', '.join(unique_angles)}")
                
                return True
            else:
                print(f"❌ No pose landmarks detected for exercise {exercise_id}")
                return False
                
        finally:
            # Clean up temporary file
            if os.path.exists(gif_path):
                os.unlink(gif_path)
    
    def process_batch(self, start_idx: int = 0, count: int = 10) -> Dict[str, int]:
        """Process a batch of exercises."""
        try:
            with open('/Users/aliabbas/model/data/exercises.json', 'r') as f:
                exercises = json.load(f)
            
            print(f"📚 Loaded {len(exercises)} exercises from database")
            
            # Process specified range
            end_idx = min(start_idx + count, len(exercises))
            batch = exercises[start_idx:end_idx]
            
            print(f"🎯 Processing exercises {start_idx+1} to {end_idx} ({len(batch)} exercises)")
            
            stats = {'successful': 0, 'failed': 0, 'skipped': 0}
            
            for i, exercise in enumerate(batch):
                exercise_id = exercise.get('exerciseId', f'unknown_{i}')
                csv_path = os.path.join(self.angles_dir, f'{exercise_id}.csv')
                
                # Skip if already processed
                if os.path.exists(csv_path):
                    print(f"⏭️ Skipping {exercise_id} - already processed")
                    stats['skipped'] += 1
                    continue
                
                print(f"\n[{start_idx + i + 1}/{end_idx}] ", end="")
                
                try:
                    if self.process_exercise(exercise):
                        stats['successful'] += 1
                    else:
                        stats['failed'] += 1
                        
                    # Small delay to avoid overwhelming servers
                    time.sleep(0.5)
                    
                except Exception as e:
                    print(f"❌ Error processing exercise {exercise_id}: {e}")
                    stats['failed'] += 1
            
            # Print summary
            print(f"\n" + "="*50)
            print(f"📊 BATCH PROCESSING SUMMARY")
            print(f"="*50)
            print(f"✅ Successful: {stats['successful']}")
            print(f"❌ Failed: {stats['failed']}")
            print(f"⏭️ Skipped: {stats['skipped']}")
            print(f"📁 CSV files created in: {self.angles_dir}")
            
            return stats
            
        except Exception as e:
            print(f"❌ Error processing batch: {e}")
            return {'successful': 0, 'failed': 0, 'skipped': 0}
    
    def analyze_specific_exercise(self, exercise_id: str) -> bool:
        """Analyze a specific exercise by ID."""
        try:
            with open('/Users/aliabbas/model/data/exercises.json', 'r') as f:
                exercises = json.load(f)
            
            # Find exercise by ID
            target_exercise = None
            for exercise in exercises:
                if exercise.get('exerciseId') == exercise_id:
                    target_exercise = exercise
                    break
            
            if not target_exercise:
                print(f"❌ Exercise with ID '{exercise_id}' not found")
                return False
            
            return self.process_exercise(target_exercise)
            
        except Exception as e:
            print(f"❌ Error analyzing exercise {exercise_id}: {e}")
            return False


def main():
    """Main function to run the angle extraction system."""
    extractor = ExerciseAngleExtractor()
    
    print("🏋️ Exercise GIF Angle Extractor")
    print("=" * 40)
    print("1. Process first 10 exercises (test)")
    print("2. Process custom batch")
    print("3. Process specific exercise by ID")
    print("4. Continue processing from where left off")
    print("5. Exit")
    
    while True:
        choice = input("\nSelect option: ").strip()
        
        if choice == "1":
            print("\n🧪 TEST MODE: Processing first 10 exercises")
            extractor.process_batch(0, 10)
            
        elif choice == "2":
            try:
                start = int(input("Start index (0-based): "))
                count = int(input("Number of exercises to process: "))
                extractor.process_batch(start, count)
            except ValueError:
                print("❌ Please enter valid numbers")
                
        elif choice == "3":
            exercise_id = input("Enter exercise ID: ").strip()
            extractor.analyze_specific_exercise(exercise_id)
            
        elif choice == "4":
            # Find where to continue
            existing_csvs = len([f for f in os.listdir(extractor.angles_dir) if f.endswith('.csv')])
            print(f"📁 Found {existing_csvs} existing CSV files")
            
            count = input(f"Process next batch from index {existing_csvs} (how many?): ")
            try:
                extractor.process_batch(existing_csvs, int(count))
            except ValueError:
                print("❌ Please enter a valid number")
                
        elif choice == "5":
            print("👋 Goodbye!")
            break
            
        else:
            print("❌ Invalid option. Please choose 1-5.")


if __name__ == "__main__":
    main()
