import 'package:flutter/material.dart';

/// Parses text containing @Name mentions and renders them as highlighted chips,
/// similar to Slack's @mention style.
///
/// - Mentions matching [currentUserName] are highlighted with [currentUserColor].
/// - Mentions matching [partnerName] are highlighted with [partnerColor].
/// - Other @mentions fall back to a neutral style.
class MentionText extends StatelessWidget {
  final String text;
  final String? currentUserName;
  final String? partnerName;
  final TextStyle? baseStyle;
  final Color currentUserColor;
  final Color partnerColor;

  const MentionText({
    super.key,
    required this.text,
    this.currentUserName,
    this.partnerName,
    this.baseStyle,
    this.currentUserColor = const Color(0xFF1264A3), // Slack-style blue
    this.partnerColor = const Color(0xFF4A154B), // Slack-style purple
  });

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ?? DefaultTextStyle.of(context).style;
    final spans = _buildSpans(style);

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// Builds alternating normal-text and mention spans.
  static List<InlineSpan> buildSpans({
    required String text,
    required TextStyle baseStyle,
    String? currentUserName,
    String? partnerName,
    Color currentUserColor = const Color(0xFF1264A3),
    Color partnerColor = const Color(0xFF4A154B),
  }) {
    // Match @Word (including accented characters) - stops at whitespace or punctuation
    final mentionRegex = RegExp(r'@([\p{L}\p{N}_-]+)', unicode: true);
    final matches = mentionRegex.allMatches(text).toList();

    if (matches.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before this mention
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final mentionName = match.group(1)!;
      final fullMention = match.group(0)!; // includes @

      // Determine which color to use
      final isCurrentUser = currentUserName != null &&
          mentionName.toLowerCase() == currentUserName!.toLowerCase();
      final isPartner = partnerName != null &&
          mentionName.toLowerCase() == partnerName!.toLowerCase();

      final Color bgColor;
      final Color textColor;
      if (isCurrentUser) {
        bgColor = currentUserColor.withOpacity(0.15);
        textColor = currentUserColor;
      } else if (isPartner) {
        bgColor = partnerColor.withOpacity(0.15);
        textColor = partnerColor;
      } else {
        // Unknown mention - neutral gray style
        bgColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey.shade700;
      }

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            fullMention,
            style: baseStyle.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text after last mention
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  List<InlineSpan> _buildSpans(TextStyle style) {
    return buildSpans(
      text: text,
      baseStyle: style,
      currentUserName: currentUserName,
      partnerName: partnerName,
      currentUserColor: currentUserColor,
      partnerColor: partnerColor,
    );
  }
}
