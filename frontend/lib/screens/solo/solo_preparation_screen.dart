import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/responsive_layout.dart';

class SoloPreparationScreen extends StatefulWidget {
  const SoloPreparationScreen({super.key});

  @override
  State<SoloPreparationScreen> createState() => _SoloPreparationScreenState();
}

class _SoloPreparationScreenState extends State<SoloPreparationScreen> {
  static const _topicKey = 'solo_prep_topic';
  static const _feelingKey = 'solo_prep_feeling';
  static const _needKey = 'solo_prep_need';
  static const _nextStepKey = 'solo_prep_next_step';

  final _topicController = TextEditingController();
  final _feelingController = TextEditingController();
  final _needController = TextEditingController();
  final _nextStepController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _feelingController.dispose();
    _needController.dispose();
    _nextStepController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _topicController.text = prefs.getString(_topicKey) ?? '';
      _feelingController.text = prefs.getString(_feelingKey) ?? '';
      _needController.text = prefs.getString(_needKey) ?? '';
      _nextStepController.text = prefs.getString(_nextStepKey) ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveDraft({bool showConfirmation = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_topicKey, _topicController.text.trim());
    await prefs.setString(_feelingKey, _feelingController.text.trim());
    await prefs.setString(_needKey, _needController.text.trim());
    await prefs.setString(_nextStepKey, _nextStepController.text.trim());

    if (mounted && showConfirmation) {
      showSuccessSnackBar(
        context,
        AppLocalizations.of(context)!.soloDraftSaved,
      );
    }
  }

  String _invitationDraft(AppLocalizations l10n) {
    final topic = _topicController.text.trim();
    final feeling = _feelingController.text.trim();
    final need = _needController.text.trim();
    final nextStep = _nextStepController.text.trim();

    return l10n.soloInvitationDraft(
      topic.isEmpty ? l10n.soloDraftFallbackTopic : topic,
      feeling.isEmpty ? l10n.soloDraftFallbackFeeling : feeling,
      need.isEmpty ? l10n.soloDraftFallbackNeed : need,
      nextStep.isEmpty ? l10n.soloDraftFallbackNextStep : nextStep,
    );
  }

  Future<void> _useForInvitation() async {
    await _saveDraft(showConfirmation: false);

    if (mounted) {
      context.push(
        '/invite',
        extra: _invitationDraft(AppLocalizations.of(context)!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.soloPreparationTitle)),
      body: ResponsiveCenter(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.soloPreparationTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.soloPreparationIntro,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _SoloPromptField(
                      controller: _topicController,
                      label: l10n.soloTopicLabel,
                      hint: l10n.soloTopicHint,
                    ),
                    const SizedBox(height: 16),
                    _SoloPromptField(
                      controller: _feelingController,
                      label: l10n.soloFeelingLabel,
                      hint: l10n.soloFeelingHint,
                    ),
                    const SizedBox(height: 16),
                    _SoloPromptField(
                      controller: _needController,
                      label: l10n.soloNeedLabel,
                      hint: l10n.soloNeedHint,
                    ),
                    const SizedBox(height: 16),
                    _SoloPromptField(
                      controller: _nextStepController,
                      label: l10n.soloNextStepLabel,
                      hint: l10n.soloNextStepHint,
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _topicController,
                        _feelingController,
                        _needController,
                        _nextStepController,
                      ]),
                      builder: (context, _) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.mail_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.soloInvitationPreviewTitle,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _invitationDraft(l10n),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      key: const ValueKey('solo-prep-save-draft-button'),
                      onPressed: _saveDraft,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l10n.soloSaveDraft),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      key: const ValueKey('solo-prep-use-invitation-button'),
                      onPressed: _useForInvitation,
                      icon: const Icon(Icons.email_outlined),
                      label: Text(l10n.soloUseForInvitation),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.soloSafetyNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SoloPromptField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _SoloPromptField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
