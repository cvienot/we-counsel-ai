import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/language_provider.dart';

class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() =>
      _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  String? _privacyContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      final locale = ref.read(currentLocaleProvider);
      final languageCode = locale.languageCode;
      final fileName = 'assets/privacy/privacy_$languageCode.md';

      String content;
      try {
        content = await rootBundle.loadString(fileName);
      } catch (e) {
        content = await rootBundle.loadString('assets/privacy/privacy_en.md');
      }

      setState(() {
        _privacyContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Privacy Policy';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPrivacyPolicy,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Markdown(
                data: _privacyContent!,
                padding: const EdgeInsets.all(24.0),
                styleSheet: MarkdownStyleSheet(
                  h1: Theme.of(context).textTheme.headlineMedium,
                  h2: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  h3: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  p: Theme.of(context).textTheme.bodyMedium,
                  listBullet: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
    );
  }
}
