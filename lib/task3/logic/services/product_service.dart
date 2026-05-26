import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../../ui/widgets/order_status_ui.dart';
import 'shop_controller.dart';
import 'supabase_config.dart';

class Week3ProductService {
  const Week3ProductService();

  static const Duration _completedOrderRetention = Duration(hours: 1);

  CollectionReference<Map<String, dynamic>> get _products {
    return FirebaseFirestore.instance.collection('products');
  }

  CollectionReference<Map<String, dynamic>> get _orders {
    return FirebaseFirestore.instance.collection('orders');
  }

  StorageFileApi get _bucket {
    return week3SupabaseClient.storage.from(week3SupabaseBucket);
  }

  Map<String, dynamic> _activityEntry({
    required String title,
    required String actor,
    String? status,
    String? note,
  }) {
    return {
      'title': title,
      'actor': actor,
      'status': status,
      'note': note,
      'timestamp': Timestamp.now(),
    };
  }

  Future<void> _cleanupCompletedOrders() async {
    final snapshot = await _orders.where('status', isEqualTo: 'selesai').get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();
    var hasDeletion = false;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
      if (completedAt != null &&
          now.difference(completedAt) >= _completedOrderRetention) {
        batch.delete(doc.reference);
        hasDeletion = true;
      }
    }

    if (hasDeletion) {
      await batch.commit();
    }
  }

  Stream<List<Week3Order>> _watchOrdersQuery(
    Query<Map<String, dynamic>> query,
  ) {
    unawaited(_cleanupCompletedOrders());
    return query.snapshots().map((snapshot) {
      unawaited(_cleanupCompletedOrders());
      return snapshot.docs
          .map((doc) => Week3Order.fromFirestore(doc))
          .toList(growable: false);
    });
  }

  Future<void> _ensureReadableUrl(String imageUrl) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(imageUrl));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'URL gambar tidak dapat diakses. Pastikan bucket $week3SupabaseBucket public atau policy bacanya mengizinkan akses ke file.',
        );
      }
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }
  }

  Stream<List<Week3Product>> watchProducts() {
    return _products
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Week3Product.fromFirestore(doc))
              .toList(growable: false),
        );
  }

  Future<void> saveProduct({
    Week3Product? existing,
    required String name,
    required String description,
    required double price,
    File? imageFile,
  }) async {
    if (existing == null && imageFile == null) {
      throw Exception('Gambar produk wajib dipilih');
    }

    var imageUrl = existing?.imageUrl ?? '';
    var storagePath = existing?.storagePath ?? '';

    if (imageFile != null) {
      final extension = imageFile.path.contains('.')
          ? imageFile.path.split('.').last.toLowerCase()
          : 'jpg';
      final targetPath = storagePath.isNotEmpty
          ? storagePath
          : 'products/${DateTime.now().millisecondsSinceEpoch}.$extension';
      await _bucket.upload(
        targetPath,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );
      imageUrl = _bucket.getPublicUrl(targetPath);
      await _ensureReadableUrl(imageUrl);
      storagePath = targetPath;
    }

    final payload = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'storagePath': storagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (existing == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      await _products.add(payload);
      return;
    }

    await _products.doc(existing.id).update(payload);
  }

  Future<void> deleteProduct(Week3Product product) async {
    await _products.doc(product.id).delete();

    if (product.storagePath.isNotEmpty) {
      try {
        await _bucket.remove([product.storagePath]);
      } catch (_) {}
    }
  }

  Stream<List<Week3Order>> watchOrders() {
    return _watchOrdersQuery(_orders.orderBy('createdAt', descending: true));
  }

  Stream<List<Week3Order>> watchOrdersForCustomer(String uid) {
    return _watchOrdersQuery(
      _orders
          .where('customerUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true),
    );
  }

  Future<void> updateOrderStatus(String orderId, String status) {
    return _orders.doc(orderId).update({
      'status': status,
      'completedAt': status == 'selesai'
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
      'activities': FieldValue.arrayUnion([
        _activityEntry(
          title: 'Status order diperbarui',
          actor: 'admin',
          status: status,
          note: 'Status diubah menjadi ${week3OrderStatusLabel(status)}',
        ),
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitCustomerCancellation(Week3Order order) {
    if (week3CanCustomerCancelDirectly(order.status)) {
      return _orders.doc(order.id).update({
        'status': 'dibatalkan',
        'activities': FieldValue.arrayUnion([
          _activityEntry(
            title: 'Order dibatalkan pelanggan',
            actor: 'pelanggan',
            status: 'dibatalkan',
            note: 'Order dibatalkan langsung karena masih berstatus baru',
          ),
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (order.status == 'permohonan_batal') {
      throw Exception('Permohonan pembatalan sudah dikirim sebelumnya');
    }

    if (order.status == 'dibatalkan') {
      throw Exception('Order ini sudah dibatalkan');
    }

    return _orders.doc(order.id).update({
      'status': 'permohonan_batal',
      'activities': FieldValue.arrayUnion([
        _activityEntry(
          title: 'Permohonan pembatalan dikirim',
          actor: 'pelanggan',
          status: 'permohonan_batal',
          note: 'Admin perlu meninjau permohonan pembatalan order ini',
        ),
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createOrder({
    required String customerName,
    required String customerAddress,
    required List<Week3CartItem> items,
    required double totalPrice,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    return _orders.add({
      'customerName': customerName,
      'customerAddress': customerAddress,
      'customerUid': user?.uid ?? '',
      'customerEmail': user?.email ?? '',
      'status': 'baru',
      'totalPrice': totalPrice,
      'createdAt': FieldValue.serverTimestamp(),
      'activities': [
        _activityEntry(
          title: 'Order dibuat',
          actor: user?.email?.isNotEmpty == true ? 'pelanggan' : 'tamu',
          status: 'baru',
          note: 'Checkout berhasil dibuat dan menunggu diproses',
        ),
      ],
      'items': items
          .map(
            (item) => {
              'productId': item.product.id,
              'name': item.product.name,
              'price': item.product.price,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
              'imageUrl': item.product.imageUrl,
            },
          )
          .toList(growable: false),
    });
  }
}
