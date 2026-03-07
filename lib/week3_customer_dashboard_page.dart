import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'week3_order_model.dart';
import 'week3_product_service.dart';
import 'week3_shop_controller.dart';
import 'week3_order_status_ui.dart';

class Week3CustomerDashboardPage extends StatelessWidget {
  const Week3CustomerDashboardPage({
    super.key,
    this.service = const Week3ProductService(),
    this.onOpenCart,
    this.onOpenOrders,
  });

  final Week3ProductService service;
  final VoidCallback? onOpenCart;
  final VoidCallback? onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Week3ShopController>();
    final user = FirebaseAuth.instance.currentUser;
    final greetingName = user?.email?.split('@').first ?? 'Pelanggan';

    return StreamBuilder<List<dynamic>>(
      stream: service.watchProducts(),
      builder: (context, snapshot) {
        return StreamBuilder<List<Week3Order>>(
          stream: user == null
              ? Stream<List<Week3Order>>.value(const <Week3Order>[])
              : service.watchOrdersForCustomer(user.uid),
          builder: (context, orderSnapshot) {
            final orders = orderSnapshot.data ?? const <Week3Order>[];
            final currentOrders = orders
                .where((order) => week3IsCurrentOrderStatus(order.status))
                .length;
            final orderHistory = orders.length - currentOrders;
            final latestCurrentOrder = orders
                .where((order) => week3IsCurrentOrderStatus(order.status))
                .firstOrNull;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $greetingName',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 320,
                              child: _DashboardShortcutCard(
                                title: 'Keranjang Belanja',
                                subtitle: cart.totalItems > 0
                                    ? '${cart.totalItems} item siap checkout'
                                    : 'Belum ada item di keranjang akun ini',
                                icon: Icons.shopping_cart_checkout,
                                onTap: onOpenCart,
                              ),
                            ),
                            SizedBox(
                              width: 320,
                              child: _DashboardShortcutCard(
                                title: 'Riwayat Order',
                                subtitle: orders.isNotEmpty
                                    ? '$currentOrders current, $orderHistory riwayat'
                                    : 'Belum ada order pada akun ini',
                                icon: Icons.receipt_long_outlined,
                                onTap: onOpenOrders,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      /* SizedBox(
                        width: 170,
                        child: _DashboardStatCard(
                          title: 'Produk',
                          value: '${products.length}',
                          icon: Icons.inventory_2_outlined,
                        ),
                      ), */
                      SizedBox(
                        width: 150,
                        child: _DashboardStatCard(
                          title: 'Keranjang',
                          value: '${cart.totalItems}',
                          icon: Icons.shopping_cart_outlined,
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: _DashboardStatCard(
                          title: 'Current Order',
                          value: '$currentOrders',
                          icon: Icons.timelapse_rounded,
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: _DashboardStatCard(
                          title: 'Riwayat',
                          value: '$orderHistory',
                          icon: Icons.history_rounded,
                        ),
                      ),
                    ],
                  ),
                  if (latestCurrentOrder != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Orderan Terbaru',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    latestCurrentOrder.customerName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                Week3OrderStatusBadge(
                                  status: latestCurrentOrder.status,
                                  compact: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Rp ${latestCurrentOrder.totalPrice.toStringAsFixed(0)}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Aktivitas terakhir: ${latestCurrentOrder.activities.isNotEmpty ? week3FormatOrderTimestamp(latestCurrentOrder.activities.last.timestamp) : week3FormatOrderTimestamp(latestCurrentOrder.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DashboardShortcutCard extends StatelessWidget {
  const _DashboardShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
