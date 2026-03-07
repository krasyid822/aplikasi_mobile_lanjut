import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'week1_firebase_options.dart';
import 'week3_admin_role_service.dart';
import 'week3_admin_login_page.dart';
import 'week3_admin_dashboard.dart';
import 'week3_cart_page.dart';
import 'week3_customer_dashboard_page.dart';
import 'week3_customer_orders_page.dart';
import 'week3_product_list.dart';
import 'week3_shop_controller.dart';
import 'week3_supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ensureWeek3SupabaseInitialized();
  runApp(const Week3App());
}

class Week3App extends StatelessWidget {
  const Week3App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Week3ShopController(),
      child: const AdaptiveMaterialApp(
        title: 'Task 3 - Firebase Storage',
        home: Week3ShellPage(),
      ),
    );
  }
}

class Week3ShellPage extends StatefulWidget {
  const Week3ShellPage({super.key});

  @override
  State<Week3ShellPage> createState() => _Week3ShellPageState();
}

class _Week3ShellPageState extends State<Week3ShellPage> {
  final _roleService = const Week3AdminRoleService();
  late final StreamSubscription<User?> _authSubscription;
  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<Week3ShopController>().bindToCustomer(
        FirebaseAuth.instance.currentUser?.uid,
      );
    });
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      context.read<Week3ShopController>().bindToCustomer(user?.uid);
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logout berhasil')));
  }

  void _openCart() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const Week3CartPage()));
  }

  void _openCustomerOrders() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const Week3CustomerOrdersPage()));
  }

  Widget _buildSecondaryBody({required User? user, required bool isAdmin}) {
    if (user == null) {
      return const Week3AdminLoginPage();
    }

    if (isAdmin) {
      return const AdminDashboard();
    }

    return Week3CustomerDashboardPage(
      onOpenCart: _openCart,
      onOpenOrders: _openCustomerOrders,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        final cartCount = context.watch<Week3ShopController>().totalItems;
        return FutureBuilder<bool>(
          future: user == null
              ? Future<bool>.value(false)
              : _roleService.isAdmin(user.uid),
          builder: (context, adminSnapshot) {
            final isAdmin = adminSnapshot.data ?? false;
            final secondaryTitle = user == null
                ? 'Login'
                : isAdmin
                ? 'Dashboard Admin'
                : 'Profil Pelanggan';
            final secondarySubtitle = user == null
                ? 'Masuk untuk melanjutkan sebagai pelanggan atau admin'
                : isAdmin
                ? 'Produk, admin role, dan order management'
                : 'Akun, riwayat order, dan ringkasan pelanggan';

            return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedIndex == 0 ? 'Belanja Produk' : secondaryTitle,
                    ),
                    Text(
                      _selectedIndex == 0
                          ? 'Katalog produk, keranjang, dan checkout'
                          : secondarySubtitle,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                actions: [
                  if (_selectedIndex == 0)
                    IconButton(
                      onPressed: _openCustomerOrders,
                      icon: const Icon(Icons.receipt_long_outlined),
                    ),
                  if (_selectedIndex == 0)
                    IconButton(
                      onPressed: _openCart,
                      icon: Badge(
                        isLabelVisible: cartCount > 0,
                        label: Text('$cartCount'),
                        child: const Icon(Icons.shopping_cart_outlined),
                      ),
                    ),
                  if (_selectedIndex == 1 && user != null)
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                    ),
                ],
              ),
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  const ProductList(),
                  _buildSecondaryBody(user: user, isAdmin: isAdmin),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    label: 'Belanja',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      user == null
                          ? Icons.login
                          : isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.person_outline,
                    ),
                    label: user == null
                        ? 'Login'
                        : isAdmin
                        ? 'Admin'
                        : 'Profil',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
