# 🛒 WEEK 3 - APLIKASI TOKO ONLINE (E-COMMERCE)
## Dokumentasi Lengkap & Panduan Implementasi

**Versi**: 1.0.0  
**Status**: Completed ✅

Aplikasi mobile berbasis Flutter untuk toko online yang mengintegrasikan layanan **Firebase** (Auth & Firestore) dan **Supabase Storage** untuk pengelolaan katalog produk, manajemen inventaris, dan proses belanja pelanggan.

---

## 📱 Fitur Utama

### 1. **Sistem Peran (Role Management)**
- **Pelanggan**: Dapat melihat produk, menambah ke keranjang, dan mengelola pesanan.
- **Admin**: Akses khusus untuk mengelola stok produk (Tambah, Edit, Hapus) dan memantau pesanan masuk.

### 2. **Katalog Produk Real-time**
- Menampilkan daftar produk secara dinamis dari Firestore.
- Pencarian dan kategori produk.
- Detail produk dengan integrasi gambar dari Supabase Storage.

### 3. **Keranjang Belanja & Checkout**
- Menambah/mengurangi jumlah produk di keranjang.
- Perhitungan total harga otomatis menggunakan **State Management (Provider)**.
- Proses checkout sederhana dengan pencatatan riwayat pesanan.

### 4. **Manajemen Produk (Admin Only)**
- Form input produk baru dengan validasi.
- Fitur **Upload Gambar** ke Supabase Storage.
- Fitur **Edit dan Hapus** produk yang sudah ada.

---

## 📁 Struktur File Utama

```
lib/
├── week3_main.dart                 # Entry point dan shell aplikasi (Bottom Nav)
├── week3_shop_controller.dart      # State Management (Provider) untuk Toko
├── week3_product_service.dart      # Layanan CRUD Firestore untuk Produk
├── week3_supabase_config.dart      # Konfigurasi koneksi Supabase Storage
├── week3_product_model.dart        # Model data Produk
├── week3_order_model.dart          # Model data Pesanan/Order
├── week3_product_list.dart         # UI Katalog Produk untuk Pelanggan
├── week3_cart_page.dart            # UI Halaman Keranjang Belanja
├── week3_customer_dashboard_page.dart # UI Profil & Dashboard Pelanggan
├── week3_admin_dashboard.dart      # UI Manajemen Produk & Pesanan (Admin)
├── week3_admin_login_page.dart     # UI Halaman Masuk khusus Admin/Pelanggan
└── week3_order_status_ui.dart      # UI Pelacakan Status Pesanan
```

---

## 🔧 Konfigurasi Layanan

### 1. Firebase Firestore
- Koleksi **`products`**: Menyimpan data teknis produk (nama, harga, stok, deskripsi, image_url).
- Koleksi **`orders`**: Menyimpan data transaksi pelanggan.

### 2. Supabase Storage
- **Bucket `PAML`**: Digunakan untuk menyimpan file gambar produk secara cloud-native.
- Konfigurasi URL dan Anon Key terdapat pada `week3_supabase_config.dart`.

---

## 🚀 Alur Kerja Belanja (State Management)
1. Pengguna memilih produk → `Week3ShopController` menambah item ke state internal.
2. Badge keranjang di AppBar terupdate secara reaktif.
3. Halaman `CartPage` membaca data dari Provider untuk menampilkan ringkasan belanja.
4. Klik **Checkout** → Data dikirim ke Firestore dan keranjang dikosongkan.

---

## 📈 Indikator Penilaian
- **State Management** (25%): Penggunaan Provider untuk sinkronisasi data antar halaman.
- **Cloud Storage** (25%): Keberhasilan upload dan rendering gambar dari Supabase.
- **CRUD Operations** (25%): Kemampuan Admin mengelola data produk secara utuh.
- **Auth & Security** (15%): Pemisahan hak akses antara Admin dan Pelanggan.
- **UI/UX** (10%): Navigasi yang lancar menggunakan Bottom Navigation Bar.

---

**Last Updated**: May 2026
**Course**: Aplikasi Mobile Lanjut
