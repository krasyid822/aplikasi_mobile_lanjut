import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'week3_product_model.dart';
import 'week3_product_service.dart';
import 'week3_shop_controller.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key, this.service = const Week3ProductService()});

  final Week3ProductService service;

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(Week3Product product) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final searchable = [
      product.name,
      product.description,
      product.price.toStringAsFixed(0),
    ].join(' ').toLowerCase();

    return searchable.contains(query);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Week3ShopController>();

    return StreamBuilder<List<Week3Product>>(
      stream: widget.service.watchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat produk!\nAnda mungkin belum login.\n\nError: ${snapshot.error}',
            ),
          );
        }

        final products = snapshot.data ?? const <Week3Product>[];
        final filteredProducts = products
            .where(_matchesQuery)
            .toList(growable: false);

        if (products.isEmpty) {
          return const Center(child: Text('Belum ada produk tersedia'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari produk',
                hintText: 'Nama, deskripsi, atau harga',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (filteredProducts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Produk tidak ditemukan untuk kata kunci ini.'),
                ),
              )
            else
              ...List.generate(filteredProducts.length, (index) {
                final product = filteredProducts[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == filteredProducts.length - 1 ? 0 : 12,
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.imageUrl.isNotEmpty)
                          Image.network(
                            product.imageUrl,
                            width: double.infinity,
                            height: 190,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            height: 190,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      'Rp ${product.price.toStringAsFixed(0)}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(product.description),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () {
                                  cart.addToCart(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.name} ditambahkan',
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  cart.containsProduct(product.id)
                                      ? Icons.add_shopping_cart
                                      : Icons.shopping_cart_checkout,
                                ),
                                label: Text(
                                  cart.containsProduct(product.id)
                                      ? 'Tambah Lagi'
                                      : 'Masukkan Keranjang',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
