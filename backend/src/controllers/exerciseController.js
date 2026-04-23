const fs = require('fs');
const path = require('path');

// Load exercises database
const exercisesPath = process.env.EXERCISES_DB_PATH || path.join(__dirname, '../../ai-planner/data/exercises.json');
let exercisesDB = null;

function loadExercises() {
  if (!exercisesDB) {
    try {
      const data = fs.readFileSync(exercisesPath, 'utf8');
      exercisesDB = JSON.parse(data);
      console.log(`✅ Loaded ${exercisesDB.length} exercises from database`);
    } catch (error) {
      console.error('Error loading exercises database:', error);
      exercisesDB = [];
    }
  }
  return exercisesDB;
}

/**
 * Search for exercise by name
 * GET /api/v1/exercises/search?name=bench+press
 */
exports.searchExercise = async (req, res) => {
  try {
    const { name } = req.query;
    
    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Exercise name is required'
      });
    }
    
    const exercises = loadExercises();
    const searchTerm = name.toLowerCase().trim();
    
    // Find exact or partial match
    const match = exercises.find(ex => 
      ex.name.toLowerCase() === searchTerm ||
      ex.name.toLowerCase().includes(searchTerm)
    );
    
    if (match) {
      res.status(200).json({
        success: true,
        data: {
          exercise: {
            name: match.name,
            gifUrl: match.gifUrl,
            targetMuscles: match.targetMuscles,
            bodyParts: match.bodyParts,
            equipments: match.equipments,
            secondaryMuscles: match.secondaryMuscles,
            instructions: match.instructions
          }
        }
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'Exercise not found'
      });
    }
    
  } catch (error) {
    console.error('Error searching exercise:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search exercise',
      error: error.message
    });
  }
};

/**
 * Get all exercises
 * GET /api/v1/exercises
 */
exports.getAllExercises = async (req, res) => {
  try {
    const exercises = loadExercises();
    const { limit = 50, offset = 0, equipment, bodyPart } = req.query;
    
    let filtered = exercises;
    
    // Filter by equipment
    if (equipment) {
      filtered = filtered.filter(ex => 
        ex.equipments.some(eq => eq.toLowerCase().includes(equipment.toLowerCase()))
      );
    }
    
    // Filter by body part
    if (bodyPart) {
      filtered = filtered.filter(ex => 
        ex.bodyParts.some(bp => bp.toLowerCase().includes(bodyPart.toLowerCase()))
      );
    }
    
    // Paginate
    const start = parseInt(offset);
    const end = start + parseInt(limit);
    const paginated = filtered.slice(start, end);
    
    res.status(200).json({
      success: true,
      data: {
        exercises: paginated.map(ex => ({
          id: ex.exerciseId,
          name: ex.name,
          gifUrl: ex.gifUrl,
          targetMuscles: ex.targetMuscles,
          equipments: ex.equipments,
          bodyParts: ex.bodyParts
        })),
        total: filtered.length,
        offset: start,
        limit: parseInt(limit)
      }
    });
    
  } catch (error) {
    console.error('Error getting exercises:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get exercises',
      error: error.message
    });
  }
};
