import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  String id;

  String title;

  String description;

  int target;

  int collected;

  String imageUrl;

  Campaign({
    required this.id,

    required this.title,

    required this.description,

    required this.target,

    required this.collected,

    required this.imageUrl,
  });

  factory Campaign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Campaign(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      target: (data['target'] ?? 0) as int,
      collected: (data['collected'] ?? 0) as int,
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}
