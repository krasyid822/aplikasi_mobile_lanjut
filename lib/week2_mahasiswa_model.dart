class Mahasiswa {
 String id;
 String nama;
 String nim;
 String jurusan;
 Mahasiswa({
 required this.id,
 required this.nama,
 required this.nim,
 required this.jurusan,
 });
 Map<String, dynamic> toMap() {
 return {
 'nama': nama,
 'nim': nim,
 'jurusan': jurusan,
 };
 }
 factory Mahasiswa.fromFirestore(Map<String, dynamic> data, String id) {
 return Mahasiswa(
 id: id,
 nama: data['nama'],
 nim: data['nim'],
 jurusan: data['jurusan'],
 );
 }
}