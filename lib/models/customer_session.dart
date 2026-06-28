class CustomerSession {
  const CustomerSession({
    required this.authToken,
    required this.customerId,
    required this.name,
    required this.phone,
  });

  final String authToken;
  final int customerId;
  final String name;
  final String phone;

  factory CustomerSession.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>? ?? {};

    return CustomerSession(
      authToken: json['auth_token']?.toString() ?? '',
      customerId: customer['id'] as int? ?? 0,
      name: customer['name']?.toString() ?? '',
      phone: customer['phone']?.toString() ?? '',
    );
  }
}
