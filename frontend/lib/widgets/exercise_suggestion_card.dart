import 'package:flutter/material.dart';

class ExerciseSuggestionCard extends StatelessWidget {
  final String exerciseId;
  final String exerciseName;
  final VoidCallback onStart;

  const ExerciseSuggestionCard({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.onStart,
  });

  /// Parse exercise suggestion from AI message
  /// Format: [EXERCISE:exercise-id] text...
  static ExerciseSuggestion? parseFromMessage(String content) {
    final regex = RegExp(r'\[EXERCISE:([^\]]+)\]');
    final match = regex.firstMatch(content);
    
    if (match != null) {
      final exerciseId = match.group(1)!;
      
      // Map exercise IDs to display names
      final Map<String, String> exerciseNames = {
        'active-listening': 'Active Listening Practice',
        'appreciation-share': 'Appreciation Share',
        'conflict-deescalation': 'Conflict De-escalation',
        'emotional-checkin': 'Emotional Check-in',
        'empathy-swap': 'Empathy Swap',
        'repair-conversation': 'Repair Conversation',
        'needs-and-boundaries': 'Needs & Boundaries',
        'rose-thorn-bud': 'Rose, Thorn & Bud',
        'dream-sharing': 'Dream Sharing',
        'gratitude-letter': 'Gratitude Letter',
      };
      
      final exerciseName = exerciseNames[exerciseId] ?? exerciseId;
      
      return ExerciseSuggestion(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        cleanContent: content.replaceAll(regex, '').trim(),
      );
    }
    
    return null;
  }

  IconData _getExerciseIcon() {
    switch (exerciseId) {
      case 'active-listening':
        return Icons.hearing;
      case 'appreciation-share':
        return Icons.favorite;
      case 'conflict-deescalation':
        return Icons.healing;
      case 'emotional-checkin':
        return Icons.mood;
      case 'empathy-swap':
        return Icons.swap_horiz;
      case 'repair-conversation':
        return Icons.handshake;
      case 'needs-and-boundaries':
        return Icons.shield_outlined;
      case 'rose-thorn-bud':
        return Icons.local_florist;
      case 'dream-sharing':
        return Icons.auto_awesome;
      case 'gratitude-letter':
        return Icons.mail_outline;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getExerciseColor(BuildContext context) {
    switch (exerciseId) {
      case 'active-listening':
        return Colors.blue;
      case 'appreciation-share':
        return Colors.pink;
      case 'conflict-deescalation':
        return Colors.orange;
      case 'emotional-checkin':
        return Colors.teal;
      case 'empathy-swap':
        return Colors.deepPurple;
      case 'repair-conversation':
        return Colors.indigo;
      case 'needs-and-boundaries':
        return Colors.amber.shade700;
      case 'rose-thorn-bud':
        return Colors.green;
      case 'dream-sharing':
        return Colors.purple;
      case 'gratitude-letter':
        return Colors.red.shade400;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getExerciseColor(context);
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onStart,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getExerciseIcon(),
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎯 Guided Exercise',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exerciseName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to start the guided exercise',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_filled,
                  color: color,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for parsed exercise suggestion
class ExerciseSuggestion {
  final String exerciseId;
  final String exerciseName;
  final String cleanContent;

  ExerciseSuggestion({
    required this.exerciseId,
    required this.exerciseName,
    required this.cleanContent,
  });
}
