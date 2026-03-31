import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/snackbar_utils.dart';

class InvitationScreen extends ConsumerStatefulWidget {
  final String invitationId;
  
  const InvitationScreen({
    super.key,
    required this.invitationId,
  });

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  @override
  void initState() {
    super.initState();
    // Store the invitation ID for later use
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingInvitationProvider.notifier).state = widget.invitationId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.joinYourPartner),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                l10n.youveBeenInvited,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.partnerInvitedYou,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (authState.isAuthenticated) ...[
                Text(
                  l10n.alreadySignedInAccept,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _acceptInvitation,
                  child: authState.isLoading
                      ? const CircularProgressIndicator()
                      : Text(l10n.acceptInvitation),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: Text(l10n.signIn),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.go('/register'),
                  child: Text(l10n.createAccount),
                ),
              ],
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.whatHappensNext,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.invitationInfoSteps,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptInvitation() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(authProvider.notifier).acceptInvitation(widget.invitationId);
      
      if (mounted) {
        // Clear the pending invitation
        ref.read(pendingInvitationProvider.notifier).state = null;
        
        showSuccessSnackBar(context, l10n.successfullyJoinedPartner);
        
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, l10n.failedToAcceptInvitation);
      }
    }
  }
}
