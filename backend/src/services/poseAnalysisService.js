const fs = require('fs');
const path = require('path');

class PoseAnalysisService {
  constructor() {
    this.poseApiUrl = process.env.POSE_API_URL || 'http://localhost:8001';
    this.exerciseMappingPath = process.env.POSE_EXERCISE_MAPPING_PATH || path.join(__dirname, '../../pose-corrector/data/exercise_id_mapping.json');
    this.exerciseMapping = null;
    this.loadExerciseMapping();
  }

  /**
   * Load exercise ID mapping from file
   */
  loadExerciseMapping() {
    try {
      if (fs.existsSync(this.exerciseMappingPath)) {
        const data = fs.readFileSync(this.exerciseMappingPath, 'utf8');
        const mappingData = JSON.parse(data);
        this.exerciseMapping = mappingData.mapping || {};
        console.log(`✅ Loaded ${Object.keys(this.exerciseMapping).length} exercise mappings`);
      } else {
        console.warn('⚠️  Exercise mapping file not found. Run create_exercise_mapping.py first.');
        this.exerciseMapping = {};
      }
    } catch (error) {
      console.error('❌ Error loading exercise mapping:', error.message);
      this.exerciseMapping = {};
    }
  }

  /**
   * Get exercise ID from exercise name
   * @param {string} exerciseName - Name of the exercise
   * @returns {string|null} Exercise ID or null if not found
   */
  getExerciseId(exerciseName) {
    if (!exerciseName) return null;
    
    const normalized = exerciseName.toLowerCase().trim();
    
    // Direct match
    if (this.exerciseMapping[normalized]) {
      return this.exerciseMapping[normalized];
    }
    
    // Fuzzy match - check if any key contains the search term
    const matchingKeys = Object.keys(this.exerciseMapping).filter(key => 
      key.includes(normalized) || normalized.includes(key)
    );
    
    if (matchingKeys.length > 0) {
      // Return the first match
      return this.exerciseMapping[matchingKeys[0]];
    }
    
    return null;
  }

  /**
   * Check if Pose API is available
   * @returns {Promise<boolean>}
   */
  async checkPoseApiHealth() {
    try {
      const response = await this._fetchJson(`${this.poseApiUrl}/health`, { timeoutMs: 3000 });
      return response.status === 'healthy' || response.status === 'available';
    } catch (error) {
      console.error('❌ Pose API health check failed:', error.message);
      return false;
    }
  }

  /**
   * Start a new exercise session
   * @param {string} exerciseName - Name of the exercise
   * @returns {Promise<Object>} Session details
   */
  async startExerciseSession(exerciseName) {
    try {
      const exerciseId = this.getExerciseId(exerciseName);
      
      if (!exerciseId) {
        throw new Error(`Exercise "${exerciseName}" not found in pose tracking database`);
      }

      const response = await this._fetchJson(`${this.poseApiUrl}/api/start-exercise`, {
        method: 'POST',
        body: { exercise_id: exerciseId },
      });

      return {
        success: true,
        exerciseId: exerciseId,
        exerciseName: response.exercise_name,
        message: response.message,
        websocketUrl: `ws://${this.poseApiUrl.replace('http://', '').replace('https://', '')}/ws/pose-analysis`
      };
    } catch (error) {
      console.error('❌ Error starting exercise session:', error.message);
      throw error;
    }
  }

  /**
   * Get session summary
   * @returns {Promise<Object>} Session statistics
   */
  async getSessionSummary() {
    try {
      const response = await this._fetchJson(`${this.poseApiUrl}/api/session-summary`);
      return response.data;
    } catch (error) {
      console.error('❌ Error getting session summary:', error.message);
      throw error;
    }
  }

  /**
   * Reset the current session
   * @returns {Promise<Object>}
   */
  async resetSession() {
    try {
      const response = await this._fetchJson(`${this.poseApiUrl}/api/reset`, { method: 'POST' });
      return {
        success: true,
        message: response.message
      };
    } catch (error) {
      console.error('❌ Error resetting session:', error.message);
      throw error;
    }
  }

  /**
   * Search for exercises in the database
   * @param {string} searchTerm - Search term
   * @returns {Array} Matching exercises
   */
  searchExercises(searchTerm) {
    if (!searchTerm) return [];
    
    const normalized = searchTerm.toLowerCase().trim();
    const matches = [];
    
    for (const [exerciseName, exerciseId] of Object.entries(this.exerciseMapping)) {
      if (exerciseName.includes(normalized)) {
        matches.push({
          name: exerciseName,
          id: exerciseId
        });
      }
    }
    
    // Limit to 20 results
    return matches.slice(0, 20);
  }

  /**
   * Get all available exercises with pose tracking
   * @returns {Array} List of all exercises
   */
  getAllExercises() {
    return Object.entries(this.exerciseMapping).map(([name, id]) => ({
      name,
      id
    }));
  }

  async _fetchJson(url, { method = 'GET', body, timeoutMs = 5000 } = {}) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetch(url, {
        method,
        headers: body ? { 'Content-Type': 'application/json' } : undefined,
        body: body ? JSON.stringify(body) : undefined,
        signal: controller.signal,
      });

      if (!response.ok) {
        const text = await response.text();
        throw new Error(`Pose API error (${response.status}): ${text}`);
      }

      return await response.json();
    } finally {
      clearTimeout(timer);
    }
  }
}

module.exports = new PoseAnalysisService();
