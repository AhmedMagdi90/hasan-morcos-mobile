class CustomerNotification {
  const CustomerNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.orderId,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final int? orderId;
  final String createdAt;

  factory CustomerNotification.fromJson(Map<String, dynamic> json) {
    return CustomerNotification(
      id: json['id'] as int,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      orderId: json['order_id'] as int?,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
