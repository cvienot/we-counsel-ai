import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Crisis alert dialog for emergency situations
class CrisisAlertDialog extends StatelessWidget {
  const CrisisAlertDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      icon: const Icon(Icons.warning, color: Colors.red, size: 48),
      title: Text(
        l10n.needImmediateHelp,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.crisisDialogText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildResourceSection(l10n.emergencyServices, [
              'Call 112 (EU), 911 (US), or your local emergency number',
            ]),
            const SizedBox(height: 16),
            _buildResourceSection(l10n.crisisHotlines, [
              'International: findahelpline.com',
              'US Suicide Prevention: 988',
              'US Domestic Violence: 1-800-799-7233',
              'UK Samaritans: 116 123',
            ]),
            const SizedBox(height: 16),
            Text(
              l10n.appProvidesSupport,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.iUnderstand),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text('• $item', style: const TextStyle(fontSize: 13)),
          ),
        ),
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
