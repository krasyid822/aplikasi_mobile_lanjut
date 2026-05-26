import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mahasiswa_model.dart';

class FirestoreService {
  FirestoreService() : _collection = _buildCollection();

  final CollectionReference<Map<String, dynamic>> _collection;

  static CollectionReference<Map<String, dynamic>> _buildCollection() {
    return FirebaseFirestore.instance.collection('mahasiswa');
  }

  Future<void> tambahMahasiswa(Mahasiswa mhs) {
    return _collection.add(mhs.toMap());
  }

  Stream<List<Mahasiswa>> getMahasiswa() {
    return _collection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Mahasiswa.fromFirestore(doc.data(), doc.id))
          .toList(),
    );
  }

  Future<void> updateMahasiswa(Mahasiswa mhs) {
    return _collection.doc(mhs.id).update(mhs.toMap());
  }

  Future<void> deleteMahasiswa(String id) {
    return _collection.doc(id).delete();
  }
}
