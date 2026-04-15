import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'week4_donation_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getCampaigns() {
    return _db.collection('campaigns').snapshots();
  }

  Future<void> addCampaign(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('createdAt')) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await _db.collection('campaigns').add(payload);
  }

  /// Donate to campaign and record donation in `donations` collection.
  Future<void> donate(String id, int amount) async {
    final ref = _db.collection('campaigns').doc(id);

    // Update collected amount in a transaction
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final current = (snapshot.data() ?? {})['collected'] ?? 0;
      final newTotal = (current as int) + amount;
      transaction.update(ref, {'collected': newTotal});
    });

    // Add donation record (non-transactional)
    final user = FirebaseAuth.instance.currentUser;
    await _db.collection('donations').add({
      'userId': user?.uid ?? '',
      'campaignId': id,
      'amount': amount,
      'date': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addUser(
    String userId,
    String email, {
    String name = '',
    String role = 'user',
  }) async {
    await _db.collection('users').doc(userId).set({
      'email': email,
      'name': name,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns true if the given user id is present in the `admins` collection.
  Future<bool> isAdmin(String userId) async {
    final doc = await _db.collection('admins').doc(userId).get();
    return doc.exists;
  }

  Future<String?> getUserRole(String userId) async {
    // Prefer explicit role on the users document when available
    final userDoc = await _db.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data.containsKey('role')) {
        final role = data['role'];
        if (role is String && role.isNotEmpty) return role;
      }
    }

    // Fallback: check legacy `admins` collection (some setups store admins there)
    final adminDoc = await _db.collection('admins').doc(userId).get();
    if (adminDoc.exists) {
      return 'admin';
    }

    return null;
  }

  Stream<List<Donation>> getDonationsForUser(String userId) async* {
    // Try the indexed query first (requires composite index if not present).
    try {
      await for (final snapshot
          in _db
              .collection('donations')
              .where('userId', isEqualTo: userId)
              .orderBy('date', descending: true)
              .snapshots()) {
        final donations = snapshot.docs
            .map((d) => Donation.fromFirestore(d))
            .toList(growable: false);
        yield donations;
      }
    } catch (e) {
      // If Firestore requires a composite index, fallback to a simpler query
      // and perform client-side sorting to avoid crashing the listener.
      if (e is FirebaseException &&
          (e.code == 'failed-precondition' ||
              (e.message != null &&
                  e.message!.contains('requires an index')))) {
        await for (final snapshot
            in _db
                .collection('donations')
                .where('userId', isEqualTo: userId)
                .snapshots()) {
          final donations = snapshot.docs
              .map((d) => Donation.fromFirestore(d))
              .toList(growable: false);
          donations.sort((a, b) => b.date.compareTo(a.date));
          yield donations;
        }
      } else {
        rethrow;
      }
    }
  }

  /// Fetches the latest `collected` amount for a campaign.
  Future<int> getCampaignCollected(String id) async {
    final doc = await _db.collection('campaigns').doc(id).get();
    if (!doc.exists) return 0;
    final data = doc.data();
    return (data?['collected'] ?? 0) as int;
  }
}
