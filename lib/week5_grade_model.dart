class Grade {
  final String id;
  final String uid;
  final String namaMahasiswa;
  final String matkul;
  final String kodeMatkul;
  final double nilai;
  final String grade;
  final int sks;
  final int semester;
  final String dosenUid;
  final DateTime tanggalInput;

  Grade({
    required this.id,
    required this.uid,
    this.namaMahasiswa = '',
    required this.matkul,
    required this.kodeMatkul,
    required this.nilai,
    required this.grade,
    required this.sks,
    required this.semester,
    this.dosenUid = '',
    required this.tanggalInput,
  });

  factory Grade.fromJson(Map<String, dynamic> json, String docId) {
    return Grade(
      id: docId,
      uid: json['uid'] ?? '',
      namaMahasiswa: json['namaMahasiswa'] ?? '',
      matkul: json['matkul'] ?? '',
      kodeMatkul: json['kodeMatkul'] ?? '',
      nilai: (json['nilai'] ?? 0.0).toDouble(),
      grade: json['grade'] ?? '-',
      sks: json['sks'] ?? 0,
      semester: json['semester'] ?? 1,
      dosenUid: json['dosenUid'] ?? '',
      tanggalInput: json['tanggalInput'] != null
          ? DateTime.parse(json['tanggalInput'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'namaMahasiswa': namaMahasiswa,
      'matkul': matkul,
      'kodeMatkul': kodeMatkul,
      'nilai': nilai,
      'grade': grade,
      'sks': sks,
      'semester': semester,
      'dosenUid': dosenUid,
      'tanggalInput': tanggalInput.toIso8601String(),
    };
  }

  static String getGradeFromValue(double nilai) {
    if (nilai >= 85) return 'A';
    if (nilai >= 70) return 'B';
    if (nilai >= 60) return 'C';
    if (nilai >= 50) return 'D';
    return 'E';
  }

  double getGradePoint() {
    switch (grade) {
      case 'A':
        return 4.0;
      case 'B':
        return 3.0;
      case 'C':
        return 2.0;
      case 'D':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Grade copyWith({
    String? id,
    String? uid,
    String? namaMahasiswa,
    String? matkul,
    String? kodeMatkul,
    double? nilai,
    String? grade,
    int? sks,
    int? semester,
    String? dosenUid,
    DateTime? tanggalInput,
  }) {
    return Grade(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      namaMahasiswa: namaMahasiswa ?? this.namaMahasiswa,
      matkul: matkul ?? this.matkul,
      kodeMatkul: kodeMatkul ?? this.kodeMatkul,
      nilai: nilai ?? this.nilai,
      grade: grade ?? this.grade,
      sks: sks ?? this.sks,
      semester: semester ?? this.semester,
      dosenUid: dosenUid ?? this.dosenUid,
      tanggalInput: tanggalInput ?? this.tanggalInput,
    );
  }
}

