import 'package:flutter/material.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  String selectedTier = 'free';

  final List<Map<String, dynamic>> plans = [
    {
      'tier': 'free',
      'name': 'Free',
      'price': '€0',
      'period': '/forever',
      'description': 'Try the AI counselor',
      'features': [
        '10 AI messages per month',
        'Unlimited partner messaging',
        'Basic history (30 days)',
        'Email notifications',
      ],
      'color': Colors.grey,
      'popular': false,
    },
    {
      'tier': 'essential',
      'name': 'Essential',
      'price': '€9.99',
      'period': '/month',
      'description': 'Regular support',
      'features': [
        '100 AI messages per month',
        'Unlimited partner messaging',
        'Full conversation history',
        'Conversation summaries',
        'Priority support',
      ],
      'color': Colors.blue,
      'popular': false,
    },
    {
      'tier': 'premium',
      'name': 'Premium',
      'price': '€19.99',
      'period': '/month',
      'description': 'Unlimited access',
      'features': [
        'Unlimited AI messages',
        'Unlimited partner messaging',
        'Full conversation history',
        'Conversation summaries',
        'Guided exercises',
        'Weekly insights',
        'Priority support',
      ],
      'color': Colors.purple,
      'popular': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'Start Your Journey Together',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a plan that fits your needs. You can upgrade or cancel anytime.',
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
                          if (plan['popular'] as bool)
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
                                child: const Text(
                                  'POPULAR',
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
                    if (selectedTier != 'free')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '7-day free trial • Cancel anytime',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, selectedTier);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: plans.firstWhere(
                              (p) => p['tier'] == selectedTier)['color'],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          selectedTier == 'free'
                              ? 'Continue with Free'
                              : 'Start Free Trial',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
