import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'week3_product_service.dart';
import 'week3_shop_controller.dart';

class Week3CartPage extends StatefulWidget {
  const Week3CartPage({super.key, this.service = const Week3ProductService()});

  final Week3ProductService service;

  @override
  State<Week3CartPage> createState() => _Week3CartPageState();
}

class _Week3CartPageState extends State<Week3CartPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  var _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _checkout(BuildContext context) async {
    final cart = context.read<Week3ShopController>();
    if (cart.items.isEmpty) return;
    if (_formKey.currentState?.validate() != true || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.service.createOrder(
        customerName: _nameController.text.trim(),
        customerAddress: _addressController.text.trim(),
        items: cart.items.toList(growable: false),
        totalPrice: cart.totalPrice,
      );
      cart.clearCart();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout berhasil disimpan')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Checkout gagal: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Week3ShopController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang Belanja')),
      body: cart.items.isEmpty
          ? const Center(child: Text('Keranjang masih kosong'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Keranjang',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${cart.totalItems} item dipilih dengan total Rp ${cart.totalPrice.toStringAsFixed(0)}.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...cart.items.map(
                  (item) => Card(
                    child: ListTile(
                      leading: item.product.imageUrl.isEmpty
                          ? const SizedBox(width: 56, height: 56)
                          : Image.network(
                              item.product.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                      title: Text(item.product.name),
                      subtitle: Text(
                        'Rp ${item.product.price.toStringAsFixed(0)} x ${item.quantity}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => cart.setQuantity(
                              item.product.id,
                              item.quantity - 1,
                            ),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            onPressed: () => cart.setQuantity(
                              item.product.id,
                              item.quantity + 1,
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Checkout sederhana',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama pembeli',
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Nama pembeli wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Alamat pengiriman',
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Alamat wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Total: Rp ${cart.totalPrice.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _checkout(context),
                            child: Text(
                              _isSubmitting ? 'Memproses...' : 'Checkout',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
