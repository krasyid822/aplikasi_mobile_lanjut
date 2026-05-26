import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/grade_model.dart';
import '../models/course_model.dart';
import '../models/major_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static const String usersCollection = 'users';
  static const String gradesCollection = 'grades';
  static const String coursesCollection = 'courses';
  static const String majorsCollection = 'majors';
  static const String krsCollection = 'krs';
  static const String notificationsCollection = 'notifications';
  static const String auditLogsCollection = 'audit_logs';

  // User Operations
  Future<void> createUserProfile(StudentUser user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .set(user.toJson());
    } catch (e) {
      throw Exception('Error creating user profile: $e');
    }
  }

  Future<StudentUser?> getUserProfile(String uid) async {
    try {
      final doc =
          await _firestore.collection(usersCollection).doc(uid).get();
      if (doc.exists) {
        return StudentUser.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user profile: $e');
    }
  }

  Stream<StudentUser?> getUserProfileStream(String uid) {
    return _firestore
        .collection(usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return StudentUser.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Future<void> updateUserProfile(StudentUser user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .update(user.toJson());
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  Future<void> deleteStudent(String uid) async {
    try {
      // 1. Delete student profile
      await _firestore.collection(usersCollection).doc(uid).delete();
      
      // 2. Delete all grades associated with this student
      final grades = await _firestore
          .collection(gradesCollection)
          .where('uid', isEqualTo: uid)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in grades.docs) {
        batch.delete(doc.reference);
      }
      
      // 3. Delete KRS associated with this student
      final krs = await _firestore
          .collection(krsCollection)
          .where('uid', isEqualTo: uid)
          .get();
      
      for (var doc in krs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error deleting student and their data: $e');
    }
  }

  // Admin/Lecturer Operations
  Future<List<StudentUser>> getAllStudents() async {
    try {
      final snapshot = await _firestore.collection(usersCollection).get();
      return snapshot.docs
          .map((doc) => StudentUser.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error getting students: $e');
    }
  }

  Stream<List<StudentUser>> getAllStudentsStream() {
    return _firestore.collection(usersCollection).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StudentUser.fromJson(doc.data()))
          .toList();
    });
  }

  // Grade Operations
  Future<void> addGrade(Grade grade) async {
    try {
      // Menggunakan ID unik kombinasi UID dan Kode Matkul untuk mencegah duplikat
      final customId = '${grade.uid}_${grade.kodeMatkul}';
      await _firestore.collection(gradesCollection).doc(customId).set(grade.toJson());
    } catch (e) {
      throw Exception('Error saving grade: $e');
    }
  }

  Future<List<Grade>> getGradesByUser(String uid) async {
    try {
      final snapshot = await _firestore
          .collection(gradesCollection)
          .where('uid', isEqualTo: uid)
          .orderBy('semester', descending: true)
          .orderBy('tanggalInput', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Grade.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error getting grades: $e');
    }
  }

  Stream<List<Grade>> getGradesByUserStream(String uid) {
    return _firestore
        .collection(gradesCollection)
        .where('uid', isEqualTo: uid)
        .orderBy('semester', descending: true)
        .orderBy('tanggalInput', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Grade.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Grade>> getGradesBySemesterStream(
      String uid, int semester) {
    return _firestore
        .collection(gradesCollection)
        .where('uid', isEqualTo: uid)
        .where('semester', isEqualTo: semester)
        .orderBy('tanggalInput', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Grade.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<double> calculateGPA(String uid, int? semester) async {
    try {
      List<Grade> grades;

      if (semester != null) {
        grades = await _firestore
            .collection(gradesCollection)
            .where('uid', isEqualTo: uid)
            .where('semester', isEqualTo: semester)
            .get()
            .then((snapshot) {
          return snapshot.docs
              .map((doc) => Grade.fromJson(doc.data(), doc.id))
              .toList();
        });
      } else {
        grades = await getGradesByUser(uid);
      }

      if (grades.isEmpty) return 0.0;

      double totalPoints = 0;
      int totalSks = 0;

      for (var grade in grades) { totalPoints += grade.getGradePoint() * grade.sks; totalSks += grade.sks; }

      return totalSks > 0 ? totalPoints / totalSks : 0.0;
    } catch (e) {
      throw Exception('Error calculating GPA: $e');
    }
  }

  Future<int> getTotalSks(String uid) async {
    try {
      final grades = await getGradesByUser(uid);
      return grades.fold<int>(0, (total, grade) => total + grade.sks);
    } catch (e) {
      throw Exception('Error calculating total SKS: $e');
    }
  }

  Future<void> updateGrade(Grade grade) async {
    try {
      await _firestore
          .collection(gradesCollection)
          .doc(grade.id)
          .update(grade.toJson());
    } catch (e) {
      throw Exception('Error updating grade: $e');
    }
  }

  Future<void> deleteGrade(String gradeId) async {
    try {
      await _firestore.collection(gradesCollection).doc(gradeId).delete();
    } catch (e) {
      throw Exception('Error deleting grade: $e');
    }
  }

  // Course Operations
  Future<void> addCourse(Course course) async {
    try {
      await _firestore.collection(coursesCollection).add(course.toJson());
    } catch (e) {
      throw Exception('Error adding course: $e');
    }
  }

  Stream<List<Course>> getAllCoursesStream() {
    return _firestore
        .collection(coursesCollection)
        .orderBy('semester')
        .orderBy('kodeMatkul')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Course.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateCourse(Course course) async {
    try {
      await _firestore
          .collection(coursesCollection)
          .doc(course.id)
          .update(course.toJson());
    } catch (e) {
      throw Exception('Error updating course: $e');
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _firestore.collection(coursesCollection).doc(courseId).delete();
    } catch (e) {
      throw Exception('Error deleting course: $e');
    }
  }

  Future<List<Grade>> getGradesByCourse(String courseName) async {
    try {
      final snapshot = await _firestore
          .collection(gradesCollection)
          .where('matkul', isEqualTo: courseName)
          .orderBy('tanggalInput', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Grade.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error getting grades by course: $e');
    }
  }

  Future<Grade?> getGradeByDetail(String uid, String matkul) async {
    try {
      final snapshot = await _firestore
          .collection(gradesCollection)
          .where('uid', isEqualTo: uid)
          .where('matkul', isEqualTo: matkul)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Grade.fromJson(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error checking existing grade: $e');
    }
  }

  // Major & Prodi Operations
  Future<void> addMajor(Major major) async {
    try {
      await _firestore.collection(majorsCollection).add(major.toJson());
    } catch (e) {
      throw Exception('Error adding major: $e');
    }
  }

  Stream<List<Major>> getAllMajorsStream() {
    return _firestore
        .collection(majorsCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Major.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateMajor(Major major) async {
    try {
      await _firestore
          .collection(majorsCollection)
          .doc(major.id)
          .update(major.toJson());
    } catch (e) {
      throw Exception('Error updating major: $e');
    }
  }

  Future<void> deleteMajor(String majorId) async {
    try {
      await _firestore.collection(majorsCollection).doc(majorId).delete();
    } catch (e) {
      throw Exception('Error deleting major: $e');
    }
  }

  // Notification Operations
  Future<String?> sendNotification({
    required String uid,
    required String email,
    required String subject,
    required String message,
    required String type,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final notificationData = {
        'uid': uid,
        'email': email,
        'subject': subject,
        'message': message,
        'type': type,
        'status': 'pending',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        ...?extraData,
      };
      final docRef = await _firestore.collection(notificationsCollection).add(notificationData);
      
      // Jalankan cleanup otomatis untuk notifikasi lama yang sudah 'sent'
      await cleanupOldNotifications();
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating notification trigger: $e');
      return null;
    }
  }

  Future<void> updateNotificationStatus(String docId, String status) async {
    try {
      await _firestore.collection(notificationsCollection).doc(docId).update({
        'status': status,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating notification status: $e');
    }
  }

  Future<void> cleanupOldNotifications() async {
    try {
      final now = DateTime.now();
      final fifteenMinutesAgo = now.subtract(const Duration(minutes: 15));

      // Cari notifikasi berstatus 'sent' yang sudah lebih dari 15 menit
      final oldNotifications = await _firestore
          .collection(notificationsCollection)
          .where('status', isEqualTo: 'sent')
          .where('sentAt', isLessThan: Timestamp.fromDate(fifteenMinutesAgo))
          .get();

      if (oldNotifications.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in oldNotifications.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('CLEANUP: Berhasil menghapus ${oldNotifications.docs.length} notifikasi lama.');
      }
    } catch (e) {
      debugPrint('CLEANUP ERROR: $e');
    }
  }

  // Audit Log Operations
  Future<void> addAuditLog({
    required String action,
    required String details,
    required String dosenUid,
    required String dosenNama,
  }) async {
    try {
      await _firestore.collection(auditLogsCollection).add({
        'action': action,
        'details': details,
        'dosenUid': dosenUid,
        'dosenNama': dosenNama,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding audit log: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getAuditLogsStream() {
    return _firestore
        .collection(auditLogsCollection)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  // Batch Operations
  Future<void> addMultipleGrades(List<Grade> grades) async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection(gradesCollection);

      for (var grade in grades) {
        batch.set(collection.doc(), grade.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error adding multiple grades: $e');
    }
  }
}
