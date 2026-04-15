import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String id;
  final String userId;
  final String campaignId;
  final int amount;
  final DateTime date;

  Donation({
    required this.id,
    required this.userId,
    required this.campaignId,
    required this.amount,
    required this.date,
  });

  factory Donation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Donation(
      id: doc.id,
      userId: data['userId'] ?? '',
      campaignId: data['campaignId'] ?? '',
      amount: (data['amount'] ?? 0) as int,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
