import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String uid;
  final String nama;
  final String email;
  final String role; // 'admin' or 'dosen'
  final List<String> matkulList; // Dosen can see specific courses
  final DateTime createdAt;

  AdminUser({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    this.matkulList = const [],
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      uid: json['uid'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'dosen',
      matkulList: List<String>.from(json['matkulList'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'role': role,
      'matkulList': matkulList,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> adminSignIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = _auth.currentUser!.uid;

      // Check if it's the master admin
      if (uid == 'YXiA3QBe5acGWdwNabpGP2xOwLz2') {
        final adminDoc = await _firestore.collection('admins').doc(uid).get();
        if (!adminDoc.exists) {
          await _firestore.collection('admins').doc(uid).set({
            'uid': uid,
            'nama': 'Rasyid Kurniawan (Admin)',
            'email': 'krasyid822@gmail.com',
            'role': 'admin',
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
        return;
      }

      // Verify other admin/dosen role
      final adminDoc = await _firestore.collection('admins').doc(uid).get();

      if (!adminDoc.exists) {
        await _auth.signOut();
        throw Exception('User bukan admin/dosen terdaftar');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e.code));
    }
  }

  Future<void> registerDosen({
    required String email,
    required String password,
    required String nama,
    required List<String> matkul,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final adminUser = AdminUser(
        uid: uid,
        nama: nama,
        email: email,
        role: 'dosen',
        matkulList: matkul,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('admins').doc(uid).set(adminUser.toJson());
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e.code));
    }
  }

  Future<AdminUser?> getAdminProfile(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      
      // Auto-bootstrap master admin jika dokumen belum ada tapi UID cocok
      if (!doc.exists && uid == 'YXiA3QBe5acGWdwNabpGP2xOwLz2') {
        final masterAdmin = AdminUser(
          uid: uid,
          nama: 'Rasyid Kurniawan (Admin)',
          email: 'krasyid822@gmail.com',
          role: 'admin',
          createdAt: DateTime.now(),
        );
        await _firestore.collection('admins').doc(uid).set(masterAdmin.toJson());
        return masterAdmin;
      }

      if (doc.exists) {
        return AdminUser.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting admin profile: $e');
    }
  }

  Stream<AdminUser?> getAdminProfileStream(String uid) {
    // Memastikan master admin terdaftar di stream juga
    return _firestore.collection('admins').doc(uid).snapshots().asyncMap((doc) async {
      if (!doc.exists && uid == 'YXiA3QBe5acGWdwNabpGP2xOwLz2') {
        return await getAdminProfile(uid);
      }
      if (doc.exists) {
        return AdminUser.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  // Admin specific operations
  Stream<List<AdminUser>> getAllLecturersStream() {
    return _firestore
        .collection('admins')
        .where('role', isEqualTo: 'dosen')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminUser.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> deleteLecturer(String uid) async {
    try {
      await _firestore.collection('admins').doc(uid).delete();
    } catch (e) {
      throw Exception('Error deleting lecturer: $e');
    }
  }

  Future<void> updateLecturer(AdminUser lecturer) async {
    try {
      await _firestore
          .collection('admins')
          .doc(lecturer.uid)
          .update(lecturer.toJson());
    } catch (e) {
      throw Exception('Error updating lecturer: $e');
    }
  }

  String _handleFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Email tidak valid';
      case 'user-disabled':
        return 'User telah dinonaktifkan';
      default:
        return 'Error: $code';
    }
  }
}

