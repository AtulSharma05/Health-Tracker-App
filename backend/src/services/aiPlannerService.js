const { spawn } = require('child_process');
const path = require('path');

/**
 * AI Workout Planner Service
 * Communicates with Python-based AI planner to generate personalized workout plans
 */
class AIPlannerService {
  constructor() {
    this.pythonPath = process.env.AI_PYTHON_PATH || 'python';
    this.apiServerPath = process.env.AI_API_SERVER_PATH || path.join(__dirname, '../../ai-planner/api_server.py');
    this.apiPort = Number(process.env.AI_PLANNER_PORT || 8000);
    this.apiUrl = process.env.AI_PLANNER_URL || `http://localhost:${this.apiPort}`;
    this.defaultTimeoutMs = Number(process.env.AI_PLANNER_TIMEOUT_MS || 30000);
  }

  /**
   * Generate a personalized workout plan
   * @param {Object} params - User parameters
   * @param {string} params.goal - Fitness goal (e.g., "muscle gain", "weight loss", "general fitness")
   * @param {string} params.experience - Experience level ("beginner", "intermediate", "advanced")
   * @param {number} params.daysPerWeek - Number of workout days per week (1-7)
   * @param {string[]} params.equipment - Available equipment
   * @param {string[]} params.targetMuscles - Target muscle groups
   * @param {number} params.duration - Workout duration in minutes
   * @returns {Promise<Object>} Generated workout plan
   */
  async generateWorkoutPlan(params) {
    try {
      // Convert structured parameters to natural language for Python API
      const message = this._buildMessage(params);
      
      const response = await this.callPythonAPI('/plan', {
        method: 'POST',
        body: JSON.stringify({
          message: message,
          weeks: 4,
          use_natural_language: false  // Get structured data
        }),
        headers: { 'Content-Type': 'application/json' }
      });
      
      // Parse structured workout data
      const workoutDays = this._parseStructuredPlan(response, params);
      
      return {
        ...params,
        plan: response.plan,
        days: workoutDays,
        createdAt: new Date().toISOString()
      };
    } catch (error) {
      console.error('Error generating workout plan:', error);
      throw new Error('Failed to generate workout plan');
    }
  }

  /**
   * Parse structured plan data from Python API
   * @private
   */
  _parseStructuredPlan(response, params) {
    const structuredData = response.structured_data;
    if (!structuredData || structuredData.length === 0) return [];
    
    const weekData = structuredData[0]; // Use first week (7 days)
    const days = [];
    
    // Always show all 7 days of the week
    for (let dayNum = 1; dayNum <= 7; dayNum++) {
      const exercises = weekData[dayNum] || [];
      
      if (exercises.length > 0) {
        // Training day
        const formattedExercises = exercises.map(([name, details]) => ({
          name: name,
          sets: details.sets || 3,
          reps: details.reps || 10,
          rest: details.rest_seconds || 60,
        }));
        
        days.push({
          dayNumber: dayNum,
          focus: this._getDayFocus(formattedExercises),
          exercises: formattedExercises,
          estimatedDuration: params.duration || 60
        });
      } else {
        // Rest day
        days.push({
          dayNumber: dayNum,
          focus: 'Rest',
          exercises: [],
          estimatedDuration: 0
        });
      }
    }
    
    return days;
  }

  /**
   * Determine day focus from exercises
   * @private
   */
  _getDayFocus(exercises) {
    // Simple heuristic - can be improved
    return exercises.length > 0 ? 'Workout' : 'Rest';
  }

  /**
   * Build natural language message from structured params
   * @private
   */
  _buildMessage(params) {
    const {goal, experience, daysPerWeek, equipment, targetMuscles, duration} = params;
    
    const goalText = {
      'muscle_gain': 'build muscle',
      'weight_loss': 'lose weight',
      'general_fitness': 'improve general fitness'
    }[goal] || goal;
    
    let msg = `I am a ${experience} level person looking to ${goalText}. `;
    msg += `I can work out ${daysPerWeek} days per week. `;
    
    // Add duration if specified
    if (duration) {
      msg += `Each workout should be ${duration} minutes. `;
    }
    
    if (equipment && equipment.length > 0) {
      msg += `I have access to: ${equipment.join(', ')}. `;
    }
    
    if (targetMuscles && targetMuscles.length > 0) {
      msg += `I want to focus on: ${targetMuscles.join(', ')}.`;
    }
    
    return msg;
  }

