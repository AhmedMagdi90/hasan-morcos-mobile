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

  double get cartTotal => widget.cartItems.fold(0, (total, item) => total + item.lineTotal);

  int get cartCount => widget.cartItems.fold(0, (count, item) => count + item.quantity);

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> submitOrder() async {
    if (widget.cartItems.isEmpty) {
      showMessage('Cart is empty.');
      return;
    }

    final requiresGuestData = widget.customerSession == null;

    if (requiresGuestData && (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty)) {
      showMessage('Customer name and phone are required.');
      return;
    }

    if (addressController.text.trim().isEmpty) {
      showMessage('Shipping address is required.');
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

  Future<void> confirmClearCart() async {
    if (widget.cartItems.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('This removes all products from the current cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final item in List<CartItem>.from(widget.cartItems)) {
        widget.onQuantityChanged(item, 0);
      }

      if (mounted) {
        setState(() {});
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

  Widget buildCartItem(CartItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.product.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: () => changeQuantity(item, 0),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${item.product.price.toStringAsFixed(2)} EGP each'),
            Text('Available stock: ${item.product.availableQuantity}'),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.outlined(
                  onPressed: () => changeQuantity(item, item.quantity - 1),
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    item.quantity.toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton.outlined(
                  onPressed: item.quantity < item.product.availableQuantity
                      ? () => changeQuantity(item, item.quantity + 1)
                      : null,
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                Text(
                  '${item.lineTotal.toStringAsFixed(2)} EGP',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          IconButton(
            tooltip: 'Clear cart',
            onPressed: widget.cartItems.isEmpty ? null : confirmClearCart,
            icon: const Icon(Icons.remove_shopping_cart_outlined),
          ),
        ],
      ),
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
            ...widget.cartItems.map(buildCartItem),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: Text('Total: ${cartTotal.toStringAsFixed(2)} EGP'),
              subtitle: Text('$cartCount items from ${widget.branch.displayName}'),
              leading: const Icon(Icons.receipt_long),
            ),
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
            decoration: const InputDecoration(
              labelText: 'Shipping address',
              helperText: 'Required for delivery and staff follow-up.',
            ),
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isSubmitting || widget.cartItems.isEmpty ? null : submitOrder,
            child: Text(isSubmitting ? 'Creating...' : 'Create Reservation Order'),
          ),
        ],
      ),
    );
  }
}
