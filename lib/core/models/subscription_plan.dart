class SubscriptionPlan {
  final String id;
  final String packageName;
  final String benefits;
  final int price;
  final int duration;
  final String status;
  final String createdAt;
  final String updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.packageName,
    required this.benefits,
    required this.price,
    required this.duration,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      packageName: json['packageName'] ?? '',
      benefits: json['benefits'] ?? '',
      price: json['price'] ?? 0,
      duration: json['duration'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}
