import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/payment_history.dart';
import '../core/network/api_service.dart';
import '../core/utils/error_handler.dart';
import 'InvoicePage.dart';

class SubscriptionHistoryPage extends StatefulWidget {
  const SubscriptionHistoryPage({super.key});

  @override
  State<SubscriptionHistoryPage> createState() =>
      _SubscriptionHistoryPageState();
}

class _SubscriptionHistoryPageState extends State<SubscriptionHistoryPage> {
  final ApiService _apiService = ApiService();
  List<PaymentHistory> _paymentHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _subscriptionFrom = '';
  String _subscriptionTo = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchPaymentHistory(),
      _fetchProfileDates(),
    ]);
  }

  Future<void> _fetchProfileDates() async {
    try {
      final profile = await _apiService.getProfile();
      setState(() {
        _subscriptionFrom = profile['subscriptionFrom'] ?? '';
        _subscriptionTo = profile['subscriptionTo'] ?? '';
      });
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
      await _apiService.fetchPaymentHistory(limit: 100, offset: 0);

      setState(() {
        _paymentHistory = (response['result'] as List)
            .map((json) => PaymentHistory.fromJson(json))
            .toList();
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Subscription History",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError()
          : _paymentHistory.isEmpty
          ? const Center(child: Text('No payment history found'))
          : RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _paymentHistory.length,
          itemBuilder: (context, index) {
            final payment = _paymentHistory[index];
            final isActive =
                payment.status.toUpperCase() == 'COMPLETED';

            return SubscriptionCard(
              payment: payment,
              isActive: isActive,
              formattedDate: _formatDate(payment.createdAt),
              subscriptionFrom: _formatDate(_subscriptionFrom),
              subscriptionTo: _formatDate(_subscriptionTo),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
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
            onPressed: _fetchData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final PaymentHistory payment;
  final bool isActive;
  final String formattedDate;
  final String subscriptionFrom;
  final String subscriptionTo;

  const SubscriptionCard({
    super.key,
    required this.payment,
    required this.isActive,
    required this.formattedDate,
    required this.subscriptionFrom,
    required this.subscriptionTo,
  });

  @override
  Widget build(BuildContext context) {

    // 🔥 Use API value directly
    final bool isRenewal =
        payment.type.toUpperCase() == "RENEWAL";

    final Color accentColor =
    isRenewal ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoicePage(
              invoiceId: payment.invoiceNumber,
              plan: payment.type,
              amount: "₹${payment.amount}",
              start: subscriptionFrom,
              end: subscriptionTo,
              isActive: isActive,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border(
              left: BorderSide(color: accentColor, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Top Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      payment.type, // Shows NEW or RENEWAL from API
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    isActive: isActive,
                    status: payment.status,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// Amount Section
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Amount Paid",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      "₹${payment.amount}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _infoRow("Invoice", payment.invoiceNumber),
              _infoRow("Transaction", payment.transactionId),
              _infoRow("Date", formattedDate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final String status;

  const _StatusBadge({
    required this.isActive,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
    isActive ? const Color(0xFFDBEAFE) : const Color(0xFFE2E8F0);

    final Color textColor =
    isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B);

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
