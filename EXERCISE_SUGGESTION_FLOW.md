# Exercise Suggestion Integration

## How It Works

The AI coach can suggest guided exercises within the conversation flow using special markers that the frontend detects and converts into interactive buttons.

## Backend: AI Prompt Format

The AI is instructed to use this exact format when suggesting exercises:

```
[EXERCISE:exercise-id] Would you like to try the **Exercise Name** exercise? 
I can guide you through it step-by-step right here. It takes about 15 minutes.
```

### Available Exercise IDs

- `active-listening` - Active Listening Practice
- `appreciation-share` - Appreciation Share  
- `conflict-deescalation` - Conflict De-escalation

### Example AI Response

```
💭 @John and @Jane, I'm hearing that you both want to feel understood 
but the conversations keep escalating. 

[EXERCISE:active-listening] Would you like to try the **Active Listening 
Practice** exercise? I can guide you through it step-by-step right here. 
It takes about 15 minutes and helps you really hear each other without 
interruption or judgment.

🤔 Or if you prefer, we can keep talking and I can help you navigate 
this conversation together.
```

## Frontend: Detection & Display

### 1. MessageBubble Widget

The `MessageBubble` widget automatically:
- Detects `[EXERCISE:id]` markers in AI messages
- Strips the marker from displayed content
- Shows an `ExerciseSuggestionCard` below the message

### 2. ExerciseSuggestionCard

Visual card with:
- Exercise icon (based on type)
- Exercise name
- "Tap to start" instruction
- Colored border matching exercise category

### 3. Integration

In your conversation screen, pass the callback to `MessageBubble`:

```dart
MessageBubble(
  message: message,
  isCurrentUser: message.senderId == currentUserId,
  onExerciseSuggestion: (exerciseId) async {
    // Start the exercise
    final token = ref.read(authProvider).token;
    final result = await ExerciseService().startExercise(
      token: token!,
      conversationId: conversationId,
      exerciseId: exerciseId,
    );
    
    // Navigate to exercise screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(
          conversationId: conversationId,
          session: result['session'],
          exercise: result['exercise'],
          onComplete: () {
            Navigator.pop(context);
            // Optionally refresh conversation
          },
        ),
      ),
    );
  },
)
```

## User Flow

1. **AI Suggests Exercise**: Coach detects a good moment and suggests an exercise using `[EXERCISE:id]` marker
2. **User Sees Card**: Message displays with an interactive exercise card below
3. **User Taps Card**: Starts the exercise via `onExerciseSuggestion` callback
4. **Exercise Launches**: Full-screen guided exercise opens
5. **User Completes**: Returns to conversation, summary can be shared

## Advantages

✅ **Seamless** - Exercises suggested naturally in conversation  
✅ **Optional** - User can ignore and continue chatting  
✅ **Clear** - Visual card makes it obvious what will happen  
✅ **Context-aware** - AI suggests at appropriate moments  
✅ **No Interruption** - Doesn't break conversation flow  

## Testing

1. Start a conversation with sensitive topic (conflict, communication issues)
2. After 2-3 messages, AI may suggest an exercise
3. You should see a colored card below the AI message
4. Tap card to launch exercise
5. Complete exercise and return to conversation

## Troubleshooting

**Exercise card not showing?**
- Check AI message contains `[EXERCISE:id]` marker
- Verify `onExerciseSuggestion` callback is passed to `MessageBubble`
- Check exerciseId matches available exercises

**Exercise won't start?**
- Verify backend `/api/exercises/start` endpoint is working
- Check authentication token is valid
- Verify conversation access permissions

## Future Enhancements

- Track which exercises have been completed
- Don't suggest same exercise twice in short period
- Allow users to browse and start exercises manually
- Show exercise completion badges in conversation
