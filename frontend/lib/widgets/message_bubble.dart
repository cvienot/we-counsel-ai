import 'package:flutter/material.dart';
import '../models/message.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isAI = message.senderType == 'ai';
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser && !isAI
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser || isAI) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser && !isAI
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser || isAI)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isAI
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _getBubbleColor(context),
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomLeft: !isCurrentUser || isAI
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                      bottomRight: isCurrentUser && !isAI
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(message.timestamp),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getTextColor(context).withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser && !isAI) ...[
            const SizedBox(width: 8),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isAI = message.senderType == 'ai';
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: 16,
      backgroundColor: isAI
          ? theme.colorScheme.primary
          : isCurrentUser
              ? theme.colorScheme.secondary
              : theme.colorScheme.tertiary,
      child: isAI
          ? const Icon(
              Icons.psychology,
              size: 16,
              color: Colors.white,
            )
          : Text(
              message.senderName.isNotEmpty
                  ? message.senderName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Color _getBubbleColor(BuildContext context) {
    final theme = Theme.of(context);
    final isAI = message.senderType == 'ai';

    if (isAI) {
      return theme.colorScheme.primaryContainer;
    } else if (isCurrentUser) {
      return theme.colorScheme.primary;
    } else {
      return theme.colorScheme.surfaceVariant;
    }
  }

  Color _getTextColor(BuildContext context) {
    final theme = Theme.of(context);
    final isAI = message.senderType == 'ai';

    if (isAI) {
      return theme.colorScheme.onPrimaryContainer;
    } else if (isCurrentUser) {
      return theme.colorScheme.onPrimary;
    } else {
      return theme.colorScheme.onSurfaceVariant;
    }
  }
}
