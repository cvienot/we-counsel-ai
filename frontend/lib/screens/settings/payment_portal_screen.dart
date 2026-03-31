import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/payment_service.dart';
import '../../config/environment.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/snackbar_utils.dart';

class PaymentPortalScreen extends ConsumerStatefulWidget {
  const PaymentPortalScreen({super.key});

  @override
  ConsumerState<PaymentPortalScreen> createState() => _PaymentPortalScreenState();
}

class _PaymentPortalScreenState extends ConsumerState<PaymentPortalScreen> {
  final PaymentService _paymentService = PaymentService(baseUrl: Environment.apiBaseUrl);
  bool _isLoading = false;
  Map<String, dynamic> _subscriptionData = {};
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final response = await _paymentService.getSubscriptionUsage();
      
      if (response['success'] == true && response['usage'] != null) {
        final usage = response['usage'];
        final tier = usage['tier'] ?? 'free';
        
        // Map tier to display name
        String tierName;
        int aiLimit;
        switch (tier) {
          case 'essential':
            tierName = 'Essential';
            aiLimit = 100;
            break;
          case 'premium':
            tierName = 'Premium';
            aiLimit = -1; // unlimited
            break;
          default:
            tierName = 'Free';
            aiLimit = 10;
        }
        
        setState(() {
          _subscriptionData = {
            'tier': tier,
            'tierName': tierName,
            'status': 'active',
            'aiLimit': aiLimit,
            'aiUsed': usage['used'] ?? 0,
            'aiRemaining': usage['remaining'] ?? aiLimit,
          };
          _dataLoaded = true;
        });
      } else {
        // Fallback to free tier
        setState(() {
          _subscriptionData = {
            'tier': 'free',
            'tierName': 'Free',
            'status': 'active',
            'aiLimit': 10,
            'aiUsed': 0,
            'aiRemaining': 10,
          };
          _dataLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading subscription data: $e');
      // Fallback to free tier on error
      setState(() {
        _subscriptionData = {
          'tier': 'free',
          'tierName': 'Free',
          'status': 'active',
          'aiLimit': 10,
          'aiUsed': 0,
          'aiRemaining': 10,
        };
        _dataLoaded = true;
      });
    }
  }

  Future<void> _openCustomerPortal() async {
    setState(() => _isLoading = true);

    try {
      final result = await _paymentService.createPortalSession();

      if (result['success'] == true) {
        final url = result['url'];
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              final l10n = AppLocalizations.of(context)!;
              showErrorSnackBar(context, l10n.couldNotOpenPaymentPortal);
            }
          }
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          showErrorSnackBar(context, l10n.failedToOpenPortal);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showErrorSnackBar(context, l10n.errorGeneric);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_dataLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.paymentPortal)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final tier = _subscriptionData['tier'] ?? 'free';
    final tierName = _subscriptionData['tierName'] ?? 'Free';
    final status = _subscriptionData['status'] ?? 'active';
    final aiLimit = _subscriptionData['aiLimit'] ?? 10;
    final aiUsed = _subscriptionData['aiUsed'] ?? 0;
    final aiRemaining = _subscriptionData['aiRemaining'] ?? 10;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentPortal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Plan Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentPlan,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tierName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Chip(
                          label: Text(status.toUpperCase()),
                          backgroundColor: status == 'active' ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(aiLimit == -1 
                      ? 'AI Messages: Unlimited (used $aiUsed this month)'
                      : 'AI Messages: $aiRemaining / $aiLimit remaining'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Manage Subscription Button
            if (tier != 'free')
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _openCustomerPortal,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment),
                label: Text(l10n.manageSubscription),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

            if (tier != 'free') const SizedBox(height: 16),

            // Change Plan Button
            OutlinedButton.icon(
              onPressed: () {
                context.go('/plan-selection');
              },
              icon: const Icon(Icons.upgrade),
              label: Text(tier == 'free' ? l10n.upgradePlan : l10n.changePlan),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            // Billing History Button
            if (tier != 'free')
              OutlinedButton.icon(
                onPressed: () {
                  context.go('/billing-history');
                },
                icon: const Icon(Icons.receipt_long),
                label: Text(l10n.billingHistory),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

            const SizedBox(height: 32),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          l10n.aboutPaymentPortal,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.paymentPortalDescription,
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
