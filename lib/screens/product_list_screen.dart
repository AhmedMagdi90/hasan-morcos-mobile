import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/customer_session.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import 'notifications_screen.dart';
import 'order_history_screen.dart';
import 'product_detail_screen.dart';
import '../widgets/product_image.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    required this.apiClient,
    required this.branch,
    required this.cartCount,
    required this.cartTotal,
    required this.customerSession,
    required this.onBranchChange,
    required this.onLogout,
    required this.onAddToCart,
    required this.onOpenCart,
    this.lastOrderId,
    super.key,
  });

  final ApiClient apiClient;
  final Branch branch;
  final int cartCount;
  final double cartTotal;
  final CustomerSession customerSession;
  final int? lastOrderId;
  final VoidCallback onBranchChange;
  final VoidCallback onLogout;
  final ValueChanged<Product> onAddToCart;
  final VoidCallback onOpenCart;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController searchController = TextEditingController();
  late Future<List<Product>> productsFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = widget.apiClient.fetchProducts(widget.branch.id);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void search() {
    setState(() {
      productsFuture = widget.apiClient.fetchProducts(widget.branch.id, query: searchController.text);
    });
  }

  Future<void> refreshProducts() async {
    final nextFuture = widget.apiClient.fetchProducts(widget.branch.id, query: searchController.text);

    setState(() {
      productsFuture = nextFuture;
    });

    try {
      await nextFuture;
    } catch (_) {
    }
  }

  void clearSearch() {
    searchController.clear();
    search();
  }

  void openOrderHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderHistoryScreen(
          apiClient: widget.apiClient,
          customerSession: widget.customerSession,
        ),
      ),
    );
  }

  void openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          apiClient: widget.apiClient,
          customerSession: widget.customerSession,
        ),
      ),
    );
  }

  void openProductDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          onAddToCart: widget.onAddToCart,
        ),
      ),
    );
  }

  Future<void> confirmSwitchCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch customer?'),
        content: const Text(
          'This clears the current cart and returns to customer login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch.displayName),
        actions: [
          IconButton(
            tooltip: 'Refresh products',
            icon: const Icon(Icons.refresh),
            onPressed: refreshProducts,
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications),
            onPressed: openNotifications,
          ),
          IconButton(
            tooltip: 'My orders',
            icon: const Icon(Icons.receipt_long),
            onPressed: openOrderHistory,
          ),
          IconButton(
            tooltip: 'Change branch',
            icon: const Icon(Icons.storefront),
            onPressed: widget.onBranchChange,
          ),
          IconButton(
            tooltip: 'Switch customer',
            icon: const Icon(Icons.logout),
            onPressed: confirmSwitchCustomer,
          ),
          IconButton(
            tooltip: 'Cart',
            icon: Badge(
              label: Text(widget.cartCount.toString()),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: widget.onOpenCart,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.customerSession.name)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search product, SKU, barcode',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (searchController.text.trim().isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: clearSearch,
                      ),
                    IconButton(
                      tooltip: 'Search',
                      icon: const Icon(Icons.search),
                      onPressed: search,
                    ),
                  ],
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => search(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Cannot load products: ${snapshot.error}'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: refreshProducts,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: refreshProducts,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('No products available.')),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: refreshProducts,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemBuilder: (context, index) {
                      final product = products[index];

                      return Card(
                        child: ListTile(
                          leading: ProductImage(imagePath: product.image),
                          title: Text(product.displayName),
                          subtitle: Text('${product.variantSku} - Stock ${product.availableQuantity}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${product.price.toStringAsFixed(2)} EGP'),
                              const SizedBox(height: 4),
                              FilledButton(
                                onPressed: product.availableQuantity > 0 ? () => widget.onAddToCart(product) : null,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          onTap: () => openProductDetail(product),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: products.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: widget.cartCount > 0 ? widget.onOpenCart : null,
            child: Text('Cart ${widget.cartCount} items - ${widget.cartTotal.toStringAsFixed(2)} EGP'),
          ),
        ),
      ),
    );
  }
}
