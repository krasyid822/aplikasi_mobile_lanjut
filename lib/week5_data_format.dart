// FIRESTORE DATABASE SCHEMA
// Sistem Informasi Akademik Mahasiswa
// ============================================================================

// 1. USERS COLLECTION
// Path: /users/{uid}
// Menyimpan data profil mahasiswa
//
// Structure:
// {
//   uid: String,              // Firebase Auth UID (Document ID)
//   nama: String,             // Nama lengkap mahasiswa
//   email: String,            // Email kampus (unique)
//   nim: String,              // Nomor Induk Mahasiswa (unique)
//   jurusan: String,          // Nama Jurusan (dari majors collection)
//   prodi: String,            // Nama Program Studi (dari majors collection)
//   semester: String,         // Semester aktif (1-8)
//   photoUrl: String,         // URL foto profil (optional)
//   createdAt: Timestamp,     // Waktu registrasi
//   updatedAt: Timestamp,     // Waktu update terakhir
// }

// 2. GRADES COLLECTION
// Path: /grades/{gradeId}
// Menyimpan data nilai mahasiswa
//
// Structure:
// {
//   uid: String,              // Reference ke users collection
//   matkul: String,           // Nama mata kuliah (Pemrograman Mobile)
//   kodeMatkul: String,       // Kode MK (IF4001)
//   nilai: Double,            // Nilai angka (0-100)
//   grade: String,            // Grade (A/B/C/D/E)
//   sks: Integer,             // Jumlah SKS (1-4)
//   semester: Integer,        // Semester pengambilan (1-8)
//   tanggalInput: Timestamp,  // Waktu nilai diinput
// }

// 3. COURSES COLLECTION (Optional)
// Path: /courses/{courseId}
// Menyimpan data master mata kuliah
//
// Structure:
// {
//   kodeMatkul: String,       // Kode unik MK
//   nama: String,             // Nama mata kuliah
//   sks: Integer,             // SKS mata kuliah
//   semester: Integer,        // Semester di kurikulum
//   dosen: String,            // Nama dosen pengampu
//   deskripsi: String,        // Deskripsi singkat
//   prasyarat: Array,         // Mata kuliah prasyarat
// }

// 4. KRS COLLECTION (Optional) - Kartu Rencana Studi
// Path: /krs/{krsId}
// Menyimpan rencana studi mahasiswa
//
// Structure:
// {
//   uid: String,              // Reference ke users
//   semester: Integer,        // Semester aktif
//   matkulList: Array,        // Daftar kode MK yang diambil
//   totalSks: Integer,        // Total SKS yang diambil
//   status: String,           // approved/pending/rejected
//   tanggalPendaftaran: Timestamp,
//   tanggalPersetujuan: Timestamp,
// }

// 5. NOTIFICATIONS COLLECTION
// Path: /notifications/{notifId}
// Menyimpan riwayat notifikasi email (dikelola via Cloud Functions)
//
// Structure:
// {
//   uid: String,              // Reference ke users
//   email: String,            // Email tujuan
//   subject: String,          // Subject email
//   message: String,          // Isi pesan singkat
//   type: String,             // 'grade_released', 'grade_updated', 'welcome', 'krs_approved'
//   gradeId: String,          // Reference ke grades (jika ada)
//   status: String,           // pending/sent/failed
//   read: Boolean,            // Apakah sudah dibaca user
//   createdAt: Timestamp,     // Waktu dibuat
//   sentAt: Timestamp,        // Waktu email dikirim
//   readAt: Timestamp,        // Waktu dibaca user
//   errorMessage: String,     // Pesan error (jika status = failed)
// }

// 6. ADMINS COLLECTION
// Path: /admins/{uid}
// ...
// }

// 7. MAJORS COLLECTION
// Path: /majors/{majorId}
// Menyimpan data master Jurusan dan Program Studi
//
// Structure:
// {
//   name: String,             // Nama Jurusan (Teknik Elektro)
//   prodiList: Array,         // Daftar Nama Prodi (D3 Teknik Listrik, dll)
// }

// ============================================================================
// ADMIN & DOSEN WORKFLOW
// ============================================================================
// 1. Grade Input: Dosen memilih mahasiswa -> Input nilai -> Firestore Trigger
// 2. Email Notification: Firestore Trigger -> SendGrid/Nodemailer -> Update Status
// 3. KRS Approval: Mahasiswa submit -> Dosen Review -> Status Update (approved/rejected)
// 4. Report Generation: Admin generate PDF/Excel based on grades collection

// ============================================================================
// FIRESTORE SECURITY RULES (Apply di Firebase Console)
// ============================================================================

const String firestoreRules = '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper Functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isSignedIn() && exists(/databases/\$(database)/documents/admins/\$(request.auth.uid));
    }
    
    function isOwner(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }

    // Users - User hanya bisa access profil sendiri, Admin bisa lihat semua
    match /users/{uid} {
      allow read: if isOwner(uid) || isAdmin();
      allow write: if isOwner(uid);
    }
    
    // Grades - User hanya bisa baca nilai sendiri, Admin/Dosen bisa kelola
    match /grades/{gradeId} {
      allow read: if isOwner(resource.data.uid) || isAdmin();
      allow create, update, delete: if isAdmin();
    }
    
    // Admins - Hanya admin yang bisa edit data admin lain
    match /admins/{uid} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }
    
    // Courses - Semua user bisa baca
    match /courses/{courseId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // Majors - Semua user bisa baca
    match /majors/{majorId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }
    
    // KRS - User akses KRS sendiri, Admin bisa approve
    match /krs/{krsId} {
      allow read: if isOwner(resource.data.uid) || isAdmin();
      allow create: if isOwner(request.resource.data.uid);
      allow update: if (isOwner(resource.data.uid) && resource.data.status != 'approved') || isAdmin();
      allow delete: if isAdmin();
    }
    
    // Notifications - User baca notifikasi sendiri
    match /notifications/{notifId} {
      allow read: if isOwner(resource.data.uid) || isAdmin();
      allow update: if isOwner(resource.data.uid);
      allow create, delete: if false; // System only
    }
    
    // Error logs - System/Admin only
    match /error_logs/{logId} {
      allow read: if isAdmin();
      allow write: if false;
    }
  }
}
''';

// ============================================================================
// INDEXES - Buat di Firebase Console
// ============================================================================

const String firestoreIndexes = '''
Collection: grades
  Index 1: uid (Asc) + semester (Desc) + tanggalInput (Desc)
  Index 2: uid (Asc) + tanggalInput (Desc)

Collection: notifications
  Index 3: uid (Asc) + status (Asc) + createdAt (Desc)
  Index 4: uid (Asc) + read (Asc) + createdAt (Desc)

Collection: krs
  Index 5: uid (Asc) + semester (Desc) + status (Asc)

Collection: courses
  Index 6: semester (Asc) + kodeMatkul (Asc)
''';

// ============================================================================
// DEPLOYMENT CHECKLIST
// ============================================================================

const String deploymentChecklist = '''
SEBELUM PRODUCTION:
□ Firestore database created
□ Security rules applied
□ Indexes created
□ Test data loaded
□ Cloud Functions deployed
□ Backup strategy active
□ Monitoring setup
□ Documentation complete
''';


