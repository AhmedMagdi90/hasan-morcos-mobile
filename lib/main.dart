import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String savedCustomerSessionKey = 'customer_session_v1';
  static const String savedBranchKey = 'selected_branch_v1';

  final ApiClient apiClient = const ApiClient();
  final List<CartItem> cartItems = [];
  bool isLoadingSession = true;
  CustomerSession? customerSession;
  Branch? selectedBranch;
  int? lastOrderId;

  double get cartTotal => cartItems.fold(0, (total, item) => total + item.lineTotal);

  @override
  void initState() {
    super.initState();
    loadSavedSession();
  }

  Future<void> loadSavedSession() async {
    CustomerSession? savedSession;
    Branch? savedBranch;

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawSession = prefs.getString(savedCustomerSessionKey);
      final rawBranch = prefs.getString(savedBranchKey);

      if (rawSession != null && rawSession.isNotEmpty) {
        final decoded = jsonDecode(rawSession);

        if (decoded is Map<String, dynamic>) {
          final parsedSession = CustomerSession.fromJson(decoded);
          if (parsedSession.isValid) {
            savedSession = parsedSession;
          }
        }
      }

      if (savedSession != null && rawBranch != null && rawBranch.isNotEmpty) {
        final decoded = jsonDecode(rawBranch);

        if (decoded is Map<String, dynamic>) {
          final parsedBranch = Branch.fromJson(decoded);
          if (parsedBranch.isValid) {
            savedBranch = parsedBranch;
          }
        }
      }
    } catch (error) {
      debugPrint('Cannot load saved app session: $error');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      customerSession = savedSession;
      selectedBranch = savedBranch;
      isLoadingSession = false;
    });
  }

  Future<void> saveCustomerSession(CustomerSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(savedCustomerSessionKey, jsonEncode(session.toJson()));
    } catch (error) {
      debugPrint('Cannot save customer session: $error');
    }
  }

  Future<void> saveSelectedBranch(Branch branch) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(savedBranchKey, jsonEncode(branch.toJson()));
    } catch (error) {
      debugPrint('Cannot save selected branch: $error');
    }
  }

  Future<void> clearSavedBranch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(savedBranchKey);
    } catch (error) {
      debugPrint('Cannot clear selected branch: $error');
    }
  }

  Future<void> clearSavedCustomerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(savedCustomerSessionKey);
      await prefs.remove(savedBranchKey);
    } catch (error) {
      debugPrint('Cannot clear customer session: $error');
    }
  }

  void selectBranch(Branch branch) {
    saveSelectedBranch(branch);

    setState(() {
      selectedBranch = branch;
      cartItems.clear();
      lastOrderId = null;
    });
  }

  void changeBranch() {
    clearSavedBranch();

    setState(() {
      selectedBranch = null;
      cartItems.clear();
      lastOrderId = null;
    });
  }

  void login(CustomerSession session) {
    saveCustomerSession(session);

    setState(() {
      customerSession = session;
    });
  }

  void logout() {
    clearSavedCustomerSession();

    setState(() {
      customerSession = null;
      selectedBranch = null;
      cartItems.clear();
      lastOrderId = null;
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
    if (isLoadingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        onLogout: logout,
      );
    }

    return ProductListScreen(
      apiClient: apiClient,
      branch: selectedBranch!,
      cartCount: cartItems.fold(0, (count, item) => count + item.quantity),
      cartTotal: cartTotal,
      lastOrderId: lastOrderId,
      customerSession: customerSession!,
      onBranchChange: changeBranch,
      onLogout: logout,
      onAddToCart: addToCart,
      onOpenCart: openCart,
    );
  }
}
