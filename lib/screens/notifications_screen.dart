import 'package:flutter/material.dart';

import '../models/customer_notification.dart';
import '../models/customer_session.dart';
import '../services/api_client.dart';
import 'order_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    required this.apiClient,
    required this.customerSession,
    super.key,
  });

  final ApiClient apiClient;
  final CustomerSession customerSession;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<CustomerNotification>> notificationsFuture;

  @override
  void initState() {
    super.initState();
    notificationsFuture = widget.apiClient.fetchMyNotifications(widget.customerSession.authToken);
  }

  void refresh() {
    setState(() {
      notificationsFuture = widget.apiClient.fetchMyNotifications(widget.customerSession.authToken);
    });
  }

  Future<void> openNotification(CustomerNotification notification) async {
    if (!notification.isRead) {
      await widget.apiClient.markNotificationRead(
        authToken: widget.customerSession.authToken,
        notificationId: notification.id,
      );
      refresh();
    }

    if (!mounted || notification.orderId == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          apiClient: widget.apiClient,
          orderId: notification.orderId!,
          authToken: widget.customerSession.authToken,
        ),
      ),
    );
  }

  IconData iconForType(String type) {
    if (type == 'payment') {
      return Icons.payments;
    }

    if (type == 'shipment') {
      return Icons.local_shipping;
    }

    return Icons.receipt_long;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<CustomerNotification>>(
        future: notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Cannot load notifications: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return RefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Card(
                  child: ListTile(
                    leading: Icon(iconForType(notification.type)),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notification.message),
                    trailing: notification.isRead
                        ? null
                        : const Icon(Icons.circle, size: 12, color: Colors.blue),
                    onTap: () => openNotification(notification),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: notifications.length,
            ),
          );
        },
      ),
    );
  }
}
