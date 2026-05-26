### Last Updated: 20/02/2026 16:01
# *Dokumentasi week2_main.dart*

## Ringkasan
- Titik masuk aplikasi Week 2; inisialisasi Firebase lalu menjalankan `Week2App`.
- Menggunakan `StreamBuilder<User?>` untuk memantau `FirebaseAuth.instance.authStateChanges()`.
- Mengarahkan ke `Week2DashboardScreen` bila sudah login, atau `LoginPage` bila belum.

## Alur utama
1. `main()` memanggil `WidgetsFlutterBinding.ensureInitialized()` dan `Firebase.initializeApp` dengan `DefaultFirebaseOptions` dari week1.
2. `Week2App` merender `MaterialApp` tanpa debug banner.
3. `StreamBuilder` menunggu koneksi: tampilkan `CircularProgressIndicator` saat `waiting`.
4. `snapshot.hasData` true -> dashboard CRUD; selain itu -> layar login.

## Ketergantungan
- `firebase_core`, `firebase_auth` untuk init dan auth stream.
- Reuse `week1_firebase_options.dart` dan `LoginPage` dari Week 1.
- `Week2DashboardScreen` sebagai halaman utama pasca login.

# *Dokumentasi week2_mahasiswa_model.dart*

## Ringkasan
- Model data sederhana untuk entitas Mahasiswa.
- Menyimpan `id`, `nama`, `nim`, dan `jurusan`.

## API
- Konstruktor wajib isi seluruh field.
- `toMap()`: menyiapkan payload Map<String, dynamic> untuk dikirim ke Firestore (tanpa `id`).
- `factory Mahasiswa.fromFirestore(Map data, String id)`: membuat instance dari dokumen Firestore dengan menyuntikkan `id` dokumen.

## Catatan
- `id` dipisah dari map agar sesuai pola Firestore (id berasal dari doc.id).
- Tidak ada validasi di model; validasi dilakukan di UI form.

# Dokumentasi week2_firestore_service.dart

## Ringkasan
- Lapis layanan untuk operasi CRUD koleksi `mahasiswa` di Cloud Firestore.
- Menyediakan API sinkronisasi real-time via stream.

## Struktur
- `_collection`: `CollectionReference<Map<String, dynamic>>` ke `mahasiswa` (dibangun statis lewat `_buildCollection`).
- Konstruktor tanpa argumen, langsung menyiapkan koleksi.

## API
- `Future<void> tambahMahasiswa(Mahasiswa mhs)`: menambah dokumen baru dari `toMap()`.
- `Stream<List<Mahasiswa>> getMahasiswa()`: mengubah snapshot Firestore menjadi list `Mahasiswa` dengan `fromFirestore`.
- `Future<void> updateMahasiswa(Mahasiswa mhs)`: memperbarui dokumen berdasar `mhs.id`.
- `Future<void> deleteMahasiswa(String id)`: menghapus dokumen.

## Catatan
- Menggunakan paket `cloud_firestore`; pastikan sudah ditambahkan di `pubspec.yaml`.
- Stream menghasilkan update real-time; digunakan langsung oleh `StreamBuilder` di dashboard.

# *Dokumentasi week2_dashboard_screen.dart*

## Ringkasan
- Layar utama CRUD mahasiswa berbasis Firestore dengan refresh manual dan pull-to-refresh.
- StatefulWidget agar bisa memicu rebuild stream via `_streamKey` dan aksi refresh.

## Alur UI
1. `AppBar` dengan judul dan tombol refresh (memanggil `_refresh`).
2. `RefreshIndicator` membungkus `StreamBuilder<List<Mahasiswa>>` untuk data real-time.
3. State memeriksa:
   - `waiting`: tampilkan `CircularProgressIndicator`.
   - `hasError`: pesan gagal ambil data.
   - data kosong: teks "Belum ada data mahasiswa".
   - data ada: `ListView.builder` berisi `ListTile` per mahasiswa.
4. Aksi per item:
   - Edit -> buka dialog form terisi data lama.
   - Delete -> dialog konfirmasi lalu `deleteMahasiswa`.
5. `FloatingActionButton` membuka dialog form tambah.

## Dialog Form
- Menggunakan `GlobalKey<FormState>` untuk validasi wajib isi `nama`, `nim`, `jurusan`.
- Membuat objek `Mahasiswa` baru; pilih `tambahMahasiswa` atau `updateMahasiswa` tergantung ada/tidaknya parameter `mahasiswa`.
- Setelah sukses, dialog ditutup (dengan pengecekan `context.mounted`).

## Refresh
- `_refresh()` mengganti `_streamKey` dan menunggu event pertama stream; digunakan oleh ikon refresh dan gesture tarik.

## Ketergantungan
- `week2_firestore_service.dart` untuk CRUD.
- `week2_mahasiswa_model.dart` sebagai model data.
