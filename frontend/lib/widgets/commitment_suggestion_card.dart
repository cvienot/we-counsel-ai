import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CommitmentSuggestionCard extends StatefulWidget {
  final CommitmentSuggestion suggestion;
  final String conversationId;
  final String? sourceMessageId;

  const CommitmentSuggestionCard({
    super.key,
    required this.suggestion,
    required this.conversationId,
    this.sourceMessageId,
  });

  static CommitmentSuggestion? parseFromMessage(String content) {
    final marker = RegExp(r'\[COMMITMENT:([^\]]+)\]');
    final match = marker.firstMatch(content);
    if (match == null) return null;

    final fields = <String, String>{};
    final body = content.substring(match.end);
    for (final rawLine in body.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('[')) break;

      final separator = line.indexOf('=');
      if (separator <= 0) continue;

      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      fields[key] = value;
    }

    final title = fields['title'];
    final agreement = fields['agreement'];
    final practice = fields['practice'];
    if (title == null || agreement == null || practice == null) return null;

    final dueDays = int.tryParse(fields['due_days'] ?? '') ?? 7;
    final cleanContent = content.substring(0, match.start).trim();

    return CommitmentSuggestion(
      slug: match.group(1)!,
      title: title,
      agreement: agreement,
      practice: practice,
      dueDays: dueDays,
      cleanContent: cleanContent,
    );
  }

  @override
  State<CommitmentSuggestionCard> createState() =>
      _CommitmentSuggestionCardState();
}

class _CommitmentSuggestionCardState extends State<CommitmentSuggestionCard> {
  final _apiService = ApiService();
  bool _isSaving = false;
  bool _isUpdating = false;
  String? _commitmentId;
  String? _status;
  String? _error;

  Future<void> _saveCommitment() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final dueAt = DateTime.now()
          .add(Duration(days: widget.suggestion.dueDays))
          .toUtc()
          .toIso8601String();
      final response = await _apiService.createCommitment(
        conversationId: widget.conversationId,
        sourceMessageId: widget.sourceMessageId,
        title: widget.suggestion.title,
        agreement: widget.suggestion.agreement,
        practice: widget.suggestion.practice,
        dueAt: dueAt,
      );
      final commitment = response['commitment'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _commitmentId = commitment['commitmentId'] as String?;
        _status = commitment['status'] as String? ?? 'pending';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _markDone() async {
    final commitmentId = _commitmentId;
    if (commitmentId == null) return;

    setState(() {
      _isUpdating = true;
      _error = null;
    });

    try {
      final response = await _apiService.updateCommitmentStatus(
        commitmentId: commitmentId,
        status: 'done',
      );
      final commitment = response['commitment'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _status = commitment['status'] as String? ?? 'done';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not update. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaved = _commitmentId != null;
    final isDone = _status == 'done';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.task_alt,
                  color: isDone ? Colors.green : theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Action plan',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.suggestion.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SectionText(label: 'Agreement', text: widget.suggestion.agreement),
            const SizedBox(height: 8),
            _SectionText(label: 'Try this', text: widget.suggestion.practice),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _isSaving || isSaved ? null : _saveCommitment,
                  icon: Icon(isSaved ? Icons.check : Icons.bookmark_add),
                  label: Text(
                    isDone ? 'Done' : (isSaved ? 'Saved' : 'Save commitment'),
                  ),
                ),
                if (isSaved && !isDone)
                  OutlinedButton.icon(
                    onPressed: _isUpdating ? null : _markDone,
                    icon: const Icon(Icons.done),
                    label: Text(_isUpdating ? 'Updating...' : 'Mark done'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String label;
  final String text;

  const _SectionText({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }
}

class CommitmentSuggestion {
  final String slug;
  final String title;
  final String agreement;
  final String practice;
  final int dueDays;
  final String cleanContent;

  const CommitmentSuggestion({
    required this.slug,
    required this.title,
    required this.agreement,
    required this.practice,
    required this.dueDays,
    required this.cleanContent,
  });
}
