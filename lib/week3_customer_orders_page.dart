import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'week3_order_model.dart';
import 'week3_order_status_ui.dart';
import 'week3_product_service.dart';

class Week3CustomerOrdersPage extends StatelessWidget {
  const Week3CustomerOrdersPage({
    super.key,
    this.service = const Week3ProductService(),
  });

  final Week3ProductService service;

  Widget _buildActivityTimeline(BuildContext context, Week3Order order) {
    if (order.activities.isEmpty) {
      return const SizedBox.shrink();
    }

    final activities = order.activities.reversed.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktivitas Order', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...activities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: activity.status == null
                        ? Theme.of(context).colorScheme.primary
                        : week3OrderStatusColors(
                            context,
                            activity.status!,
                          ).foreground,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activity.actor} • ${week3FormatOrderTimestamp(activity.timestamp)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if ((activity.note ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(activity.note!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCancellation(
    BuildContext context,
    Week3Order order,
  ) async {
    final isDirectCancellation = week3CanCustomerCancelDirectly(order.status);
    final isRequestCancellation = week3CanCustomerRequestCancellation(
      order.status,
    );

    if (!isDirectCancellation && !isRequestCancellation) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isDirectCancellation ? 'Batalkan order?' : 'Ajukan pembatalan?',
          ),
          content: Text(
            isDirectCancellation
                ? 'Order dengan status baru akan langsung dibatalkan.'
                : 'Order ini tidak lagi berstatus baru. Sistem akan mengirim permohonan pembatalan dan admin yang menentukan hasil akhirnya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tutup'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isDirectCancellation ? 'Batalkan Sekarang' : 'Kirim Permohonan',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await service.submitCustomerCancellation(order);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDirectCancellation
                ? 'Order berhasil dibatalkan'
                : 'Permohonan pembatalan berhasil dikirim ke admin',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Aksi pembatalan gagal: $e')));
    }
  }

  Widget _buildOrderCard(BuildContext context, Week3Order order) {
    final showCancelAction =
        week3CanCustomerCancelDirectly(order.status) ||
        week3CanCustomerRequestCancellation(order.status);

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(order.customerName),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Rp ${order.totalPrice.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Week3OrderStatusBadge(status: order.status, compact: true),
                  if (order.status == 'selesai' && order.completedAt != null)
                    Week3OrderExpiryBadge(
                      completedAt: order.completedAt,
                      compact: true,
                    ),
                  if (order.createdAt != null)
                    Chip(
                      label: Text(week3FormatOrderTimestamp(order.createdAt)),
                    ),
                ],
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customerAddress),
                const SizedBox(height: 12),
                if (order.status == 'permohonan_batal')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Permohonan pembatalan sudah dikirim. Admin akan menentukan apakah order dibatalkan atau tetap dilanjutkan.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                if (order.status == 'dibatalkan')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Order ini sudah dibatalkan dan masuk ke riwayat.',
                    ),
                  ),
                if (order.status == 'permohonan_batal' ||
                    order.status == 'dibatalkan' ||
                    order.status == 'selesai')
                  const SizedBox(height: 12),
                ...order.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: item.imageUrl.isEmpty
                        ? const SizedBox(width: 48, height: 48)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item.imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.quantity} x Rp ${item.price.toStringAsFixed(0)}',
                    ),
                    trailing: Text('Rp ${item.subtotal.toStringAsFixed(0)}'),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActivityTimeline(context, order),
                if (showCancelAction) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: order.status == 'baru'
                        ? FilledButton.icon(
                            onPressed: () =>
                                _handleCancellation(context, order),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Batalkan Order'),
                          )
                        : OutlinedButton.icon(
                            onPressed: () =>
                                _handleCancellation(context, order),
                            icon: const Icon(Icons.gpp_maybe_outlined),
                            label: const Text('Ajukan Pembatalan'),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Week3Order> orders,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(emptyMessage),
            ),
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderCard(context, order),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Order')),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Riwayat order butuh login',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          /* const Text(
                            'Order tamu tetap bisa checkout, tetapi tidak muncul di riwayat pelanggan. Login Firebase terlebih dahulu jika ingin melihat order pribadi.',
                            textAlign: TextAlign.center,
                          ), */
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : StreamBuilder<List<Week3Order>>(
              stream: service.watchOrdersForCustomer(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat riwayat order: ${snapshot.error}',
                    ),
                  );
                }

                final orders = snapshot.data ?? const <Week3Order>[];
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('Belum ada order yang terkait dengan akun ini'),
                  );
                }

                final currentOrders = orders
                    .where((order) => week3IsCurrentOrderStatus(order.status))
                    .toList(growable: false);
                final historyOrders = orders
                    .where((order) => !week3IsCurrentOrderStatus(order.status))
                    .toList(growable: false);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection(
                      context,
                      title: 'Current Order',
                      subtitle:
                          'Order aktif, order baru, dan order yang sedang menunggu keputusan admin.',
                      orders: currentOrders,
                      emptyMessage: 'Tidak ada current order saat ini.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      title: 'Riwayat Order',
                      subtitle:
                          'Order yang sudah selesai atau dibatalkan akan masuk ke grup ini.',
                      orders: historyOrders,
                      emptyMessage: 'Belum ada order pada riwayat.',
                    ),
                  ],
                );
              },
            ),
    );
  }
}