  /**
   * Get exercise recommendations based on criteria
   * @param {Object} criteria - Search criteria
   * @returns {Promise<Array>} List of recommended exercises
   */
  async getExerciseRecommendations(criteria) {
    try {
      // Use parse endpoint to get profile, then return generic recommendations
      const message = `Looking for ${criteria.muscleGroup || 'all'} exercises`;
      if (criteria.equipment) message += ` using ${criteria.equipment}`;
      
      // For now, return mock data as Python API doesn't have this specific endpoint
      return {
        exercises: [
          { name: 'Bench Press', equipment: 'Barbell', muscleGroup: 'Chest' },
          { name: 'Squat', equipment: 'Barbell', muscleGroup: 'Legs' },
          { name: 'Deadlift', equipment: 'Barbell', muscleGroup: 'Back' }
        ].filter(ex => 
          (!criteria.muscleGroup || ex.muscleGroup === criteria.muscleGroup) &&
          (!criteria.equipment || ex.equipment === criteria.equipment)
        ).slice(0, criteria.limit || 10)
      };
    } catch (error) {
      console.error('Error getting exercise recommendations:', error);
      throw new Error('Failed to get exercise recommendations');
    }
  }

  /**
   * Predict optimal sets and reps for an exercise
   * @param {Object} params - Exercise parameters
   * @returns {Promise<Object>} Predicted sets/reps
   */
  async predictSetsReps(params) {
    try {
      const response = await this.callPythonAPI('/predict-sets', {
        method: 'POST',
        body: JSON.stringify(params),
        headers: { 'Content-Type': 'application/json' }
      });
      
      return response;
    } catch (error) {
      console.error('Error predicting sets/reps:', error);
      throw new Error('Failed to predict sets/reps');
    }
  }

  /**
   * Call Python API endpoint
   * @private
   */
  async callPythonAPI(endpoint, options = {}) {
    const url = `${this.apiUrl}${endpoint}`;

    const response = await this._fetchWithTimeout(url, options, this.defaultTimeoutMs);
    
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Python API error: ${error}`);
    }
    
    return await response.json();
  }

  /**
   * Check if Python AI server is running
   * @returns {Promise<boolean>}
   */
  async isServerRunning() {
    try {
      const response = await this._fetchWithTimeout(`${this.apiUrl}/health`, {}, 5000);
      return response.ok;
    } catch (error) {
      return false;
    }
  }

  async _fetchWithTimeout(url, options = {}, timeoutMs = this.defaultTimeoutMs) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      return await fetch(url, {
        ...options,
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timer);
    }
  }

  /**
   * Start Python AI server (if not running)
   * Note: In production, run this as a separate service
   */
  startPythonServer() {
    return new Promise((resolve, reject) => {
      const pythonProcess = spawn(this.pythonPath, [this.apiServerPath]);
      
      pythonProcess.stdout.on('data', (data) => {
        console.log(`Python AI Server: ${data}`);
        if (data.toString().includes('Running on')) {
          resolve();
        }
      });
      
      pythonProcess.stderr.on('data', (data) => {
        console.error(`Python AI Server Error: ${data}`);
      });
      
      pythonProcess.on('error', (error) => {
        console.error('Failed to start Python AI server:', error);
        reject(error);
      });
      
      // Store process reference for cleanup
      this.pythonProcess = pythonProcess;
      
      // Timeout after 30 seconds
      setTimeout(() => {
        reject(new Error('Python server start timeout'));
      }, 30000);
    });
  }

  /**
   * Stop Python AI server
   */
  stopPythonServer() {
    if (this.pythonProcess) {
      this.pythonProcess.kill();
      this.pythonProcess = null;
    }
  }
}

module.exports = new AIPlannerService();
