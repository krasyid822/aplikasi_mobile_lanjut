import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'week3_product_model.dart';

class Week3CartItem {
  const Week3CartItem({required this.product, required this.quantity});

  final Week3Product product;
  final int quantity;

  double get subtotal => product.price * quantity;

  Week3CartItem copyWith({int? quantity}) {
    return Week3CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}

class Week3ShopController extends ChangeNotifier {
  final Map<String, Map<String, Week3CartItem>> _cartsByOwner = {};
  String _activeOwnerKey = 'guest';

  Map<String, Week3CartItem> get _items {
    return _cartsByOwner.putIfAbsent(_activeOwnerKey, () => {});
  }

  String get activeOwnerKey => _activeOwnerKey;

  void bindToCustomer(String? uid) {
    final nextOwnerKey = (uid == null || uid.isEmpty) ? 'guest' : uid;
    if (nextOwnerKey == _activeOwnerKey) return;
    _activeOwnerKey = nextOwnerKey;
    notifyListeners();
  }

  UnmodifiableListView<Week3CartItem> get items {
    return UnmodifiableListView(_items.values);
  }

  int get totalItems {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    return _items.values.fold(0, (sum, item) => sum + item.subtotal);
  }

  bool containsProduct(String productId) {
    return _items.containsKey(productId);
  }

  void addToCart(Week3Product product) {
    final existing = _items[product.id];
    _items[product.id] = Week3CartItem(
      product: product,
      quantity: (existing?.quantity ?? 0) + 1,
    );
    notifyListeners();
  }

  void setQuantity(String productId, int quantity) {
    final existing = _items[productId];
    if (existing == null) return;

    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId] = existing.copyWith(quantity: quantity);
    }

    notifyListeners();
  }

  void removeFromCart(String productId) {
    if (_items.remove(productId) != null) {
      notifyListeners();
    }
  }

  void clearCart() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
