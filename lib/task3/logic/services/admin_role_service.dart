import 'package:cloud_firestore/cloud_firestore.dart';

const week3FirstAdminUid = 'YXiA3QBe5acGWdwNabpGP2xOwLz2';

class Week3AdminRoleService {
  const Week3AdminRoleService();

  CollectionReference<Map<String, dynamic>> get _admins {
    return FirebaseFirestore.instance.collection('admins');
  }

  Future<bool> isAdmin(String uid) async {
    final doc = await _admins.doc(uid).get();
    return doc.exists;
  }

  Future<void> addAdmin({required String uid, String? email}) {
    return _admins.doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> bootstrapFirstAdminIfMatched({
    required String uid,
    String? email,
  }) async {
    if (uid != week3FirstAdminUid) return false;

    await addAdmin(uid: uid, email: email);
    return true;
  }
}
