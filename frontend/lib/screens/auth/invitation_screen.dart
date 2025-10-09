import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Your Partner'),
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
                'You\'ve been invited!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your partner has invited you to join We Counsel. Please sign in or create an account to get started.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (authState.isAuthenticated) ...[
                Text(
                  'You\'re already signed in. Click below to accept the invitation.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _acceptInvitation,
                  child: authState.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Accept Invitation'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Create Account'),
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
                        'What happens next?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• If you already have an account, sign in and accept the invitation\n'
                        '• If you\'re new, create an account and you\'ll automatically be paired\n'
                        '• Once paired, you can start your counselling journey together',
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
    try {
      await ref.read(authProvider.notifier).acceptInvitation(widget.invitationId);
      
      if (mounted) {
        // Clear the pending invitation
        ref.read(pendingInvitationProvider.notifier).state = null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined your partner!'),
            backgroundColor: Colors.green,
          ),
        );
        
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept invitation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
