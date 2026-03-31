import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/exercise_service.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../l10n/app_localizations.dart';

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
  late Map<String, dynamic> _currentStepData; // Personalized current step
  bool _isLoading = false;
  String? _summary;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _currentExercise = widget.exercise;
    // Get the personalized current step from the exercise
    print('📝 ExerciseScreen init:');
    print('  Session: ${widget.session}');
    print('  Exercise: ${widget.exercise}');
    print('  CurrentStep in exercise: ${widget.exercise['currentStep']}');
    
    _currentStepData = (widget.exercise['currentStep'] as Map<String, dynamic>?) ?? {};
    _startPollingIfWaiting();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _responseController.dispose();
    super.dispose();
  }

  void _startPollingIfWaiting() {
    _pollTimer?.cancel();
    
    final prompt = _currentStepData['prompt'] as String? ?? '';
    if (prompt.isNotEmpty && !_isCurrentUsersTurn(prompt)) {
      // Not our turn - poll every 5 seconds for updates
      print('⏳ Starting poll - waiting for partner...');
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollSession());
    }
  }

  Future<void> _pollSession() async {
    try {
      final token = await ApiService().getToken();
      if (token == null || token.isEmpty) return;

      final result = await _exerciseService.getActiveSession(
        token: token,
        conversationId: widget.conversationId,
      );

      if (!mounted) return;

      // No active session means exercise was completed by partner
      if (result == null) {
        print('🔄 Exercise completed by partner!');
        _pollTimer?.cancel();
        
        // Update session status to completed and load summary
        setState(() {
          _currentSession['status'] = 'completed';
        });
        await _loadSummary();
        return;
      }

      final session = result['session'] as Map<String, dynamic>;
      final serverStep = session['currentStep'] as int? ?? 1;
      final localStep = _currentSession['currentStep'] as int? ?? 1;
      final serverStatus = session['status'] as String? ?? 'active';

      if (serverStep != localStep || serverStatus != _currentSession['status']) {
        print('🔄 Session updated! Step $localStep → $serverStep, status: $serverStatus');
        
        if (serverStatus == 'completed') {
          // Partner completed the exercise
          _pollTimer?.cancel();
          setState(() {
            _currentSession = session;
          });
          await _loadSummary();
          return;
        }

        // Use the exercise data from active session response
        final exercise = result['exercise'] as Map<String, dynamic>?;
        
        if (!mounted) return;
        
        setState(() {
          _currentSession = session;
          if (exercise != null) {
            _currentExercise = exercise;
            _currentStepData = (exercise['currentStep'] as Map<String, dynamic>?) ?? {};
          }
        });
        
        // Re-evaluate polling
        _startPollingIfWaiting();
      }
    } catch (e) {
      print('⚠️ Poll error: $e');
    }
  }

  bool _isCurrentUsersTurn(String prompt) {
    final authState = ref.read(authProvider);
    final currentUserFirstName = authState.user?.firstName ?? '';
    
    if (currentUserFirstName.isEmpty) {
      // Can't determine - deny by default for safety
      return false;
    }
    
    // Check if the prompt starts with the current user's first name followed by a comma
    // Prompts are like "Alex, what would you like to share?"
    // This ensures we match the person being asked, not just mentioned
    final startsWithUserName = prompt.startsWith('$currentUserFirstName,') || 
                                prompt.startsWith('$currentUserFirstName ');
    
    print('🔒 Turn check:');
    print('  Current user: $currentUserFirstName');
    print('  Prompt: $prompt');
    print('  Is their turn: $startsWithUserName');
    
    return startsWithUserName;
  }

  String _extractPartnerName(String prompt, {required bool isFirst}) {
    // Extract partner names from a personalized prompt
    // Example: "Alex, what would you like to share with Emma?"
    // Returns: partner1=Alex, partner2=Emma
    
    final regex = RegExp(r'^(\w+),.*\s(\w+)\?');
    final match = regex.firstMatch(prompt);
    
    if (match != null && match.groupCount >= 2) {
      return isFirst ? match.group(1)! : match.group(2)!;
    }
    
    return '';
  }

  Future<void> _submitResponse() async {
    final l10n = AppLocalizations.of(context)!;
    if (_responseController.text.trim().isEmpty) {
      showErrorSnackBar(context, l10n.pleaseEnterResponse);
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
        // Exercise completed - stop polling, get summary
        _pollTimer?.cancel();
        setState(() {
          _currentSession = result['session'];
          _isLoading = false;
        });
        await _loadSummary();
      } else {
        // Move to next step
        setState(() {
          _currentSession = result['session'];
          _currentStepData = result['nextStep']; // Update with personalized step
          _isLoading = false;
        });
        // Re-evaluate polling (it's now partner's turn)
        _startPollingIfWaiting();
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.exerciseCompleteTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.greatWorkCompleting(_currentExercise['name']),
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
                          l10n.keyTakeaways,
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
              l10n.generatingSummary,
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
            child: Text(l10n.returnToConversation),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseView() {
    final stepNumber = (_currentSession['currentStep'] as int?) ?? 1;
    final totalSteps = (_currentExercise['steps'] as List).length;
    final progress = stepNumber / totalSteps;
    
    // Use the personalized current step data
    print('📝 Building exercise view:');
    print('  Step number: $stepNumber');
    print('  Current step data: $_currentStepData');
    
    final currentStepData = _currentStepData;
    
    // Fallback to template if personalized step is missing
    if (currentStepData.isEmpty || currentStepData['instruction'] == null) {
      print('⚠️ Using fallback template step');
      final templateStepData = (_currentExercise['steps'] as List)[stepNumber - 1];
      return _buildStepView(stepNumber, totalSteps, progress, templateStepData);
    }

    return _buildStepView(stepNumber, totalSteps, progress, currentStepData);
  }
  
  Widget _buildStepView(int stepNumber, int totalSteps, double progress, Map<String, dynamic> currentStepData) {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.exerciseStepProgress(stepNumber, totalSteps),
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
                              l10n.instruction,
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
                              l10n.guidance,
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

                // Previous responses (conversation history)
                if (_hasPreviousResponses()) ...[
                  Card(
                    color: Colors.grey.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                l10n.conversationSoFar,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._buildPreviousResponses(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Prompt
                Text(
                  currentStepData['prompt'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),

                // Check if it's current user's turn
                if (!_isCurrentUsersTurn(currentStepData['prompt']))
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_empty, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.waitingForPartnerResponse,
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_isCurrentUsersTurn(currentStepData['prompt']))
                  const SizedBox(height: 16),

                // Response input
                TextField(
                  controller: _responseController,
                  maxLines: 5,
                  enabled: _isCurrentUsersTurn(currentStepData['prompt']) && !_isLoading,
                  decoration: InputDecoration(
                    hintText: _isCurrentUsersTurn(currentStepData['prompt']) 
                      ? l10n.typeYourResponseHere
                      : l10n.waitingForYourPartner,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Submit button
                ElevatedButton(
                  onPressed: (_isLoading || !_isCurrentUsersTurn(currentStepData['prompt'])) ? null : _submitResponse,
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
                          stepNumber == totalSteps ? l10n.completeExercise : l10n.nextStep,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _hasPreviousResponses() {
    final progressRaw = _currentSession['progress'];
    if (progressRaw == null) return false;
    
    // Parse progress if it's a string
    final Map<String, dynamic> progress;
    if (progressRaw is String) {
      try {
        progress = jsonDecode(progressRaw) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Failed to parse progress: $e');
        return false;
      }
    } else {
      progress = progressRaw as Map<String, dynamic>;
    }
    
    final steps = progress['steps'] as List?;
    if (steps == null) return false;
    
    // Check if any previous steps have responses
    final currentStepNum = (_currentSession['currentStep'] as int?) ?? 1;
    return steps.any((step) {
      final stepNum = step['stepNumber'] as int;
      final response = step['response'] as String?;
      return stepNum < currentStepNum && response != null && response.isNotEmpty;
    });
  }

  List<Widget> _buildPreviousResponses() {
    final progressRaw = _currentSession['progress'];
    if (progressRaw == null) return [];
    
    // Parse progress if it's a string
    final Map<String, dynamic> progress;
    if (progressRaw is String) {
      try {
        progress = jsonDecode(progressRaw) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Failed to parse progress: $e');
        return [];
      }
    } else {
      progress = progressRaw as Map<String, dynamic>;
    }
    
    final steps = progress['steps'] as List?;
    if (steps == null) return [];
    
    final currentStepNum = (_currentSession['currentStep'] as int?) ?? 1;
    final exerciseSteps = _currentExercise['steps'] as List;
    
    // Get partner names from the exercise (they're embedded in the currentStep)
    final currentStepPrompt = _currentStepData['prompt'] as String? ?? '';
    final partner1 = _extractPartnerName(currentStepPrompt, isFirst: true);
    final partner2 = _extractPartnerName(currentStepPrompt, isFirst: false);
    
    final widgets = <Widget>[];
    
    for (var i = 0; i < currentStepNum - 1; i++) {
      final stepData = steps[i];
      final response = stepData['response'] as String?;
      
      if (response != null && response.isNotEmpty) {
        final templateStep = exerciseSteps[i] as Map<String, dynamic>;
        var prompt = templateStep['prompt'] as String;
        
        // Replace partner placeholders with actual names
        if (partner1.isNotEmpty && partner2.isNotEmpty) {
          prompt = prompt
              .replaceAll('@{partner1}', partner1)
              .replaceAll('@{partner2}', partner2);
        }
        
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${i + 1}: $prompt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  response,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _currentSession['status'] == 'completed';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCompleted ? l10n.exerciseComplete : l10n.guidedExercise),
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
                  title: Text(l10n.leaveExercise),
                  content: Text(
                    l10n.leaveExerciseConfirmation,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.stay),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text(l10n.leave),
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
