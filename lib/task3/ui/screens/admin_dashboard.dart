import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../logic/models/order_model.dart';
import '../widgets/order_status_ui.dart';
import '../../logic/models/product_model.dart';
import '../../logic/services/product_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, this.service = const Week3ProductService()});

  final Week3ProductService service;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _orderSearchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  Week3Product? _editingProduct;
  var _isSubmitting = false;
  var _productQuery = '';
  var _orderQuery = '';
  String? _selectedOrderStatusFilter;

  @override
  void dispose() {
    _productSearchController.dispose();
    _orderSearchController.dispose();
    nameController.dispose();
    priceController.dispose();
    descController.dispose();
    super.dispose();
  }

  bool _matchesProductSearch(Week3Product product) {
    final query = _productQuery.trim().toLowerCase();
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

  bool _matchesOrderSearch(Week3Order order) {
    final query = _orderQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final itemsText = order.items.map((item) => item.name).join(' ');
    final searchable = [
      order.id,
      order.customerName,
      order.customerEmail,
      order.customerAddress,
      order.status,
      itemsText,
      week3FormatOrderTimestamp(order.createdAt),
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }

  bool _matchesOrderStatusFilter(Week3Order order) {
    final filter = _selectedOrderStatusFilter;
    if (filter == null || filter.isEmpty) {
      return true;
    }
    return order.status == filter;
  }

  Widget _buildOrderStatusFilterChips(List<Week3Order> orders) {
    final statuses = <String>{...orders.map((order) => order.status)};
    final orderedStatuses = [
      for (final status in week3AdminStatusOptions)
        if (statuses.contains(status)) status,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Semua'),
          selected: _selectedOrderStatusFilter == null,
          onSelected: (_) {
            setState(() {
              _selectedOrderStatusFilter = null;
            });
          },
        ),
        ...orderedStatuses.map(
          (status) => _OrderFilterChip(
            status: status,
            selected: _selectedOrderStatusFilter == status,
            onTap: () {
              setState(() {
                _selectedOrderStatusFilter =
                    _selectedOrderStatusFilter == status ? null : status;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedDurationInfo(Week3Order order) {
    if (order.status != 'selesai' || order.completedAt == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Week3OrderExpiryBadge(
          completedAt: order.completedAt,
          compact: true,
        ),
      ),
    );
  }

  Widget _buildActivityTimeline(Week3Order order) {
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

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _startEdit(Week3Product product) {
    setState(() {
      _editingProduct = product;
      nameController.text = product.name;
      priceController.text = product.price.toStringAsFixed(0);
      descController.text = product.description;
      _image = null;
    });
  }

  void _resetForm() {
    setState(() {
      _editingProduct = null;
      _image = null;
      nameController.clear();
      priceController.clear();
      descController.clear();
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true || _isSubmitting) return;

    final wasEditing = _editingProduct != null;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.service.saveProduct(
        existing: _editingProduct,
        name: nameController.text.trim(),
        description: descController.text.trim(),
        price: double.parse(priceController.text.trim()),
        imageFile: _image,
      );

      _resetForm();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEditing
                ? 'Produk berhasil diperbarui'
                : 'Produk berhasil ditambahkan',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan produk: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteProduct(Week3Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus produk'),
          content: Text('Yakin ingin menghapus ${product.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await widget.service.deleteProduct(product);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produk berhasil dihapus')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus produk: $e')));
    }
  }

  Future<void> _updateOrderStatus(Week3Order order, String status) async {
    try {
      await widget.service.updateOrderStatus(order.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status order ${order.id} diperbarui ke $status'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal update status order: $e')));
    }
  }

  Widget _buildOrderSection() {
    return StreamBuilder<List<Week3Order>>(
      stream: widget.service.watchOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Gagal memuat order: ${snapshot.error}');
        }

        final allOrders = snapshot.data ?? const <Week3Order>[];
        final orders = allOrders
            .where(_matchesOrderSearch)
            .where(_matchesOrderStatusFilter)
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderStatusFilterChips(allOrders),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Tidak ada order yang cocok dengan filter aktif.',
                  ),
                ),
              )
            else
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(order.customerName),
                      subtitle: Text(
                        '${order.customerEmail.isNotEmpty ? order.customerEmail : 'Email tidak tersedia'}\n${order.customerAddress}\nTotal Rp ${order.totalPrice.toStringAsFixed(0)}',
                      ),
                      trailing: Week3OrderStatusBadge(
                        status: order.status,
                        compact: true,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCompletedDurationInfo(order),
                              ...order.items.map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: item.imageUrl.isEmpty
                                      ? const SizedBox(width: 48, height: 48)
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                  trailing: Text(
                                    'Rp ${item.subtotal.toStringAsFixed(0)}',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildActivityTimeline(order),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue:
                                    week3AdminStatusOptions.contains(
                                      order.status,
                                    )
                                    ? order.status
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Perbarui Status Order',
                                ),
                                items: week3AdminStatusOptions
                                    .map(
                                      (status) => DropdownMenuItem<String>(
                                        value: status,
                                        child: Week3OrderStatusBadge(
                                          status: status,
                                          compact: true,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (status) {
                                  if (status == null ||
                                      status == order.status) {
                                    return;
                                  }
                                  _updateOrderStatus(order, status);
                                },
                              ),
                              if (order.status == 'permohonan_batal')
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Pelanggan meminta pembatalan. Admin dapat memutuskan untuk membatalkan order atau mengembalikannya ke status proses atau selesai.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Week3Product>>(
      stream: widget.service.watchProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <Week3Product>[];
        final filteredProducts = products
            .where(_matchesProductSearch)
            .toList(growable: false);
        late final Widget productListSection;

        if (snapshot.connectionState == ConnectionState.waiting) {
          productListSection = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          productListSection = Text('Gagal memuat produk: ${snapshot.error}');
        } else if (products.isEmpty) {
          productListSection = const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada produk. Tambahkan produk pertama.'),
            ),
          );
        } else if (filteredProducts.isEmpty) {
          productListSection = const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Produk tidak ditemukan untuk kata kunci ini.'),
            ),
          );
        } else {
          productListSection = Column(
            children: filteredProducts
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: product.imageUrl.isEmpty
                            ? const SizedBox(width: 64, height: 64)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product.imageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.description}\nRp ${product.price.toStringAsFixed(0)}',
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              onPressed: () => _startEdit(product),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => _deleteProduct(product),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /*  Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel Admin',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kelola produk, ubah status pesanan, dan pantau transaksi pelanggan.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ), */
            /* const SizedBox(height: 16), */
            Text(
              'Manajemen Order',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderSearchController,
              decoration: InputDecoration(
                labelText: 'Cari pada manajemen order',
                hintText: 'Nama, email, status, item, alamat, atau ID order',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _orderQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _orderSearchController.clear();
                          setState(() {
                            _orderQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _orderQuery = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildOrderSection(),
            const SizedBox(height: 20),
            Text(
              'Daftar Produk',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _productSearchController,
              decoration: InputDecoration(
                labelText: 'Cari pada daftar produk',
                hintText: 'Nama, deskripsi, atau harga',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _productQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _productSearchController.clear();
                          setState(() {
                            _productQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _productQuery = value;
                });
              },
            ),
            const SizedBox(height: 12),
            productListSection,
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingProduct == null
                            ? 'Tambah Produk'
                            : 'Edit Produk',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Nama produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Harga'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final parsed = double.tryParse((value ?? '').trim());
                          if (parsed == null) return 'Harga harus berupa angka';
                          if (parsed <= 0) return 'Harga harus lebih dari 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Deskripsi wajib diisi';
                          }
                          if ((value ?? '').trim().length < 10) {
                            return 'Deskripsi minimal 10 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Pilih Gambar'),
                          ),
                          if (_editingProduct != null)
                            OutlinedButton(
                              onPressed: _resetForm,
                              child: const Text('Batal Edit'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _image!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else if (_editingProduct?.imageUrl.isNotEmpty == true)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _editingProduct!.imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Text('Belum ada gambar dipilih'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          _isSubmitting
                              ? 'Menyimpan...'
                              : _editingProduct == null
                              ? 'Simpan Produk'
                              : 'Update Produk',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderFilterChip extends StatelessWidget {
  const _OrderFilterChip({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final String status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: selected ? 1 : 0.72,
          child: Week3OrderStatusBadge(status: status, compact: true),
        ),
      ),
    );
  }
}
