class PaymentHistory {
  final String id;
  final String planId;
  final String accountId;
  final String transactionId;
  final String invoiceNumber;
  final String orderId;
  final String signature;
  final String paymentId;
  final int amount;
  final String status;
  final String? converterId;
  final String type;
  final String createdAt;
  final String updatedAt;

  PaymentHistory({
    required this.id,
    required this.planId,
    required this.accountId,
    required this.transactionId,
    required this.invoiceNumber,
    required this.orderId,
    required this.signature,
    required this.paymentId,
    required this.amount,
    required this.status,
    this.converterId,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'] ?? '',
      planId: json['planId'] ?? '',
      accountId: json['accountId'] ?? '',
      transactionId: json['transactionId'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      orderId: json['orderId'] ?? '',
      signature: json['signature'] ?? '',
      paymentId: json['paymentId'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? '',
      converterId: json['converterId'],
      type: json['type'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}
