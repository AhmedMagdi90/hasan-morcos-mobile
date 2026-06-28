import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/branch.dart';
import '../models/cart_item.dart';
import '../models/customer_notification.dart';
import '../models/customer_session.dart';
import '../models/order_detail.dart';
import '../models/order_summary.dart';
import '../models/product.dart';

class ApiClient {
  const ApiClient();

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParameters);
  }

  Future<List<Branch>> fetchBranches() async {
    final response = await http.get(_uri('/orders/api/branches/'));
    final data = _decode(response);
    final branches = data['branches'] as List<dynamic>? ?? [];
    return branches.map((item) => Branch.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<String> requestOtp({
    required String name,
    required String phone,
  }) async {
    final response = await http.post(
      _uri('/orders/api/auth/request-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
      }),
    );
    final data = _decode(response);
    return data['dev_otp']?.toString() ?? '';
  }

  Future<CustomerSession> verifyOtp({
    required String phone,
    required String otpCode,
  }) async {
    final response = await http.post(
      _uri('/orders/api/auth/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'otp_code': otpCode,
      }),
    );
    return CustomerSession.fromJson(_decode(response));
  }

  Future<List<Product>> fetchProducts(int branchId, {String query = ''}) async {
    final response = await http.get(_uri('/orders/api/products/', {
      'branch': branchId.toString(),
      if (query.trim().isNotEmpty) 'q': query.trim(),
    }));
    final data = _decode(response);
    final products = data['products'] as List<dynamic>? ?? [];
    return products.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<int> createOrder({
    required int branchId,
    required String customerName,
    required String customerPhone,
    required String shippingAddress,
    required List<CartItem> items,
    String? authToken,
  }) async {
    final response = await http.post(
      _uri('/orders/api/orders/'),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'branch_id': branchId,
        if (authToken == null || authToken.isEmpty)
          'customer': {
            'name': customerName,
            'phone': customerPhone,
            'address': shippingAddress,
          },
        'shipping_address': shippingAddress,
        'items': items.map((item) => item.toOrderJson()).toList(),
      }),
    );
    final data = _decode(response);
    return data['order_id'] as int;
  }

  Future<List<OrderSummary>> fetchMyOrders(String authToken) async {
    final response = await http.get(
      _uri('/orders/api/my/orders/'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    final data = _decode(response);
    final orders = data['orders'] as List<dynamic>? ?? [];
    return orders.map((item) => OrderSummary.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<CustomerNotification>> fetchMyNotifications(String authToken) async {
    final response = await http.get(
      _uri('/orders/api/my/notifications/'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    final data = _decode(response);
    final notifications = data['notifications'] as List<dynamic>? ?? [];
    return notifications.map((item) => CustomerNotification.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> markNotificationRead({
    required String authToken,
    required int notificationId,
  }) async {
    final response = await http.post(
      _uri('/orders/api/my/notifications/$notificationId/read/'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    _decode(response);
  }

  Future<OrderDetail> fetchOrder(int orderId, {String? authToken}) async {
    final response = await http.get(
      _uri('/orders/api/orders/$orderId/'),
      headers: {
        if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      },
    );
    return OrderDetail.fromJson(_decode(response));
  }

  Future<OrderDetail> submitPayment({
    required int orderId,
    required double paidAmount,
    required String paymentReference,
    String? authToken,
    String? paymentProofBase64,
    String? paymentProofFilename,
  }) async {
    final response = await http.post(
      _uri('/orders/api/orders/$orderId/payment/'),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'paid_amount': paidAmount.toStringAsFixed(2),
        'payment_reference': paymentReference,
        if (paymentProofBase64 != null && paymentProofBase64.isNotEmpty) 'payment_proof_base64': paymentProofBase64,
        if (paymentProofFilename != null && paymentProofFilename.isNotEmpty) 'payment_proof_filename': paymentProofFilename,
      }),
    );
    _decode(response);
    return fetchOrder(orderId, authToken: authToken);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final data = jsonDecode(response.body.isEmpty ? '{}' : response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['error']?.toString() ?? 'Request failed');
    }

    return data;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
