import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/exercise_service.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/responsive_layout.dart';
import '../../utils/snackbar_utils.dart';

class ExerciseHistoryScreen extends ConsumerStatefulWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  ConsumerState<ExerciseHistoryScreen> createState() =>
      _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends ConsumerState<ExerciseHistoryScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await ApiService().getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final sessions = await _exerciseService.getExerciseHistory(token);
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = cleanErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'active':
        return Icons.play_circle;
      case 'abandoned':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.orange;
      case 'abandoned':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showSummaryDialog(Map<String, dynamic> session) {
    final l10n = AppLocalizations.of(context)!;
    final summary = session['summary'] as String?;
    final name = session['exerciseName'] as String? ?? 'Exercise';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            summary ?? l10n.noSummaryAvailable,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exerciseHistory),
      ),
      body: ResponsiveCenter(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text('Failed to load history',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadHistory,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center,
                              size: 64,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noExercisesYet,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.completeExercisePrompt,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final status =
                              session['status'] as String? ?? 'unknown';
                          final name = session['exerciseName'] as String? ??
                              'Exercise';
                          final hasSummary =
                              session['summary'] != null &&
                                  (session['summary'] as String).isNotEmpty;
                          final currentStep =
                              session['currentStep'] as int? ?? 0;
                          final totalSteps =
                              session['totalSteps'] as int? ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: hasSummary
                                  ? () => _showSummaryDialog(session)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Status icon
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _statusIcon(status),
                                        color: _statusColor(status),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                status == 'completed'
                                                    ? l10n.completed
                                                    : status == 'active'
                                                        ? l10n.inProgressStatus(currentStep, totalSteps)
                                                        : status
                                                            .substring(
                                                                0, 1)
                                                            .toUpperCase() +
                                                        status.substring(
                                                            1),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          _statusColor(
                                                              status),
                                                    ),
                                              ),
                                              if (session['startedAt'] !=
                                                  null) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  '· ${_formatDate(session['startedAt'] as String?)}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors
                                                            .grey
                                                            .shade500,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (status == 'completed' &&
                                              totalSteps > 0) ...[
                                            const SizedBox(height: 6),
                                            LinearProgressIndicator(
                                              value: 1.0,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              color: Colors.green,
                                            ),
                                          ] else if (status == 'active' &&
                                              totalSteps > 0) ...[
                                            const SizedBox(height: 6),
                                            LinearProgressIndicator(
                                              value:
                                                  currentStep / totalSteps,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              color: Colors.orange,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Chevron for completed with summary
                                    if (hasSummary)
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey.shade400,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      ),
    );
  }
}
