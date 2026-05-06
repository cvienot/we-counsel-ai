import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/exercise_service.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class ExerciseSelectionDialog extends ConsumerStatefulWidget {
  final String conversationId;
  final Function(Map<String, dynamic> session, Map<String, dynamic> exercise)
  onExerciseStarted;

  const ExerciseSelectionDialog({
    super.key,
    required this.conversationId,
    required this.onExerciseStarted,
  });

  @override
  ConsumerState<ExerciseSelectionDialog> createState() =>
      _ExerciseSelectionDialogState();
}

class _ExerciseSelectionDialogState
    extends ConsumerState<ExerciseSelectionDialog> {
  final ExerciseService _exerciseService = ExerciseService();
  List<Map<String, dynamic>>? _exercises;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await ApiService().getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final exercises = await _exerciseService.getExercises(token);
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startExercise(String exerciseId) async {
    setState(() => _isLoading = true);

    try {
      final token = await ApiService().getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final result = await _exerciseService.startExercise(
        token: token,
        conversationId: widget.conversationId,
        exerciseId: exerciseId,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onExerciseStarted(result['session'], result['exercise']);
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'communication':
        return Icons.forum;
      case 'appreciation':
        return Icons.favorite;
      case 'conflict':
        return Icons.healing;
      case 'connection':
        return Icons.people;
      case 'empathy':
        return Icons.swap_horiz;
      case 'repair':
        return Icons.handshake;
      default:
        return Icons.psychology;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'communication':
        return Colors.blue;
      case 'appreciation':
        return Colors.pink;
      case 'conflict':
        return Colors.orange;
      case 'connection':
        return Colors.teal;
      case 'empathy':
        return Colors.deepPurple;
      case 'repair':
        return Colors.indigo;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.chooseAnExercise,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.practiceSkillsWithExercises,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadExercises,
                              child: Text(AppLocalizations.of(context)!.retry),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _exercises == null || _exercises!.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noExercisesAvailable,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _exercises!.length,
                      itemBuilder: (context, index) {
                        final exercise = _exercises![index];
                        final category = exercise['category'] as String;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _startExercise(exercise['exerciseId']),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(
                                            category,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(category),
                                          color: _getCategoryColor(category),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise['name'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${exercise['duration']} min',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    exercise['description'],
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
