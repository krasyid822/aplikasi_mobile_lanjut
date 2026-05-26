import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String nama,
    required String nim,
    required String jurusan,
    required String prodi,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final student = StudentUser(
        uid: userCredential.user!.uid,
        nama: nama,
        email: email,
        nim: nim,
        jurusan: jurusan,
        prodi: prodi,
        semester: '1',
        createdAt: DateTime.now(),
      );

      await _firestoreService.createUserProfile(student);

      // Trigger Welcome Email
      await _firestoreService.sendNotification(
        uid: student.uid,
        email: student.email,
        subject: 'Selamat Datang di Sistem Akademik',
        message: 'Halo ${student.nama}, pendaftaran akun mahasiswa Anda berhasil.',
        type: 'welcome',
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e.code));
    } catch (e) {
      throw Exception('Error during sign up: $e');
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e.code));
    } catch (e) {
      throw Exception('Error during sign in: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error during sign out: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e.code));
    } catch (e) {
      throw Exception('Error sending password reset email: $e');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e.code));
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  Future<StudentUser?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await _firestoreService.getUserProfile(user.uid);
    } catch (e) {
      throw Exception('Error getting current user profile: $e');
    }
  }

  Stream<StudentUser?> getCurrentUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return _firestoreService.getUserProfileStream(user.uid);
  }

  String _handleFirebaseAuthError(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'invalid-email':
        return 'Email tidak valid';
      case 'user-not-found':
        return 'Pengguna tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'user-disabled':
        return 'Pengguna telah dinonaktifkan';
      default:
        return 'Error: $code';
    }
  }
}
