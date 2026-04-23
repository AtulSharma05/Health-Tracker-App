"""
Exercise Utilities
Contains utility functions for exercise tracking with MediaPipe.
"""

import cv2
import numpy as np
import mediapipe as mp


def initialize_pose_detection(min_detection_confidence=0.5, min_tracking_confidence=0.5):
    """
    Initialize the MediaPipe Pose detection model.
    
    Args:
        min_detection_confidence: Minimum confidence for detection
        min_tracking_confidence: Minimum confidence for tracking
        
    Returns:
        tuple: MediaPipe pose module and model
    """
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(
        min_detection_confidence=min_detection_confidence,
        min_tracking_confidence=min_tracking_confidence
    )
    return mp_pose, pose


def detect_landmarks(pose, image):
    """
    Process an image with MediaPipe Pose to detect pose landmarks.
    
    Args:
        pose: MediaPipe pose model
        image: RGB image to process
        
    Returns:
        MediaPipe pose detection results
    """
    return pose.process(image)


def calculate_angle(a, b, c):
    """
    Calculate the angle between three points.
    
    Args:
        a: First point coordinates [x, y]
        b: Middle point coordinates [x, y] (vertex of the angle)
        c: End point coordinates [x, y]
        
    Returns:
        angle: Angle in degrees
    """
    if a is None or b is None or c is None:
        return None
        
    a = np.array(a)  # First
    b = np.array(b)  # Mid
    c = np.array(c)  # End
    
    radians = np.arctan2(c[1] - b[1], c[0] - b[0]) - np.arctan2(a[1] - b[1], a[0] - b[0])
    angle = np.abs(radians * 180.0 / np.pi)
    
    if angle > 180.0:
        angle = 360 - angle
        
    return angle


def calculate_distance(a, b):
    """
    Calculate Euclidean distance between two points.
    
    Args:
        a: First point coordinates [x, y]
        b: Second point coordinates [x, y]
        
    Returns:
        distance: Euclidean distance
    """
    if a is None or b is None:
        return None
        
    a = np.array(a)
    b = np.array(b)
    return np.sqrt(np.sum((a - b) ** 2))


def extract_landmarks(results, mp_pose):
    """
    Extract all relevant landmarks for exercise tracking.
    
    Args:
        results: MediaPipe pose detection results
        mp_pose: MediaPipe pose solution
        
    Returns:
        dict: Dictionary containing all joint coordinates
    """
    landmarks_dict = {}
    
    try:
        if not results.pose_landmarks:
            return None
            
        landmarks = results.pose_landmarks.landmark
        
        # Define list of landmarks to extract
        joints = [
            # Face landmarks
            ("nose", mp_pose.PoseLandmark.NOSE),
            
            # Upper body landmarks
            ("left_shoulder", mp_pose.PoseLandmark.LEFT_SHOULDER),
            ("right_shoulder", mp_pose.PoseLandmark.RIGHT_SHOULDER),
            ("left_elbow", mp_pose.PoseLandmark.LEFT_ELBOW),
            ("right_elbow", mp_pose.PoseLandmark.RIGHT_ELBOW),
            ("left_wrist", mp_pose.PoseLandmark.LEFT_WRIST),
            ("right_wrist", mp_pose.PoseLandmark.RIGHT_WRIST),
            
            # Torso landmarks
            ("left_hip", mp_pose.PoseLandmark.LEFT_HIP),
            ("right_hip", mp_pose.PoseLandmark.RIGHT_HIP),
            
            # Lower body landmarks
            ("left_knee", mp_pose.PoseLandmark.LEFT_KNEE),
            ("right_knee", mp_pose.PoseLandmark.RIGHT_KNEE),
            ("left_ankle", mp_pose.PoseLandmark.LEFT_ANKLE),
            ("right_ankle", mp_pose.PoseLandmark.RIGHT_ANKLE),
            ("left_heel", mp_pose.PoseLandmark.LEFT_HEEL),
            ("right_heel", mp_pose.PoseLandmark.RIGHT_HEEL),
            ("left_foot_index", mp_pose.PoseLandmark.LEFT_FOOT_INDEX),
            ("right_foot_index", mp_pose.PoseLandmark.RIGHT_FOOT_INDEX)
        ]
        
        # Extract coordinates for each joint
        for name, landmark_enum in joints:
            landmark = landmarks[landmark_enum.value]
            if landmark.visibility > 0.5:  # Only use visible landmarks
                landmarks_dict[name] = [landmark.x, landmark.y, landmark.z, landmark.visibility]
            else:
                landmarks_dict[name] = None
        
    except Exception as e:
        print(f"Error extracting landmarks: {e}")
        return None
        
    return landmarks_dict


