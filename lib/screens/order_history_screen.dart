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

  Future<void> openOrder(OrderSummary order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          apiClient: widget.apiClient,
          orderId: order.orderId,
          authToken: widget.customerSession.authToken,
        ),
      ),
    );

    if (mounted) {
      refresh();
    }
  }

  Color statusColor(OrderSummary order) {
    switch (order.status) {
      case 'reserved':
        return Colors.blue;
      case 'deposit_pending':
        return Colors.orange;
      case 'deposit_confirmed':
      case 'fully_paid':
        return Colors.green;
      case 'sent_to_shipment':
        return Colors.purple;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
                final color = statusColor(order);

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => openOrder(order),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ORDER-${order.orderId}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(order.branchName),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(order.statusLabel),
                            backgroundColor: color.withOpacity(0.12),
                            side: BorderSide(color: color.withOpacity(0.35)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: Text('Total: ${order.total.toStringAsFixed(2)} EGP')),
                              Expanded(child: Text('Paid: ${order.paidAmount.toStringAsFixed(2)} EGP')),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              order.remainingAmount > 0
                                  ? 'Remaining: ${order.remainingAmount.toStringAsFixed(2)} EGP'
                                  : 'No remaining payment',
                            ),
                          ),
                        ],
                      ),
                    ),
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
