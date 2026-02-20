### Last Updated: 20/02/2026 16:06
# *Dokumentasi Modul Week 1 (Firebase Auth)*

## week1_main.dart
- **Peran**: Entry point modul Week 1; inisialisasi Firebase lalu menjalankan `Week1App`.
- **Alur**:
  1. `main()` memanggil `WidgetsFlutterBinding.ensureInitialized()` dan `Firebase.initializeApp` dengan `DefaultFirebaseOptions` (generated) dari `week1_firebase_options.dart`.
  2. `Week1App` merender `MaterialApp` tanpa debug banner.
  3. `StreamBuilder<User?>` mendengar `FirebaseAuth.instance.authStateChanges()`:
     - `waiting`: tampilkan `CircularProgressIndicator`.
     - ada user: arahkan ke `DashboardPage`.
     - tidak ada user: arahkan ke `LoginPage`.
- **Dependensi**: `firebase_core`, `firebase_auth`, file generated `week1_firebase_options.dart`, UI `week1_login_page.dart`, `week1_dashboard_page.dart`.

## week1_login_page.dart
- **Peran**: Layar login dengan form email & password, validasi basic, aksi login dan reset password.
- **Alur utama**:
  - Form memakai `GlobalKey<FormState>`; validasi email format regex dan password minimal 6 karakter.
  - `login()`: panggil `FirebaseAuth.instance.signInWithEmailAndPassword`; jika sukses, `Navigator.pushReplacement` ke `Week2DashboardScreen` (sudah disesuaikan ke modul Week 2).
  - `resetPassword()`: kirim email reset lewat `sendPasswordResetEmail`, tampilkan snackbar sesuai hasil.
  - Tombol navigasi ke register (`RegisterPage`).
- **UI**: Ikon akun, dua `TextFormField` (email, password), tombol `Login`, `Reset`, dan tautan ke pendaftaran.

## week1_register_page.dart
- **Peran**: Layar pendaftaran akun baru dengan email/password dan konfirmasi password.
- **Alur utama**:
  - Validasi: email wajib & format, password wajib & minimal 6, konfirmasi harus sama dengan password.
  - `register()`: panggil `FirebaseAuth.instance.createUserWithEmailAndPassword`; jika sukses, `pushReplacement` ke `DashboardPage`.
  - Navigasi balik ke login via tombol teks.
- **UI**: Ikon person add, tiga `TextFormField` (email, password, konfirmasi), tombol `Daftar`, tautan ke login.

## week1_dashboard_page.dart
- **Peran**: Halaman setelah login/daftar; menampilkan email user dan menyediakan logout.
- **Alur**:
  - Ambil `FirebaseAuth.instance.currentUser` untuk menampilkan email.
  - Tombol logout memanggil `FirebaseAuth.instance.signOut()` lalu `pushReplacement` ke `LoginPage` (dengan `mounted` check).
- **UI**: AppBar dengan title "Dashboard" dan ikon logout; body teks sambutan.

## week1_firebase_options.dart
- **Peran**: File generated berisi konfigurasi `DefaultFirebaseOptions` untuk platform (Android/iOS/web/etc.).
- **Catatan**: Jangan diubah manual; dibangkitkan oleh `flutterfire configure`.

## Integrasi & Navigasi
- Aplikasi launcher (di `lib/main.dart`) dapat meluncurkan `Week1App` langsung.
- Login default Week1 kini diarahkan ke `Week2DashboardScreen` setelah sukses agar selaras modul lanjutan; sesuaikan jika ingin tetap ke dashboard Week1.

## Pengujian yang disarankan
- Daftar akun baru (email/password valid) → diarahkan ke Dashboard, email tampil.
- Logout lalu login kembali dengan kredensial tadi.
- Uji validasi: email kosong/format salah, password pendek, konfirmasi beda.
- Uji reset password: masukkan email valid, cek email reset terkirim (lihat log Firebase/Auth emulator bila pakai emulator).
