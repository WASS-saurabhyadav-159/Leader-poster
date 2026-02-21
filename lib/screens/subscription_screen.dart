import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/models/subscription_plan.dart';
import '../core/network/api_service.dart';
import '../core/utils/error_handler.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiService _apiService = ApiService();
  late Razorpay _razorpay;
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentOrderId;
  String? _currentPlanId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchPlans();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.fetchSubscriptionPlans(
        limit: 10,
        offset: 0,
        keyword: '',
      );

      setState(() {
        _plans = response.map((json) => SubscriptionPlan.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      final errorMsg = await ErrorHandler.getErrorMessage(e);
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  Future<void> _initiatePayment(SubscriptionPlan plan) async {
    try {
      setState(() => _isLoading = true);

      // Create order
      final orderResponse = await _apiService.createPaymentOrder(
        amount: plan.price.toInt(),
      );

      _currentOrderId = orderResponse['id'];
      _currentPlanId = plan.id;

      // Open Razorpay checkout
      var options = {
        'key': 'rzp_test_DHAXbhQDgKoIAN', // Replace with your Razorpay key
        'amount': orderResponse['amount'],
        'currency': orderResponse['currency'],
        'name': 'Premium Subscription',
        'description': '${plan.packageName} - ${plan.duration} Days',
        'order_id': orderResponse['id'],
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {
          'color': '#4E6CF4',
        }
      };

      _razorpay.open(options);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      final errorMsg = await ErrorHandler.getErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMsg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      setState(() => _isLoading = true);

      await _apiService.savePayment(
        planId: _currentPlanId!,
        amount: _plans.firstWhere((p) => p.id == _currentPlanId).price.toInt(),
        status: 'Success',
        orderId: _currentOrderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      final errorMsg = await ErrorHandler.getErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving payment: $errorMsg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External wallet: ${response.walletName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leadingWidth: 40,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          "Premium",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPlans,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _plans.isEmpty
                  ? const Center(child: Text('No plans available'))
                  : RefreshIndicator(
                      onRefresh: _fetchPlans,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _plans.length,
                        itemBuilder: (context, index) {
                          final plan = _plans[index];
                          return PlanCard(
                            plan: plan,
                            gradient: _getGradientForIndex(index),
                            onBuyNow: () => _initiatePayment(plan),
                          );
                        },
                      ),
                    ),
    );
  }

  List<Color> _getGradientForIndex(int index) {
    final gradients = [
      [const Color(0xFF4E6CF4), const Color(0xFF6C8CFF)],
      [const Color(0xFF1BB5C4), const Color(0xFF42D6E6)],
      [const Color(0xFF1FAE8B), const Color(0xFF4BD3AF)],
      [const Color(0xFF8E5CF7), const Color(0xFFB388FF)],
    ];
    return gradients[index % gradients.length];
  }
}

class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final List<Color> gradient;
  final VoidCallback onBuyNow;

  const PlanCard({
    super.key,
    required this.plan,
    required this.gradient,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(
                  plan.packageName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${plan.duration} DAYS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "INR ₹${plan.price}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// BENEFITS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              plan.benefits,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),

          /// BUY NOW
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onBuyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gradient.first,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "BUY NOW",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
