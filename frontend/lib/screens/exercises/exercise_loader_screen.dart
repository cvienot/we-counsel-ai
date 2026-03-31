import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/exercise_service.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import 'exercise_screen.dart';

class ExerciseLoaderScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String exerciseId;

  const ExerciseLoaderScreen({
    super.key,
    required this.conversationId,
    required this.exerciseId,
  });

  @override
  ConsumerState<ExerciseLoaderScreen> createState() => _ExerciseLoaderScreenState();
}

class _ExerciseLoaderScreenState extends ConsumerState<ExerciseLoaderScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _exercise;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    try {
      final authState = ref.read(authProvider);
      final token = await ApiService().getToken();
      
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'notAuthenticated';
          _isLoading = false;
        });
        return;
      }

      // Get exercise details
      final exercises = await _exerciseService.getExercises(token);
      final exercise = exercises.firstWhere(
        (e) => e['exerciseId'] == widget.exerciseId,
        orElse: () => throw Exception('exerciseNotFound'),
      );

      // Start the exercise session
      final result = await _exerciseService.startExercise(
        token: token,
        conversationId: widget.conversationId,
        exerciseId: widget.exerciseId,
      );

      print('📝 Exercise loaded:');
      print('  Result: $result');
      print('  Session: ${result['session']}');
      print('  Exercise: ${result['exercise']}');

      setState(() {
        _exercise = result['exercise'];  // Use personalized exercise from result
        _session = result['session'];  // Extract session from result
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      final l10n = AppLocalizations.of(context)!;
      final errorMsg = _error == 'notAuthenticated' ? l10n.notAuthenticated 
          : _error == 'exerciseNotFound' ? l10n.exerciseNotFound 
          : _error!;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.error)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(errorMsg, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(l10n.goBack),
              ),
            ],
          ),
        ),
      );
    }

    return ExerciseScreen(
      conversationId: widget.conversationId,
      session: _session!,
      exercise: _exercise!,
      onComplete: () {
        context.pop();
      },
    );
  }
}
