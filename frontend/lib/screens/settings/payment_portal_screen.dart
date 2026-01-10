import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/payment_service.dart';
import '../../config/app_config.dart';

class PaymentPortalScreen extends ConsumerStatefulWidget {
  const PaymentPortalScreen({super.key});

  @override
  ConsumerState<PaymentPortalScreen> createState() => _PaymentPortalScreenState();
}

class _PaymentPortalScreenState extends ConsumerState<PaymentPortalScreen> {
  final PaymentService _paymentService = PaymentService(baseUrl: AppConfig.apiBaseUrl);
  bool _isLoading = false;
  Map<String, dynamic> _subscriptionData = {};
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    // For now, use default free tier data
    // TODO: Add API call to fetch actual subscription
    setState(() {
      _subscriptionData = {
        'tier': 'free',
        'tierName': 'Free',
        'status': 'active',
        'aiLimit': 10,
        'aiRemaining': 10,
        'endDate': null,
      };
      _dataLoaded = true;
    });
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not open payment portal'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to open portal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Portal')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final tier = _subscriptionData['tier'] ?? 'free';
    final tierName = _subscriptionData['tierName'] ?? 'Free';
    final status = _subscriptionData['status'] ?? 'active';
    final aiLimit = _subscriptionData['aiLimit'] ?? 10;
    final aiRemaining = _subscriptionData['aiRemaining'] ?? 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Portal'),
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
                      'Current Plan',
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
                    Text('AI Messages: $aiRemaining / $aiLimit remaining'),
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
                label: const Text('Manage Subscription'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

            if (tier != 'free') const SizedBox(height: 16),

            // Change Plan Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/plan-selection');
              },
              icon: const Icon(Icons.upgrade),
              label: Text(tier == 'free' ? 'Upgrade Plan' : 'Change Plan'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            // Billing History Button
            if (tier != 'free')
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/billing-history');
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Billing History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

            const SizedBox(height: 32),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'About Payment Portal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use the Manage Subscription button to update payment methods, view invoices, or cancel your subscription. All payment processing is securely handled by Stripe.',
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
