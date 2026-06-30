import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'models/branch.dart';
import 'models/cart_item.dart';
import 'models/customer_session.dart';
import 'models/product.dart';
import 'screens/branch_selection_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/login_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/product_list_screen.dart';
import 'services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.load();
  runApp(const HasanMorcosMobileApp());
}

class HasanMorcosMobileApp extends StatelessWidget {
  const HasanMorcosMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hasan & Morcos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0f172a)),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final ApiClient apiClient = const ApiClient();
  final List<CartItem> cartItems = [];
  CustomerSession? customerSession;
  Branch? selectedBranch;
  int? lastOrderId;

  double get cartTotal => cartItems.fold(0, (total, item) => total + item.lineTotal);

  void selectBranch(Branch branch) {
    setState(() {
      selectedBranch = branch;
      cartItems.clear();
      lastOrderId = null;
    });
  }

  void login(CustomerSession session) {
    setState(() {
      customerSession = session;
    });
  }

  void addToCart(Product product) {
    setState(() {
      final existingIndex = cartItems.indexWhere((item) => item.product.variantId == product.variantId);

      if (existingIndex >= 0) {
        final existing = cartItems[existingIndex];

        if (existing.quantity < existing.product.availableQuantity) {
          existing.quantity += 1;
        }
      } else {
        cartItems.add(CartItem(product: product));
      }
    });
  }

  void updateQuantity(CartItem item, int quantity) {
    setState(() {
      if (quantity <= 0) {
        cartItems.remove(item);
      } else {
        item.quantity = quantity.clamp(1, item.product.availableQuantity);
      }
    });
  }

  void openCart() {
    if (selectedBranch == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(
          apiClient: apiClient,
          branch: selectedBranch!,
          cartItems: cartItems,
          cartTotal: cartTotal,
          customerSession: customerSession,
          onQuantityChanged: updateQuantity,
          onOrderCreated: (orderId) {
            setState(() {
              lastOrderId = orderId;
              cartItems.clear();
            });
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(
                  apiClient: apiClient,
                  orderId: orderId,
                  authToken: customerSession?.authToken,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (customerSession == null) {
      return LoginScreen(
        apiClient: apiClient,
        onLoggedIn: login,
      );
    }

    if (selectedBranch == null) {
      return BranchSelectionScreen(
        apiClient: apiClient,
        onBranchSelected: selectBranch,
      );
    }

    return ProductListScreen(
      apiClient: apiClient,
      branch: selectedBranch!,
      cartCount: cartItems.fold(0, (count, item) => count + item.quantity),
      cartTotal: cartTotal,
      lastOrderId: lastOrderId,
      customerSession: customerSession!,
      onBranchChange: () => setState(() => selectedBranch = null),
      onAddToCart: addToCart,
      onOpenCart: openCart,
    );
  }
}
