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

  String get statusLabel => orderStatusLabel(status);

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

String orderStatusLabel(String status) {
  switch (status) {
    case 'reserved':
      return 'Reserved - waiting for payment';
    case 'deposit_pending':
      return 'Payment submitted - waiting for staff confirmation';
    case 'deposit_confirmed':
      return 'Deposit confirmed';
    case 'fully_paid':
      return 'Fully paid';
    case 'sent_to_shipment':
      return 'Sent to shipment';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status.isEmpty ? 'Unknown' : status;
  }
}

String shipmentStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Preparing shipment';
    case 'shipped':
      return 'Shipped';
    case 'delivered':
      return 'Delivered';
    default:
      return status.isEmpty ? 'Not started' : status;
  }
}
