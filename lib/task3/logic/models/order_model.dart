import 'package:cloud_firestore/cloud_firestore.dart';

class Week3OrderActivity {
  const Week3OrderActivity({
    required this.title,
    required this.actor,
    required this.timestamp,
    this.note,
    this.status,
  });

  final String title;
  final String actor;
  final DateTime? timestamp;
  final String? note;
  final String? status;

  factory Week3OrderActivity.fromMap(Map<String, dynamic> data) {
    return Week3OrderActivity(
      title: (data['title'] ?? '') as String,
      actor: (data['actor'] ?? '') as String,
      note: data['note'] as String?,
      status: data['status'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

class Week3OrderItem {
  const Week3OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final double subtotal;

  factory Week3OrderItem.fromMap(Map<String, dynamic> data) {
    return Week3OrderItem(
      productId: (data['productId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Week3Order {
  const Week3Order({
    required this.id,
    required this.customerName,
    required this.customerAddress,
    required this.customerUid,
    required this.customerEmail,
    required this.status,
    required this.totalPrice,
    required this.items,
    required this.activities,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String customerName;
  final String customerAddress;
  final String customerUid;
  final String customerEmail;
  final String status;
  final double totalPrice;
  final List<Week3OrderItem> items;
  final List<Week3OrderActivity> activities;
  final DateTime? createdAt;
  final DateTime? completedAt;

  factory Week3Order.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawItems = (data['items'] as List?) ?? const [];
    final rawActivities = (data['activities'] as List?) ?? const [];

    return Week3Order(
      id: doc.id,
      customerName: (data['customerName'] ?? '') as String,
      customerAddress: (data['customerAddress'] ?? '') as String,
      customerUid: (data['customerUid'] ?? '') as String,
      customerEmail: (data['customerEmail'] ?? '') as String,
      status: (data['status'] ?? 'baru') as String,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0,
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => Week3OrderItem.fromMap(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false),
      activities: rawActivities
          .whereType<Map>()
          .map(
            (activity) => Week3OrderActivity.fromMap(
              activity.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}
