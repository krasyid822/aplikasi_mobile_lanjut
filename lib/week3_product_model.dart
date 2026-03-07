import 'package:cloud_firestore/cloud_firestore.dart';

class Week3Product {
  const Week3Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.storagePath,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String storagePath;
  final DateTime? createdAt;

  factory Week3Product.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return Week3Product(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrl: (data['imageUrl'] ?? '') as String,
      storagePath: (data['storagePath'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
