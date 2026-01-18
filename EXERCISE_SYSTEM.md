# Guided Exercise System

## Overview

The guided exercise system allows couples to practice communication skills through structured, AI-facilitated exercises. Exercises are **optional** and integrate seamlessly with the main conversation flow.

## Features

### ✨ Key Benefits
- **Structured Practice**: Step-by-step guidance for specific skills
- **Non-intrusive**: Optional suggestions, never forced
- **AI-Generated Summaries**: Automatic insights after completion
- **Progress Tracking**: Save progress and continue later
- **Personalized**: Uses partner names throughout

### 🎯 Available Exercises

1. **Active Listening Practice** (15 min)
   - Practice truly hearing each other
   - Take turns speaking and reflecting
   - Build empathy and understanding

2. **Appreciation Share** (10 min)
   - Share specific appreciations
   - Practice receiving gratitude
   - Build positivity

3. **Conflict De-escalation** (20 min)
   - Slow down heated moments
   - Identify underlying feelings
   - Find shared needs

## Architecture

### Backend

#### Database Tables

**exercises**
- `exerciseId` (PK): Exercise identifier
- `name`: Exercise name
- `description`: What the exercise does
- `category`: communication | appreciation | conflict
- `duration`: Estimated time in minutes
- `steps`: JSON array of exercise steps
- `isActive`: Whether available

**exercise-sessions**
- `sessionId` (PK): Unique session identifier
- `coupleId`: Couple performing exercise
- `conversationId`: Where exercise is happening
- `exerciseId`: Exercise template
- `status`: active | completed | abandoned
- `currentStep`: Current step number
- `progress`: JSON tracking responses
- `summary`: AI-generated after completion
- `startedAt`, `completedAt`, `createdAt`

#### API Endpoints

```
GET    /api/exercises                          # List available exercises
POST   /api/exercises/start                    # Start an exercise
POST   /api/exercises/:sessionId/progress      # Submit step response
GET    /api/exercises/:sessionId/summary       # Get completion summary
GET    /api/exercises/active/:conversationId   # Get active session
```

#### Exercise Service

**Location**: `backend/src/services/exerciseService.js`

**Key Functions**:
- `startExercise()` - Create new session
- `progressExercise()` - Move to next step
- `getExercises()` - List templates
- `getActiveSession()` - Check for active exercise

### Frontend

#### Services

**ExerciseService** (`lib/services/exercise_service.dart`)
- Handles all exercise API calls
- Manages session state

#### Screens

**ExerciseScreen** (`lib/screens/exercises/exercise_screen.dart`)
- Full-screen exercise interface
- Step-by-step progression
- Progress indicator
- Completion view with summary

#### Widgets

**ExerciseSelectionDialog** (`lib/widgets/exercise_selection_dialog.dart`)
- Browse available exercises
- Shows duration and category
- Start exercise flow

**ExerciseButton** (`lib/widgets/exercise_button.dart`)
- Call-to-action in main thread
- Shows "Continue" if exercise active
- Shows "Try Exercise" if none active

## User Flow

### Starting an Exercise

1. **AI Suggestion** (optional)
   ```
   "Would you like to try the Active Listening Practice 
   exercise? I can guide you through it step-by-step."
   ```

2. **Manual Selection**
   - User clicks "Try a Guided Exercise" button
   - Dialog shows available exercises
   - User selects an exercise

3. **Exercise Begins**
   - Full-screen exercise view opens
   - Shows step 1 with instruction, guidance, prompt
   - Progress bar at top

### Progressing Through Steps

1. User reads instruction and guidance
2. User responds to prompt
3. System saves response and loads next step
4. Repeat until all steps complete

### Completion

1. Exercise marked as completed
2. AI generates summary with:
   - What they practiced
   - Key insights
   - Encouragement
3. Summary displayed
4. User returns to main thread
5. Summary can be posted to conversation (optional)

## Integration with Main Conversation

### Conversation View Updates

Add to your conversation screen:

```dart
import '../widgets/exercise_button.dart';
import '../widgets/exercise_selection_dialog.dart';
import '../screens/exercises/exercise_screen.dart';

// Check for active exercise on load
Map<String, dynamic>? _activeExercise;

@override
void initState() {
  super.initState();
  _checkForActiveExercise();
}

Future<void> _checkForActiveExercise() async {
  final token = ref.read(authProvider).token;
  final session = await ExerciseService().getActiveSession(
    token: token!,
    conversationId: widget.conversationId,
  );
  
  setState(() {
    _activeExercise = session;
  });
}

// Add button in your ListView
ExerciseButton(
  hasActiveExercise: _activeExercise != null,
  onPressed: () {
    if (_activeExercise != null) {
      // Continue existing exercise
      _openExercise(_activeExercise!);
    } else {
      // Show exercise selection
      showDialog(
        context: context,
        builder: (context) => ExerciseSelectionDialog(
          conversationId: widget.conversationId,
          onExerciseStarted: (session, exercise) {
            _openExercise(session, exercise);
          },
        ),
      );
    }
  },
)

void _openExercise(Map<String, dynamic> session, [Map<String, dynamic>? exercise]) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ExerciseScreen(
        conversationId: widget.conversationId,
        session: session,
        exercise: exercise ?? _buildExerciseFromSession(session),
        onComplete: () {
          Navigator.pop(context);
          _checkForActiveExercise(); // Refresh
        },
      ),
    ),
  );
}
```

### AI Prompt Guidelines

The AI coach is configured to:
- **NOT suggest exercises in first 1-2 messages** (build rapport first)
- Suggest exercises when couples are stuck or need practice
- Frame as optional: "Would you like to try..."
- Continue conversation normally if declined

## Testing

### Backend Tests

```bash
# Test exercise routes
curl -X GET http://localhost:3001/api/exercises \
  -H "Authorization: Bearer $TOKEN"

# Start exercise
curl -X POST http://localhost:3001/api/exercises/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"conversationId":"xxx","exerciseId":"active-listening"}'
```

### Frontend Testing

1. Create test user couple
2. Open main conversation
3. Click "Try a Guided Exercise"
4. Select "Active Listening Practice"
5. Complete all 6 steps
6. Verify summary generation
7. Return to conversation

## Configuration

### Adding New Exercises

Edit `backend/src/services/exerciseService.js`:

```javascript
EXERCISE_TEMPLATES['your-exercise-id'] = {
  exerciseId: 'your-exercise-id',
  name: 'Your Exercise Name',
  description: 'What it does',
  category: 'communication', // or appreciation, conflict
  duration: 15,
  steps: [
    {
      stepNumber: 1,
      instruction: '@{partner1}, do something...',
      guidance: 'How to do it well',
      prompt: 'What would you like to share?'
    },
    // ... more steps
  ]
}
```

**Note**: Use `{partner1}` and `{partner2}` placeholders - they're auto-replaced with actual names.

## Future Enhancements

- [ ] Exercise categories filter
- [ ] Exercise history/completion tracking
- [ ] Custom couple-specific exercises
- [ ] Audio/video guidance
- [ ] Exercise reminders/scheduling
- [ ] Achievement badges for completions
- [ ] Export summaries as PDF

## Monitoring

Track these metrics:
- Exercise completion rate
- Average time per exercise
- Most popular exercises
- Dropout points (which steps)
- Summary satisfaction

## Support

For issues or questions:
- Backend: Check logs for exercise route errors
- Frontend: Verify ExerciseService API calls
- AI: Review prompt in aiService.js for exercise suggestions
