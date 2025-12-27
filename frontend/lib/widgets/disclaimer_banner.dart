import 'package:flutter/material.dart';

/// Disclaimer banner to show on conversation screen
/// Reminds users that the service is not therapy
class DisclaimerBanner extends StatefulWidget {
  const DisclaimerBanner({super.key});

  @override
  State<DisclaimerBanner> createState() => _DisclaimerBannerState();
}

class _DisclaimerBannerState extends State<DisclaimerBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Important Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _isDismissed = true;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Dismiss',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This AI provides relationship communication support only. '
            'It is not therapy or a substitute for professional mental health services. '
            'For serious concerns, please consult a licensed professional.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.shade900,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Crisis alert dialog for emergency situations
class CrisisAlertDialog extends StatelessWidget {
  const CrisisAlertDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning, color: Colors.red, size: 48),
      title: const Text(
        'Need Immediate Help?',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If you or your partner are in crisis or immediate danger:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildResourceSection(
              'Emergency Services',
              ['Call 112 (EU), 911 (US), or your local emergency number'],
            ),
            const SizedBox(height: 16),
            _buildResourceSection(
              '24/7 Crisis Hotlines',
              [
                'International: findahelpline.com',
                'US Suicide Prevention: 988',
                'US Domestic Violence: 1-800-799-7233',
                'UK Samaritans: 116 123',
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'This app provides communication support only. '
              'For mental health crises, abuse, or safety concerns, '
              'please contact professional help immediately.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('I Understand'),
        ),
      ],
    );
  }

  Widget _buildResourceSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Text('• $item', style: const TextStyle(fontSize: 13)),
        )),
      ],
    );
  }

  /// Show crisis alert dialog
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CrisisAlertDialog(),
    );
  }
}
