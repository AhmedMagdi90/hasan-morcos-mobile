import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/cart_item.dart';
import '../models/customer_session.dart';
import '../services/api_client.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    required this.apiClient,
    required this.branch,
    required this.cartItems,
    required this.cartTotal,
    required this.customerSession,
    required this.onQuantityChanged,
    required this.onOrderCreated,
    super.key,
  });

  final ApiClient apiClient;
  final Branch branch;
  final List<CartItem> cartItems;
  final double cartTotal;
  final CustomerSession? customerSession;
  final void Function(CartItem item, int quantity) onQuantityChanged;
  final ValueChanged<int> onOrderCreated;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> submitOrder() async {
    final requiresGuestData = widget.customerSession == null;

    if (requiresGuestData && (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty)) {
      showMessage('Customer name and phone are required.');
      return;
    }

    if (widget.cartItems.isEmpty) {
      showMessage('Cart is empty.');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final orderId = await widget.apiClient.createOrder(
        branchId: widget.branch.id,
        customerName: widget.customerSession?.name ?? nameController.text.trim(),
        customerPhone: widget.customerSession?.phone ?? phoneController.text.trim(),
        shippingAddress: addressController.text.trim(),
        items: widget.cartItems,
        authToken: widget.customerSession?.authToken,
      );
      widget.onOrderCreated(orderId);
    } catch (error) {
      showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void changeQuantity(CartItem item, int quantity) {
    widget.onQuantityChanged(item, quantity);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.cartItems.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No items in cart.'),
              ),
            )
          else
            ...widget.cartItems.map((item) {
              return Card(
                child: ListTile(
                  title: Text(item.product.displayName),
                  subtitle: Text('${item.product.price.toStringAsFixed(2)} EGP - ${item.lineTotal.toStringAsFixed(2)} EGP'),
                  trailing: SizedBox(
                    width: 132,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => changeQuantity(item, item.quantity - 1),
                          icon: const Icon(Icons.remove),
                        ),
                        Text(item.quantity.toString()),
                        IconButton(
                          onPressed: () => changeQuantity(item, item.quantity + 1),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          Text(
            'Total: ${widget.cartTotal.toStringAsFixed(2)} EGP',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          if (widget.customerSession == null) ...[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Customer name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Customer phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
          ] else ...[
            Card(
              child: ListTile(
                title: Text(widget.customerSession!.name),
                subtitle: Text(widget.customerSession!.phone),
                leading: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: addressController,
            decoration: const InputDecoration(labelText: 'Shipping address'),
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isSubmitting ? null : submitOrder,
            child: Text(isSubmitting ? 'Creating...' : 'Create Reservation Order'),
          ),
        ],
      ),
    );
  }
}

