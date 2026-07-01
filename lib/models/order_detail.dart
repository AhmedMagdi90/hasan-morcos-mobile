import 'order_summary.dart';

class OrderDetail {
  const OrderDetail({
    required this.orderId,
    required this.status,
    required this.total,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentReference,
    required this.paymentProofUrl,
    this.shipment,
  });

  final int orderId;
  final String status;
  final double total;
  final double paidAmount;
  final double remainingAmount;
  final String paymentReference;
  final String paymentProofUrl;
  final ShipmentDetail? shipment;

  String get statusLabel => orderStatusLabel(status);

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      orderId: json['order_id'] as int,
      status: json['status']?.toString() ?? '',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0,
      remainingAmount: double.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0,
      paymentReference: json['payment_reference']?.toString() ?? '',
      paymentProofUrl: json['payment_proof_url']?.toString() ?? '',
      shipment: json['shipment'] == null
          ? null
          : ShipmentDetail.fromJson(json['shipment'] as Map<String, dynamic>),
    );
  }
}

class ShipmentDetail {
  const ShipmentDetail({
    required this.status,
    required this.trackingNumber,
    required this.courierName,
    required this.createdAt,
  });

  final String status;
  final String trackingNumber;
  final String courierName;
  final String createdAt;

  String get statusLabel => shipmentStatusLabel(status);

  factory ShipmentDetail.fromJson(Map<String, dynamic> json) {
    return ShipmentDetail(
      status: json['status']?.toString() ?? '',
      trackingNumber: json['tracking_number']?.toString() ?? '',
      courierName: json['courier_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
