import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isEditing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context)!;
      try {
        await ref.read(authProvider.notifier).updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
        
        if (mounted) {
          showSuccessSnackBar(context, l10n.profileUpdatedSuccess);
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(context, l10n.failedToUpdateProfile);
        }
      }
    }
  }

  String _getInitials(String firstName, String lastName) {
    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    final initials = '$firstInitial$lastInitial'.toUpperCase();
    return initials.isNotEmpty ? initials : '?';
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          TextButton(
            onPressed: authState.isLoading ? null : _saveProfile,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      _getInitials(user.firstName, user.lastName),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Profile information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.personalInformation,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: l10n.firstName,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.pleaseEnterFirstName;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: l10n.lastName,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.pleaseEnterLastName;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        initialValue: user.email,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          helperText: l10n.emailCannotBeChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Partner information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.relationshipStatus,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    if (user.hasPartner && user.partner != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.connectedWith(user.partner!.fullName),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.person_add,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.noPartnerConnected,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push('/invite'),
                        child: Text(l10n.invitePartner),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Subscription & Billing Card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text(l10n.exerciseHistory),
                    subtitle: Text(l10n.viewPastExercises),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/exercise-history'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.payment),
                    title: Text(l10n.paymentPortal),
                    subtitle: Text(l10n.manageSubscriptionBilling),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/payment-portal'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(l10n.billingHistory),
                    subtitle: Text(l10n.viewInvoicesPayments),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/billing-history'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upgrade),
                    title: Text(l10n.changePlan),
                    subtitle: Text(l10n.upgradeOrChangeSubscription),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/plan-selection'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.logout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
