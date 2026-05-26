import 'package:cloud_firestore/cloud_firestore.dart';

class Krs {
  final String id;
  final String uid;
  final int semester;
  final List<String> matkulList;
  final int totalSks;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime tanggalPendaftaran;
  final DateTime? tanggalPersetujuan;

  Krs({
    required this.id,
    required this.uid,
    required this.semester,
    required this.matkulList,
    required this.totalSks,
    required this.status,
    required this.tanggalPendaftaran,
    this.tanggalPersetujuan,
  });

  factory Krs.fromJson(Map<String, dynamic> json, String id) {
    return Krs(
      id: id,
      uid: json['uid'] ?? '',
      semester: json['semester'] ?? 0,
      matkulList: List<String>.from(json['matkulList'] ?? []),
      totalSks: json['totalSks'] ?? 0,
      status: json['status'] ?? 'pending',
      tanggalPendaftaran: (json['tanggalPendaftaran'] as Timestamp).toDate(),
      tanggalPersetujuan: json['tanggalPersetujuan'] != null
          ? (json['tanggalPersetujuan'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'semester': semester,
      'matkulList': matkulList,
      'totalSks': totalSks,
      'status': status,
      'tanggalPendaftaran': Timestamp.fromDate(tanggalPendaftaran),
      'tanggalPersetujuan': tanggalPersetujuan != null
          ? Timestamp.fromDate(tanggalPersetujuan!)
          : null,
    };
  }
}
