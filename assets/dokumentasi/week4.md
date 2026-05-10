# 🎁 WEEK 4 - APLIKASI DONASI ONLINE (CROWDFUNDING)
## Dokumentasi Lengkap & Panduan Implementasi

**Versi**: 1.0.0  
**Status**: Completed ✅

Aplikasi mobile berbasis Flutter untuk platform donasi online (crowdfunding) yang mengintegrasikan layanan **Firebase** dan **Supabase** untuk pengelolaan konten, transaksi donasi, dan pengiriman notifikasi.

---

## 📱 Fitur Utama

### 1. **Sistem Autentikasi**
- Pendaftaran akun donatur baru.
- Login menggunakan Email dan Password.
- Manajemen sesi pengguna (Auto-login).

### 2. **Manajemen Campaign Donasi**
- Menampilkan daftar program donasi secara real-time.
- Detail campaign lengkap dengan progres penggalangan dana.
- Fitur penambahan campaign baru oleh admin (termasuk upload gambar ke Firebase Storage).

### 3. **Fitur Donasi**
- Nominal donasi fleksibel.
- Pencatatan riwayat donasi per pengguna.
- Pembaruan otomatis total dana terkumpul pada campaign terkait.

### 4. **Pusat Notifikasi (Messaging)**
- Integrasi Firebase Cloud Messaging (FCM) untuk notifikasi sistem.
- Integrasi Supabase Messaging untuk pengiriman pengingat donasi.

---

## 📁 Struktur File Utama

```
lib/
├── week4_main.dart                   # Entry point aplikasi donasi
├── week4_auth_service.dart           # Layanan autentikasi Firebase
├── week4_firestore_service.dart      # Manajemen data (Campaign & Donasi)
├── week4_storage_service.dart        # Layanan upload gambar ke Firebase Storage
├── week4_messaging_service.dart      # Layanan FCM (Firebase)
├── week4_supabase_messaging.dart     # Layanan Messaging (Supabase)
├── week4_campaign_model.dart         # Model data program donasi
├── week4_donation_model.dart         # Model data transaksi donasi
├── week4_login_screen.dart           # UI Halaman masuk
├── week4_register_screen.dart        # UI Halaman daftar
├── week4_home_screen.dart            # UI Dashboard utama
├── week4_campaign_detail_screen.dart # UI Detail program donasi
└── week4_add_campaign_screen.dart    # UI Form pembuatan program baru
```

---

## 🔧 Konfigurasi Layanan

### 1. Firebase Firestore
Pastikan koleksi berikut telah dibuat:
- **`campaigns`**: Menyimpan info program donasi (judul, deskripsi, target, terkumpul, imageUrl).
- **`donations`**: Menyimpan riwayat transaksi donasi (uid, campaignId, nominal, timestamp).

### 2. Firebase Storage
- Aktifkan bucket Storage untuk menyimpan gambar campaign.
- Atur rules agar hanya user terautentikasi yang bisa mengunggah gambar.

### 3. Supabase Integration
- Digunakan untuk pengiriman pesan pengingat melalui database Supabase yang diinisialisasi pada `week3_supabase_config.dart`.

---

## 🚀 Alur Kerja Aplikasi

### Alur Berdonasi:
1. Pengguna memilih salah satu **Campaign** di halaman utama.
2. Pengguna memasukkan nominal pada halaman **Detail**.
3. Sistem menyimpan data ke koleksi `donations`.
4. Sistem menjalankan *Atomic Update* untuk menambah jumlah dana terkumpul pada koleksi `campaigns`.
5. Notifikasi sukses dikirim ke pengguna.

---

## 📈 Indikator Penilaian
- **Integrasi Storage** (30%): Berhasil mengunggah dan menampilkan gambar campaign.
- **Data Consistency** (30%): Sinkronisasi dana terkumpul saat donasi berhasil.
- **Messaging System** (20%): Berhasil menerima pesan notifikasi.
- **UI/UX** (20%): Tampilan informatif dan mudah digunakan.

---

**Last Updated**: May 2026
**Course**: Aplikasi Mobile Lanjut
