import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageState = ref.watch(languageProvider);
    final languageNotifier = ref.read(languageProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: LanguageNotifier.supportedLocales.length,
        itemBuilder: (context, index) {
          final locale = LanguageNotifier.supportedLocales[index];
          final isSelected = locale == languageState.locale;
          final languageName = languageNotifier.getLanguageName(locale);
          final nativeName = languageNotifier.getLanguageNativeName(locale);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                languageName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                nativeName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : const Icon(Icons.radio_button_unchecked),
              onTap: () async {
                if (!isSelected) {
                  await languageNotifier.changeLanguage(locale);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class LanguageSelectionDialog extends ConsumerWidget {
  const LanguageSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageState = ref.watch(languageProvider);
    final languageNotifier = ref.read(languageProvider.notifier);

    return AlertDialog(
      title: Text(l10n.selectLanguage),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: LanguageNotifier.supportedLocales.length,
          itemBuilder: (context, index) {
            final locale = LanguageNotifier.supportedLocales[index];
            final isSelected = locale == languageState.locale;
            final languageName = languageNotifier.getLanguageName(locale);
            final nativeName = languageNotifier.getLanguageNativeName(locale);

            return ListTile(
              title: Text(languageName),
              subtitle: Text(
                nativeName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : const Icon(Icons.radio_button_unchecked),
              onTap: () async {
                if (!isSelected) {
                  await languageNotifier.changeLanguage(locale);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
