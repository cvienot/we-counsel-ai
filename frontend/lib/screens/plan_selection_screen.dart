import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payment_service.dart';
import '../config/environment.dart';
import '../utils/snackbar_utils.dart';
import '../l10n/app_localizations.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  String selectedTier = 'free';
  String selectedBillingPeriod = 'monthly';
  bool _isProcessingPayment = false;
  bool _isLoading = true;
  String? _currentTier; // Nullable to distinguish between "not loaded" and "free tier"
  final PaymentService _paymentService = PaymentService(baseUrl: Environment.apiBaseUrl);

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      final response = await _paymentService.getSubscriptionUsage();
      
      if (response['success'] == true && response['usage'] != null) {
        final usage = response['usage'];
        final tier = usage['tier'] ?? 'free';
        
        setState(() {
          _currentTier = tier;
          selectedTier = tier;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle case where user isn't authenticated yet (during registration flow)
      // Don't set _currentTier so button stays enabled
      print('Could not load subscription (might be during registration): $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getPlans(AppLocalizations l10n) => [
    {
      'tier': 'free',
      'name': l10n.free,
      'price': '€0',
      'period': '/${l10n.forever}',
      'description': l10n.tryAiCoach,
      'features': [
        l10n.aiMessagesPerMonth(10),
        l10n.unlimitedPartnerMessaging,
        l10n.basicExercises,
      ],
      'color': Colors.grey,
      'popular': false,
    },
    {
      'tier': 'essential',
      'name': l10n.essential,
      'price': '€9.99',
      'period': l10n.perMonth,
      'description': l10n.regularSupport,
      'features': [
        l10n.aiMessagesPerMonth(100),
        l10n.unlimitedPartnerMessaging,
        l10n.allFreeFeatures,
        l10n.guidedExercises,
        l10n.conversationSummaries,
      ],
      'color': Colors.blue,
      'popular': false,
    },
    {
      'tier': 'premium',
      'name': l10n.premium,
      'price': '€19.99',
      'period': l10n.perMonth,
      'description': l10n.unlimitedAccess,
      'features': [
        l10n.unlimitedAiMessages,
        l10n.unlimitedPartnerMessaging,
        l10n.allEssentialFeatures,
        l10n.guidedExercises,
        l10n.prioritySupport,
        l10n.advancedInsights,
      ],
      'color': Colors.purple,
      'popular': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plans = _getPlans(l10n);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chooseYourPlan),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    l10n.startYourJourneyTogether,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.choosePlanDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final isSelected = selectedTier == plan['tier'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTier = plan['tier'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? plan['color']
                              : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: isSelected
                            ? plan['color'].withOpacity(0.05)
                            : Colors.white,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: plan['color'].withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: plan['color'].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getPlanIcon(plan['tier']),
                                        color: plan['color'],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan['name'],
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            plan['description'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: plan['color'],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      plan['price'],
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: plan['color'],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 6, left: 4),
                                      child: Text(
                                        plan['period'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...((plan['features'] as List<String>)
                                    .map((feature) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: plan['color'],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            feature,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList()),
                              ],
                            ),
                          ),
                          if (plan['popular'] as bool && (_currentTier == null || plan['tier'] != _currentTier))
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: plan['color'],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l10n.popular,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (_currentTier != null && plan['tier'] == _currentTier)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l10n.currentPlan,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    if (selectedTier != 'free') ...[
                      // Billing period toggle
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedBillingPeriod = 'monthly';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selectedBillingPeriod == 'monthly'
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    l10n.monthly,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: selectedBillingPeriod == 'monthly'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedBillingPeriod = 'annual';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selectedBillingPeriod == 'annual'
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        l10n.annual,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: selectedBillingPeriod == 'annual'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        l10n.save20,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l10n.freeTrialInfo,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isProcessingPayment || (_currentTier != null && selectedTier == _currentTier)) 
                            ? null 
                            : _handleSubscribe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: plans.firstWhere(
                              (p) => p['tier'] == selectedTier)['color'],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isProcessingPayment
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _currentTier != null && selectedTier == _currentTier
                                    ? l10n.currentPlanButton
                                    : (selectedTier == 'free'
                                        ? l10n.continueWithFree
                                        : l10n.startFreeTrial),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _currentTier != null && selectedTier == _currentTier 
                                      ? Colors.grey[600] 
                                      : Colors.white,
                                ),
                              ),
                      ),
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

  Future<void> _handleSubscribe() async {
    if (selectedTier == 'free') {
      Navigator.pop(context, selectedTier);
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final result = await _paymentService.createCheckoutSession(
        tier: selectedTier,
        billingPeriod: selectedBillingPeriod,
      );

      if (result['success'] == true) {
        final url = result['url'];
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            // Close this screen as payment is handled in browser
            if (mounted) {
              Navigator.pop(context);
            }
          } else {
            if (mounted) {
              showErrorSnackBar(context, 'Could not open payment page');
            }
          }
        }
      } else {
        if (mounted) {
          showErrorSnackBar(context, result['message'] ?? 'Failed to start checkout');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  IconData _getPlanIcon(String tier) {
    switch (tier) {
      case 'free':
        return Icons.favorite_border;
      case 'essential':
        return Icons.favorite;
      case 'premium':
        return Icons.workspace_premium;
      default:
        return Icons.favorite;
    }
  }
}
