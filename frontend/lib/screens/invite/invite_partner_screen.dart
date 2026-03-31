import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/ctrl_enter_submit.dart';
import '../../utils/snackbar_utils.dart';


class InvitePartnerScreen extends ConsumerStatefulWidget {
  const InvitePartnerScreen({super.key});

  @override
  ConsumerState<InvitePartnerScreen> createState() => _InvitePartnerScreenState();
}

class _InvitePartnerScreenState extends ConsumerState<InvitePartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (_formKey.currentState!.validate()) {
      try {
        final l10n = AppLocalizations.of(context)!;
        
        await ref.read(authProvider.notifier).invitePartner(
          email: _emailController.text.trim(),
          message: _messageController.text.trim(),
        );
        
        if (mounted) {
          final email = _emailController.text.trim();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.invitationSent),
              content: Text(
                l10n.invitationSentMessage(email),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/home');
                  },
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          showErrorSnackBar(context, l10n.failedToSendInvitation);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inviteYourPartner),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.sendInvitation,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.invitePartnerDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Form
            CtrlEnterSubmit(
              onSubmit: _sendInvitation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.partnerEmailAddress,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: l10n.enterPartnerEmail,
                      prefixIcon: const Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterPartnerEmail;
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return l10n.pleaseEnterValidEmail;
                      }
                      if (value.trim().toLowerCase() == user?.email.toLowerCase()) {
                        return l10n.cannotInviteYourself;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    l10n.personalMessageOptional,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: l10n.addPersonalMessage,
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _sendInvitation,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.sendInvitation),
                    ),
                  ),
                ],
              ),
            ),
            ),
            
            const SizedBox(height: 24),
            
            // Info card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.whatHappensNext,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.invitationSteps.replaceAll('\\n', '\n'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
