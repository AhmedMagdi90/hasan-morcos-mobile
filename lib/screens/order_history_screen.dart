import 'package:flutter/material.dart';

import '../models/customer_session.dart';
import '../models/order_summary.dart';
import '../services/api_client.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({
    required this.apiClient,
    required this.customerSession,
    super.key,
  });

  final ApiClient apiClient;
  final CustomerSession customerSession;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<OrderSummary>> ordersFuture;

  @override
  void initState() {
    super.initState();
    ordersFuture = widget.apiClient.fetchMyOrders(widget.customerSession.authToken);
  }

  void refresh() {
    setState(() {
      ordersFuture = widget.apiClient.fetchMyOrders(widget.customerSession.authToken);
    });
  }

  void openOrder(OrderSummary order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          apiClient: widget.apiClient,
          orderId: order.orderId,
          authToken: widget.customerSession.authToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<OrderSummary>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Cannot load orders: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }

          return RefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  child: ListTile(
                    title: Text('ORDER-${order.orderId}'),
                    subtitle: Text('${order.branchName} - ${order.status}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${order.total.toStringAsFixed(2)} EGP'),
                        if (order.remainingAmount > 0)
                          Text('Remaining ${order.remainingAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    onTap: () => openOrder(order),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: orders.length,
            ),
          );
        },
      ),
    );
  }
}
