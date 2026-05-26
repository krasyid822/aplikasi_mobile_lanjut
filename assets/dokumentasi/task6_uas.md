# Task 6 - UAS: Local AI Agent (Google Gemma 2B)

## 📝 Deskripsi Proyek
Modul ini merupakan tugas akhir (UAS) untuk mata kuliah **Praktik Aplikasi Mobile Lanjut**. Proyek ini mengimplementasikan **Agent AI Lokal** yang berjalan sepenuhnya di perangkat (*on-device*) tanpa memerlukan koneksi internet setelah model berhasil diunduh.

Menggunakan model bahasa besar (**LLM**) yaitu **Google Gemma 2B IT** dengan teknik kuantisasi 4-bit (INT4) yang dioptimalkan untuk perangkat mobile melalui teknologi **LiteRT** (sebelumnya TFLite).

---

## 🏗️ Arsitektur Proyek
Proyek ini mengikuti prinsip **Presentation-Logic Separation** untuk memastikan kode yang bersih, modular, dan mudah dipelihara:

### 🧠 Logic Layer (`lib/task6/logic/`)
*   **Models**: Mendefinisikan blueprint data (misal: `MessageEntry`).
*   **Services**: Menangani komunikasi tingkat rendah dengan mesin AI (`flutter_gemma`) dan pengunduhan file besar menggunakan `Dio`.
*   **Providers**: Mengelola state aplikasi (loading, progress, messages) menggunakan **Provider Pattern** sebagai jembatan antara UI dan Logic.

### 🎨 Presentation Layer (`lib/task6/ui/`)
*   **Screens**: Halaman utama chat (`ChatSessionPage`) dan halaman pengaturan (`SettingsPage`).
*   **Widgets**: Komponen UI granular seperti `ChatBubble` yang mendukung rendering Markdown dan `MetricsPanel` untuk statistik AI.
*   **Styles**: Konfigurasi visual dan format data global.

---

## 🚀 Fitur Unggulan

### 1. Hybrid Backend AI
Pengguna dapat memilih antara mode **GPU** (untuk performa tinggi/cepat) atau **CPU** (untuk stabilitas pada perangkat dengan RAM terbatas). Pengaturan ini tersedia di menu Settings.

### 2. Diagnostic Console (Thinking Process)
Menyediakan transparansi penuh terhadap proses kerja AI. Pengguna dapat melihat:
*   **Token Counter**: Jumlah kata yang dihasilkan secara real-time.
*   **Inference Timer**: Waktu pemrosesan dalam detik.
*   **Thought Logs**: Log teknis internal mulai dari encoding prompt hingga penerimaan token pertama.

### 3. Advanced Markdown & Code Support
Respon AI dirender menggunakan format **Markdown** yang mendukung:
*   Format teks (Bold, Italic, Lists).
*   **Code Block Copy**: Tombol khusus untuk menyalin potongan kode program secara instan ke clipboard.

### 4. Smart Model Management
*   **Internal Downloader**: Menggunakan `Dio` untuk download yang lebih stabil via Mobile Data/Wi-Fi dengan progress bar detail.
*   **Local Storage**: Model disimpan di folder `/sdcard/Download/ai_bin` untuk memudahkan pengelolaan manual.
*   **Model Cleanup**: Fitur untuk menghapus model dari storage guna mengosongkan ruang penyimpanan.

### 5. Stability Mechanisms
*   **Stop Button**: Fitur untuk menghentikan generasi token di tengah jalan.
*   **Hard Restart**: Tombol darurat di AppBar untuk membersihkan RAM dan memuat ulang aplikasi jika mesin AI macet.
*   **Auto-Recovery**: Sistem secara otomatis mereset sesi jika mendeteksi mesin AI dalam status sibuk (*busy*).

---

## 🛠️ Spesifikasi Teknis
*   **Base Model**: Google Gemma 2B Instruction Tuned.
*   **Quantization**: 4-bit INT4 (Mengurangi ukuran dari ~10GB menjadi ~1.3GB).
*   **Inference Engine**: Google LiteRT (MediaPipe GenAI).
*   **Minimum Requirements**: Android 11+ (API 30), sisa RAM bebas ~1.5GB.

---

## 📖 Panduan Penggunaan
1.  **Izin Akses**: Saat pertama kali dibuka, aplikasi akan meminta izin "Kelola Semua File". Ini wajib diberikan agar aplikasi bisa menulis file model berukuran besar di folder Download.
2.  **Pemilihan Mode**: Masuk ke menu **Settings** (ikon gerigi) untuk memilih antara mode GPU atau CPU.
3.  **Unduhan Pertama**: Klik tombol **Install Model**. Pastikan koneksi internet stabil (disarankan Wi-Fi karena ukuran file ~1.3GB).
4.  **Chatting**: Setelah status menjadi "Siap", Anda bisa bertanya apa saja (saat ini model dioptimalkan untuk Bahasa Inggris).
5.  **Monitoring**: Klik ikon **Terminal** di pojok kanan atas untuk memastikan AI tidak sedang macet saat memproses prompt panjang.

---
*Dibuat oleh: Rasyid Kurniawan - Tugas UAS Praktik Aplikasi Mobile Lanjut*
