import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// A prominent banner shown on the main conversation screen
/// when a guided exercise is currently active.
///
/// Pulses when it's the current user's turn to respond.
class ActiveExerciseBanner extends StatefulWidget {
  final String exerciseName;
  final int currentStep;
  final int totalSteps;
  final bool isCurrentUsersTurn;
  final String? waitingForName;
  final VoidCallback onJoin;
  final VoidCallback? onDismiss;

  const ActiveExerciseBanner({
    super.key,
    required this.exerciseName,
    required this.currentStep,
    required this.totalSteps,
    required this.isCurrentUsersTurn,
    this.waitingForName,
    required this.onJoin,
    this.onDismiss,
  });

  @override
  State<ActiveExerciseBanner> createState() => _ActiveExerciseBannerState();
}

class _ActiveExerciseBannerState extends State<ActiveExerciseBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isCurrentUsersTurn) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ActiveExerciseBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentUsersTurn && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrentUsersTurn && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isYourTurn = widget.isCurrentUsersTurn;

    // Colours
    final baseColor = isYourTurn
        ? Colors.orange.shade700
        : theme.colorScheme.tertiary;
    final bgStart = isYourTurn
        ? Colors.orange.shade50
        : theme.colorScheme.tertiaryContainer.withOpacity(0.4);
    final bgEnd = isYourTurn
        ? Colors.amber.shade50
        : theme.colorScheme.tertiaryContainer.withOpacity(0.2);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final glowOpacity = isYourTurn ? 0.15 + _pulseAnimation.value * 0.15 : 0.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgStart, bgEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: baseColor.withOpacity(isYourTurn ? 0.6 + _pulseAnimation.value * 0.4 : 0.3),
              width: isYourTurn ? 2 : 1.5,
            ),
            boxShadow: [
              if (isYourTurn)
                BoxShadow(
                  color: Colors.orange.withOpacity(glowOpacity),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onJoin,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isYourTurn ? Icons.play_circle_filled : Icons.hourglass_top,
                        color: baseColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exercise name
                          Text(
                            widget.exerciseName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: baseColor,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Step progress + turn indicator
                          Row(
                            children: [
                              Text(
                                l10n.exerciseStepProgress(widget.currentStep, widget.totalSteps),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('•', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isYourTurn
                                      ? l10n.exerciseYourTurn
                                      : l10n.exerciseWaitingFor(widget.waitingForName ?? '...'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: isYourTurn ? FontWeight.w600 : FontWeight.normal,
                                    color: isYourTurn ? baseColor : theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Action button
                    FilledButton.tonal(
                      onPressed: widget.onJoin,
                      style: FilledButton.styleFrom(
                        backgroundColor: baseColor.withOpacity(isYourTurn ? 0.2 : 0.1),
                        foregroundColor: baseColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isYourTurn ? l10n.exerciseJoin : l10n.exerciseView,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
