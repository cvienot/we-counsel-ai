import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/progress_provider.dart';

class ProgressDashboardScreen extends ConsumerStatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  ConsumerState<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState
    extends ConsumerState<ProgressDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.progressDashboard ?? 'Progress Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _ErrorView(
                  error: state.error!,
                  onRetry: () =>
                      ref.read(progressProvider.notifier).loadDashboard(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(progressProvider.notifier).loadDashboard(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Health Score
                        _HealthScoreCard(score: state.healthScore),
                        const SizedBox(height: 16),

                        // Activity Streak
                        _StreakCard(streak: state.activityStreak),
                        const SizedBox(height: 16),

                        // Quick Stats Row
                        _QuickStatsRow(
                          conversationStats: state.conversationStats,
                          exerciseStats: state.exerciseStats,
                        ),
                        const SizedBox(height: 16),

                        // Weekly Activity
                        Text(
                          l10n?.weeklyActivity ?? 'Weekly Activity',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        _WeeklyActivityChart(
                            weeklyActivity: state.weeklyActivity),
                        const SizedBox(height: 16),

                        // Exercise Stats
                        Text(
                          l10n?.exerciseProgress ?? 'Exercise Progress',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        _ExerciseStatsCard(stats: state.exerciseStats),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ──────────────────────────────────────────────
// Health Score Card with circular indicator
// ──────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  final int score;

  const _HealthScoreCard({required this.score});

  Color _scoreColor() {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red.shade400;
  }

  String _scoreLabel(AppLocalizations? l10n) {
    if (score >= 70) return l10n?.healthGreat ?? 'Great';
    if (score >= 40) return l10n?.healthGood ?? 'Good';
    return l10n?.healthGettingStarted ?? 'Getting Started';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = _scoreColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _CircularScorePainter(
                  score: score / 100,
                  color: color,
                  backgroundColor: color.withOpacity(0.15),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.relationshipHealth ?? 'Relationship Health',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _scoreLabel(l10n),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.healthScoreDescription ??
                        'Based on your conversations, exercises, and engagement',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularScorePainter extends CustomPainter {
  final double score;
  final Color color;
  final Color backgroundColor;

  _CircularScorePainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const strokeWidth = 10.0;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * score,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularScorePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}

// ──────────────────────────────────────────────
// Activity Streak Card
// ──────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final Map<String, dynamic> streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final currentStreak = streak['currentStreak'] ?? 0;
    final longestStreak = streak['longestStreak'] ?? 0;
    final totalActiveDays = streak['totalActiveDays'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_fire_department,
                  color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.activityStreak ?? 'Activity Streak',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$currentStreak',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n?.days ?? 'days',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${l10n?.best ?? "Best"}: $longestStreak',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n?.totalDaysActive ?? "Total"}: $totalActiveDays',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Quick Stats Row
// ──────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final Map<String, dynamic> conversationStats;
  final Map<String, dynamic> exerciseStats;

  const _QuickStatsRow({
    required this.conversationStats,
    required this.exerciseStats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.chat_bubble_outline,
            value: '${conversationStats['totalMessages'] ?? 0}',
            label: l10n?.messages ?? 'Messages',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.fitness_center,
            value: '${exerciseStats['completed'] ?? 0}',
            label: l10n?.exercisesCompleted ?? 'Exercises',
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Weekly Activity Bar Chart
// ──────────────────────────────────────────────

class _WeeklyActivityChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyActivity;

  const _WeeklyActivityChart({required this.weeklyActivity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (weeklyActivity.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              AppLocalizations.of(context)?.noActivityYet ??
                  'No activity yet this week',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ),
      );
    }

    final maxMessages = weeklyActivity
        .map((d) => (d['messages'] as int?) ?? 0)
        .fold(0, (a, b) => a > b ? a : b);
    final chartMax = maxMessages > 0 ? maxMessages.toDouble() : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeklyActivity.map((day) {
              final messages = (day['messages'] as int?) ?? 0;
              final exercises = (day['exercises'] as int?) ?? 0;
              final dayLabel = day['dayOfWeek'] ?? '';
              final barHeight = (messages / chartMax) * 120;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (exercises > 0)
                        Icon(
                          Icons.fitness_center,
                          size: 14,
                          color: Colors.green.shade400,
                        ),
                      if (messages > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '$messages',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      Container(
                        height: math.max(barHeight, 4),
                        decoration: BoxDecoration(
                          color: messages > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Exercise Stats Card
// ──────────────────────────────────────────────

class _ExerciseStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _ExerciseStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final completed = stats['completed'] ?? 0;
    final total = stats['total'] ?? 0;
    final completionRate = stats['completionRate'] ?? 0;
    final byCategory =
        Map<String, dynamic>.from(stats['byCategory'] ?? {});

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion rate bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.completionRate ?? 'Completion Rate',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '$completionRate%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completionRate / 100,
                minHeight: 8,
                backgroundColor:
                    theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(
                    value: '$completed',
                    label: l10n?.completed ?? 'Completed'),
                _MiniStat(
                    value: '$total', label: l10n?.totalStarted ?? 'Started'),
                _MiniStat(
                    value: '${stats['recentCompleted'] ?? 0}',
                    label: l10n?.thisMonth ?? 'This Month'),
              ],
            ),

            // Categories
            if (byCategory.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                l10n?.byCategory ?? 'By Category',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: byCategory.entries.map((entry) {
                  return Chip(
                    avatar: Icon(
                      _categoryIcon(entry.key),
                      size: 16,
                    ),
                    label: Text(
                        '${_categoryLabel(entry.key)}: ${entry.value}'),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'communication':
        return Icons.record_voice_over;
      case 'appreciation':
        return Icons.favorite;
      case 'conflict':
        return Icons.handshake;
      case 'emotional':
        return Icons.psychology;
      default:
        return Icons.fitness_center;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'communication':
        return 'Communication';
      case 'appreciation':
        return 'Appreciation';
      case 'conflict':
        return 'Conflict';
      case 'emotional':
        return 'Emotional';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Error View
// ──────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(l10n?.retry ?? 'Retry'),
          ),
        ],
      ),
    );
  }
}
