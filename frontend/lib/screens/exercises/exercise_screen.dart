import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/exercise_service.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/snackbar_utils.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final Map<String, dynamic> session;
  final Map<String, dynamic> exercise;
  final Function() onComplete;

  const ExerciseScreen({
    super.key,
    required this.conversationId,
    required this.session,
    required this.exercise,
    required this.onComplete,
  });

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final TextEditingController _responseController = TextEditingController();
  
  late Map<String, dynamic> _currentSession;
  late Map<String, dynamic> _currentExercise;
  bool _isLoading = false;
  String? _summary;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _currentExercise = widget.exercise;
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) {
      showErrorSnackBar(context, 'Please enter a response');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await ApiService().getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      print('📝 Submitting response:');
      print('  Session: $_currentSession');
      print('  SessionId: ${_currentSession['sessionId']}');

      final result = await _exerciseService.progressExercise(
        token: token,
        sessionId: _currentSession['sessionId'] as String,
        response: _responseController.text.trim(),
      );

      _responseController.clear();

      if (result['completed'] == true) {
        // Exercise completed - get summary
        setState(() {
          _currentSession = result['session'];
          _isLoading = false;
        });
        await _loadSummary();
      } else {
        // Move to next step
        setState(() {
          _currentSession = result['session'];
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        showErrorSnackBar(context, 'Error: $error');
      }
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);

    try {
      final token = await ApiService().getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final summary = await _exerciseService.getExerciseSummary(
        token: token,
        sessionId: _currentSession['sessionId'],
      );

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        showErrorSnackBar(context, 'Error loading summary: $error');
      }
    }
  }

  Widget _buildCompletionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            'Exercise Complete! ✨',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Great work on completing "${_currentExercise['name']}"!',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_summary != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insights, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Key Takeaways',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _summary!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ] else if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              'Generating your summary...',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Return to Conversation'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseView() {
    final stepNumber = (_currentSession['currentStep'] as int?) ?? 1;
    final totalSteps = (_currentExercise['steps'] as List).length;
    final progress = stepNumber / totalSteps;
    
    // Get the current step data (steps are 1-indexed)
    final currentStepData = (_currentExercise['steps'] as List)[stepNumber - 1];

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(value: progress),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Exercise name and step counter
                Text(
                  _currentExercise['name'],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step $stepNumber of $totalSteps',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
                const SizedBox(height: 24),

                // Instruction card
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.directions,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Instruction',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentStepData['instruction'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Guidance card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Guidance',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentStepData['guidance'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Prompt
                Text(
                  currentStepData['prompt'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),

                // Response input
                TextField(
                  controller: _responseController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Type your response here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitResponse,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          stepNumber == totalSteps ? 'Complete Exercise' : 'Next Step',
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _currentSession['status'] == 'completed';

    return Scaffold(
      appBar: AppBar(
        title: Text(isCompleted ? 'Exercise Complete' : 'Guided Exercise'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (isCompleted) {
              widget.onComplete();
            } else {
              // Warn about abandoning
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Leave Exercise?'),
                  content: const Text(
                    'Are you sure you want to leave? Your progress will be saved and you can continue later.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Stay'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      body: isCompleted ? _buildCompletionView() : _buildExerciseView(),
    );
  }
}
