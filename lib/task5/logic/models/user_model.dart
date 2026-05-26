class StudentUser {
  final String uid;
  final String nama;
  final String email;
  final String nim;
  final String jurusan;
  final String prodi;
  final String semester;
  final String photoUrl;
  final bool emailNotificationsEnabled;
  final DateTime createdAt;

  StudentUser({
    required this.uid,
    required this.nama,
    required this.email,
    required this.nim,
    required this.jurusan,
    required this.prodi,
    required this.semester,
    this.photoUrl = '',
    this.emailNotificationsEnabled = true,
    required this.createdAt,
  });

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      uid: json['uid'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      nim: json['nim'] ?? '',
      jurusan: json['jurusan'] ?? '',
      prodi: json['prodi'] ?? '',
      semester: json['semester'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      emailNotificationsEnabled: json['emailNotificationsEnabled'] ?? true,
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
      'nim': nim,
      'jurusan': jurusan,
      'prodi': prodi,
      'semester': semester,
      'photoUrl': photoUrl,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  StudentUser copyWith({
    String? uid,
    String? nama,
    String? email,
    String? nim,
    String? jurusan,
    String? prodi,
    String? semester,
    String? photoUrl,
    bool? emailNotificationsEnabled,
    DateTime? createdAt,
  }) {
    return StudentUser(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nim: nim ?? this.nim,
      jurusan: jurusan ?? this.jurusan,
      prodi: prodi ?? this.prodi,
      semester: semester ?? this.semester,
      photoUrl: photoUrl ?? this.photoUrl,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
