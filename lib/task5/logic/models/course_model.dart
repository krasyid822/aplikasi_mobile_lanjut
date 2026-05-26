class Course {
  final String id;
  final String kodeMatkul;
  final String nama;
  final int sks;
  final int semester;
  final String deskripsi;

  Course({
    required this.id,
    required this.kodeMatkul,
    required this.nama,
    required this.sks,
    required this.semester,
    this.deskripsi = '',
  });

  factory Course.fromJson(Map<String, dynamic> json, String id) {
    return Course(
      id: id,
      kodeMatkul: json['kodeMatkul'] ?? '',
      nama: json['nama'] ?? '',
      sks: json['sks'] ?? 0,
      semester: json['semester'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kodeMatkul': kodeMatkul,
      'nama': nama,
      'sks': sks,
      'semester': semester,
      'deskripsi': deskripsi,
    };
  }
}