def draw_landmarks(image, results, mp_pose):
    """
    Draw pose landmarks and connections on an image.
    
    Args:
        image: BGR image to draw on
        results: MediaPipe pose results
        mp_pose: MediaPipe pose module
        
    Returns:
        image: Image with landmarks drawn
    """
    mp_drawing = mp.solutions.drawing_utils
    mp_drawing_styles = mp.solutions.drawing_styles
    
    # Draw the pose landmarks
    mp_drawing.draw_landmarks(
        image,
        results.pose_landmarks,
        mp_pose.POSE_CONNECTIONS,
        landmark_drawing_spec=mp_drawing_styles.get_default_pose_landmarks_style())
    
    return image


def draw_exercise_status(image, exercise_name, counter, stage, form_feedback=None):
    """
    Draw exercise status information on image.
    
    Args:
        image: OpenCV image to draw on
        exercise_name: Name of the current exercise
        counter: Rep count
        stage: Current exercise stage
        form_feedback: Feedback on exercise form
        
    Returns:
        image: Image with exercise status information drawn
    """
    # Setup status box
    cv2.rectangle(image, (0, 0), (320, 80), (245, 117, 16), -1)
    
    # Exercise name
    cv2.putText(image, exercise_name, (10, 25),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2, cv2.LINE_AA)
    
    # Rep data
    cv2.putText(image, 'REPS', (15, 50),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 1, cv2.LINE_AA)
    cv2.putText(image, str(counter), (10, 80),
                cv2.FONT_HERSHEY_SIMPLEX, 2, (255, 255, 255), 2, cv2.LINE_AA)
    
    # Stage data
    cv2.putText(image, 'STAGE', (100, 50),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 1, cv2.LINE_AA)
    cv2.putText(image, str(stage) if stage else '', (100, 80),
                cv2.FONT_HERSHEY_SIMPLEX, 1.5, (255, 255, 255), 2, cv2.LINE_AA)
    
    # Form feedback (if provided)
    if form_feedback:
        # Additional feedback box for form
        cv2.rectangle(image, (0, image.shape[0]-60), (image.shape[1], image.shape[0]), (0, 0, 0), -1)
        cv2.putText(image, form_feedback, (10, image.shape[0]-20),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2, cv2.LINE_AA)
    
    return image


def visualize_angles(image, landmarks, angles, dimensions=(640, 480)):
    """
    Visualize angles between joints on the image.
    
    Args:
        image: OpenCV image to draw on
        landmarks: Dictionary of landmark coordinates
        angles: Dictionary of angle names and their corresponding 3 landmarks
        dimensions: Image dimensions (width, height)
        
    Returns:
        image: Image with angles drawn
    """
    for angle_name, (point1, point2, point3) in angles.items():
        # Get the landmarks
        p1 = landmarks.get(point1)
        p2 = landmarks.get(point2)  # This is the vertex of the angle
        p3 = landmarks.get(point3)
        
        # Calculate angle if all points are available
        if p1 and p2 and p3:
            # Extract x, y coordinates
            p1_coords = p1[:2]
            p2_coords = p2[:2]
            p3_coords = p3[:2]
            
            # Calculate angle
            angle = calculate_angle(p1_coords, p2_coords, p3_coords)
            
            # Convert normalized coordinates to pixel coordinates for display
            pixel_coords = tuple(np.multiply(p2_coords, dimensions).astype(int))
            
            # Draw angle
            cv2.putText(image, f"{int(angle)}", pixel_coords,
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2, cv2.LINE_AA)
    
    return image


def draw_landmarks(image, results, mp_pose):
    """
    Draw pose landmarks and connections on an image.
    
    Args:
        image: BGR image to draw on
        results: MediaPipe pose results
        mp_pose: MediaPipe pose module
        
    Returns:
        image: Image with landmarks drawn
    """
    mp_drawing = mp.solutions.drawing_utils
    mp_drawing_styles = mp.solutions.drawing_styles
    
    # Draw the pose landmarks
    mp_drawing.draw_landmarks(
        image,
        results.pose_landmarks,
        mp_pose.POSE_CONNECTIONS,
        landmark_drawing_spec=mp_drawing_styles.get_default_pose_landmarks_style())
    
    return image
