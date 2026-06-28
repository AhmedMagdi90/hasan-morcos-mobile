class OrderSummary {
  const OrderSummary({
    required this.orderId,
    required this.status,
    required this.branchName,
    required this.total,
    required this.paidAmount,
    required this.remainingAmount,
    required this.createdAt,
  });

  final int orderId;
  final String status;
  final String branchName;
  final double total;
  final double paidAmount;
  final double remainingAmount;
  final String createdAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final branch = json['branch'] as Map<String, dynamic>? ?? {};

    return OrderSummary(
      orderId: json['order_id'] as int,
      status: json['status']?.toString() ?? '',
      branchName: branch['name_ar']?.toString() ?? '',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0,
      remainingAmount: double.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
