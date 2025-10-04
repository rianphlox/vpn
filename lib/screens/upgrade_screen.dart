import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({Key? key}) : super(key: key);

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  int _selectedPlan = 1; // 0: Monthly, 1: Yearly, 2: Lifetime

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Monthly',
      'price': '\$9.99',
      'period': '/month',
      'savings': '',
      'color': const Color(0xFF4FC3F7),
    },
    {
      'title': 'Yearly',
      'price': '\$59.99',
      'period': '/year',
      'savings': 'Save 50%',
      'color': const Color(0xFF4CAF50),
    },
    {
      'title': 'Lifetime',
      'price': '\$199.99',
      'period': 'one-time',
      'savings': 'Best Value',
      'color': const Color(0xFFFF9800),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPromoSection(),
                      const SizedBox(height: 30),
                      _buildPremiumFeatures(),
                      const SizedBox(height: 30),
                      _buildPricingPlans(),
                      const SizedBox(height: 30),
                      _buildUpgradeButton(),
                      const SizedBox(height: 20),
                      _buildRestorePurchase(),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
            ),
          ),
          child: const Icon(
            CupertinoIcons.star_fill,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Upgrade to Pro',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPromoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4FC3F7),
            Color(0xFF29B6F6),
            Color(0xFF0277BD),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FC3F7).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.rocket_fill,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock Premium Power',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Get unlimited access to premium servers,\nadvanced security features, and priority support',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🎉 Limited Time: 50% OFF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    final features = [
      {
        'icon': CupertinoIcons.globe,
        'title': 'Premium Servers',
        'description': 'Access to 50+ premium server locations',
      },
      {
        'icon': CupertinoIcons.speedometer,
        'title': 'Ultra-Fast Speed',
        'description': 'Up to 10x faster connection speeds',
      },
      {
        'icon': CupertinoIcons.shield_fill,
        'title': 'Advanced Security',
        'description': 'Military-grade encryption & ad blocking',
      },
      {
        'icon': CupertinoIcons.device_phone_portrait,
        'title': 'Multi-Device',
        'description': 'Connect up to 10 devices simultaneously',
      },
      {
        'icon': CupertinoIcons.headphones,
        'title': 'Priority Support',
        'description': '24/7 premium customer support',
      },
      {
        'icon': CupertinoIcons.chart_bar,
        'title': 'Usage Analytics',
        'description': 'Detailed bandwidth and usage statistics',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.star_fill,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Premium Features',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...features.map((feature) => _buildFeatureTile(
                feature['icon'] as IconData,
                feature['title'] as String,
                feature['description'] as String,
              )),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A3E), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4FC3F7),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.checkmark_alt,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingPlans() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.money_dollar,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Choose Your Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ..._plans.asMap().entries.map((entry) {
            final index = entry.key;
            final plan = entry.value;
            return _buildPlanTile(index, plan);
          }),
        ],
      ),
    );
  }

  Widget _buildPlanTile(int index, Map<String, dynamic> plan) {
    final isSelected = _selectedPlan == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F3460) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? plan['color'] : const Color(0xFF2A2A3E),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? plan['color'] : Colors.white54,
                  width: 2,
                ),
                color: isSelected ? plan['color'] : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      CupertinoIcons.checkmark,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (plan['savings'].isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: plan['color'],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            plan['savings'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        plan['price'],
                        style: TextStyle(
                          color: plan['color'],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        plan['period'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeButton() {
    final selectedPlan = _plans[_selectedPlan];

    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleUpgrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedPlan['color'],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.star_fill),
            const SizedBox(width: 12),
            Text(
              'Upgrade to ${selectedPlan['title']} - ${selectedPlan['price']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestorePurchase() {
    return Column(
      children: [
        TextButton(
          onPressed: _restorePurchase,
          child: const Text(
            'Restore Purchase',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Auto-renewable. Cancel anytime.\nPrices may vary by location.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handleUpgrade() {
    final selectedPlan = _plans[_selectedPlan];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Upgrade to Premium',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You selected the ${selectedPlan['title']} plan for ${selectedPlan['price']}${selectedPlan['period']}.\n\nThis would redirect to the payment system in a real app.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpgradeSuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPlan['color'],
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Color(0xFF4CAF50),
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Welcome to Pro!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Congratulations! You now have access to all premium features. Enjoy unlimited VPN access!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Start Using Pro'),
          ),
        ],
      ),
    );
  }

  void _restorePurchase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Restore Purchase',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'No previous purchases found. If you believe this is an error, please contact support.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF4FC3F7)),
            ),
          ),
        ],
      ),
    );
  }
}