import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/app_bar.dart';
import 'subscription_providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  int _selectedPlan = 0; // 0 for monthly, 1 for yearly

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedPlan = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final subscriptionDetails = ref.watch(subscriptionDetailsProvider);
    final productsAsync = ref.watch(productsProvider);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Premium Subscription',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium banner
              _buildPremiumBanner(isPremium),
              
              // Current subscription status
              if (isPremium) Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSubscriptionStatus(subscriptionDetails),
              ),
              
              // Premium features section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildFeaturesSection(),
              ),
              
              // Subscription options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  isPremium ? 'Manage Subscription' : 'Choose a Plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              
              // Subscription plans
              productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                            const SizedBox(height: 16),
                            const Text('No subscription products found.'),
                            const SizedBox(height: 8),
                            if (!isPremium)
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(subscriptionServiceProvider).loadProducts();
                                },
                                child: const Text('Retry'),
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Filter products by type
                  final monthlyProduct = products.firstWhere(
                    (p) => p.id.contains('monthly'),
                    orElse: () => products.first,
                  );
                  
                  final yearlyProduct = products.firstWhere(
                    (p) => p.id.contains('yearly'),
                    orElse: () => products.last,
                  );

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Tab bar for subscription options
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(30),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Theme.of(context).primaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha(50),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            tabs: [
                              Tab(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Monthly'),
                                    Text(
                                      monthlyProduct.price,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Yearly'),
                                    RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: yearlyProduct.price,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const TextSpan(
                                            text: ' (Save 20%)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Subscription features with animated indicators
                        _buildSubscriptionFeatures(),
                        
                        const SizedBox(height: 24),
                        
                        // Purchase button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: isPremium 
                            ? OutlinedButton.icon(
                                onPressed: _manageSubscription,
                                icon: const Icon(Icons.settings),
                                label: const Text('Manage in App Store'),
                              )
                            : ElevatedButton(
                                onPressed: _isLoading 
                                  ? null 
                                  : () => _purchaseSubscription(
                                      _selectedPlan == 0 ? monthlyProduct : yearlyProduct,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Subscribe ${_selectedPlan == 0 ? 'Monthly' : 'Yearly'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                              ),
                        ),
                        
                        // Restore purchases button
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _restorePurchases,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore Purchases'),
                        ),
                        
                        // Cancel subscription button (only for premium users)
                        if (isPremium) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _isLoading ? null : _showCancelDialog,
                            child: const Text(
                              'Cancel Subscription',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        
                        // Legal info
                        const SizedBox(height: 24),
                        const Text(
                          'Subscriptions will automatically renew unless canceled within 24 hours before the end of the current period. '
                          'You can cancel anytime in your App Store settings. For more information, see our Terms and Privacy Policy.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading subscription plans: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.refresh(productsProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPremiumBanner(bool isPremium) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPremium 
            ? [Colors.purple.shade700, Colors.indigo.shade700]
            : [Colors.grey.shade600, Colors.blueGrey.shade700],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.star : Icons.star_border,
                size: 40,
                color: isPremium ? Colors.amber : Colors.white70,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isPremium ? 'Premium Member' : 'Upgrade to Premium',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isPremium
                ? 'Enjoy all premium features and benefits!'
                : 'Unlock the full potential of Lexa',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withAlpha(220),
            ),
          ),
          if (isPremium)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Thanks for supporting us!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStatus(Map<String, dynamic> details) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Subscription',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${details['period']} Premium',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildStatusItem('Status', details['status']),
            _buildStatusItem('Renews On', details['expiryDate']),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: label == 'Status' && value == 'Active' 
                  ? Colors.green 
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.mic,
        'title': 'Unlimited Voice Notes',
        'description': 'Create as many voice notes as you need',
      },
      {
        'icon': Icons.high_quality,
        'title': 'High-Quality Audio',
        'description': 'Record in higher quality for better transcription',
      },
      {
        'icon': Icons.sync,
        'title': 'Cloud Sync',
        'description': 'Sync your notes across all your devices',
      },
      {
        'icon': Icons.folder_special,
        'title': 'Premium Templates',
        'description': 'Access premium export templates',
      },
      {
        'icon': Icons.ad_units_rounded,
        'title': 'No Advertisements',
        'description': 'Enjoy a completely ad-free experience',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Features',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => _buildFeatureItem(
          icon: feature['icon'] as IconData,
          title: feature['title'] as String,
          description: feature['description'] as String,
        )),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionFeatures() {
    final features = [
      'Unlimited voice recordings',
      'Advanced transcription options',
      'Premium export templates',
      'Priority customer support',
      'No advertisements',
      'Offline access to all features',
    ];

    return Column(
      children: features.map((feature) => 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(feature),
              ),
            ],
          ),
        ),
      ).toList(),
    );
  }

  Future<void> _purchaseSubscription(ProductDetails product) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await ref.read(subscriptionServiceProvider).purchaseSubscription(product);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing your purchase...'),
            backgroundColor: Colors.blue,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start purchase'),
            backgroundColor: Colors.red,
          ),
        );
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await ref.read(subscriptionServiceProvider).restorePurchases();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No purchases to restore'),
            backgroundColor: Colors.orange,
          ),
        );
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'To cancel your subscription, you\'ll need to do this through your App Store or Google Play account settings. '
          'Would you like instructions on how to do this?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCancellationInstructions();
            },
            child: const Text('SHOW INSTRUCTIONS'),
          ),
        ],
      ),
    );
  }
  
  void _showCancellationInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Cancel'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'On iOS:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('1. Open Settings App\n'
                  '2. Tap your Apple ID\n'
                  '3. Tap Subscriptions\n'
                  '4. Select VoiceNotes\n'
                  '5. Tap Cancel Subscription'),
              const SizedBox(height: 16),
              const Text(
                'On Android:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('1. Open Google Play Store\n'
                  '2. Tap your profile icon\n'
                  '3. Tap Payments & subscriptions\n'
                  '4. Tap Subscriptions\n'
                  '5. Select VoiceNotes\n'
                  '6. Tap Cancel subscription'),
                  ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
  
  // Open the subscription management page in App Store/Play Store
  Future<void> _manageSubscription() async {
    if (Platform.isIOS) {
      // iOS: Open App Store subscription management
      const url = 'itms-apps://apps.apple.com/account/subscriptions';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open App Store subscription settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (Platform.isAndroid) {
      // Android: Open Play Store subscription management
      const url = 'https://play.google.com/store/account/subscriptions';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Google Play subscription settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}