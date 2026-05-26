import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Send email notification via Supabase
  /// This inserts into Supabase 'notifications' table which can trigger an Edge Function
  static Future<void> sendEmailViaSupabase({
    required String toEmail,
    required String subject,
    required String message,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'email': toEmail,
        'subject': subject,
        'message': message,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Supabase Email Triggered successfully');
    } catch (e) {
      debugPrint('Error triggering Supabase Email: $e');
    }
  }

  /// Get notification history untuk user
  static Stream<List<Map<String, dynamic>>> getNotificationHistory(String uid) {
    return _firestore
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  /// Get unread notification count
  static Stream<int> getUnreadNotificationCount(String uid) {
    return _firestore
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'sent')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Hapus notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }
}

/// Email Template yang digunakan di Cloud Functions
class EmailTemplates {
  /// Template untuk nilai baru
  static String gradeReleaseTemplate({
    required String name,
    required String matkul,
    required String kodeMatkul,
    required double nilai,
    required String grade,
    required int sks,
    required int semester,
  }) {
    return '''
    <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                    color: white; padding: 20px; border-radius: 5px; text-align: center; }
          .content { background: #f9f9f9; padding: 20px; margin: 20px 0; border-radius: 5px; }
          table { width: 100%; border-collapse: collapse; }
          th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
          th { background-color: #667eea; color: white; }
          .footer { text-align: center; font-size: 12px; color: #666; margin-top: 30px; }
          .highlight { color: #667eea; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>📊 Nilai Baru - Sistem Informasi Akademik</h2>
          </div>
          
          <p>Assalamu'alaikum <span class="highlight">$name</span>,</p>
          
          <p>Kami dengan senang hati memberitahukan bahwa nilai untuk mata kuliah berikut telah diumumkan:</p>
          
          <div class="content">
            <table>
              <tr>
                <th>Keterangan</th>
                <th>Detail</th>
              </tr>
              <tr>
                <td>Mata Kuliah</td>
                <td>$matkul</td>
              </tr>
              <tr>
                <td>Kode MK</td>
                <td>$kodeMatkul</td>
              </tr>
              <tr>
                <td>Nilai</td>
                <td><span class="highlight">$nilai</span></td>
              </tr>
              <tr>
                <td>Grade</td>
                <td><span class="highlight">$grade</span></td>
              </tr>
              <tr>
                <td>SKS</td>
                <td>$sks</td>
              </tr>
              <tr>
                <td>Semester</td>
                <td>$semester</td>
              </tr>
            </table>
          </div>
          
          <p>Untuk informasi lebih lengkap mengenai nilai Anda, silakan:</p>
          <ul>
            <li>Buka aplikasi Sistem Informasi Akademik</li>
            <li>Login dengan email dan password Anda</li>
            <li>Lihat detail di menu Nilai atau Laporan</li>
          </ul>
          
          <p>Jika ada pertanyaan, hubungi admin akademik.</p>
          
          <div class="footer">
            <p>Email ini dikirim secara otomatis oleh Sistem Informasi Akademik Mahasiswa</p>
            <p>© ${DateTime.now().year} Universitas XXX - Semua Hak Dilindungi</p>
          </div>
        </div>
      </body>
    </html>
    ''';
  }

  /// Template untuk welcome email
  static String welcomeTemplate({
    required String name,
    required String nim,
    required String jurusan,
  }) {
    return '''
    <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                    color: white; padding: 20px; border-radius: 5px; text-align: center; }
          .content { background: #f9f9f9; padding: 20px; margin: 20px 0; border-radius: 5px; }
          .highlight { color: #667eea; font-weight: bold; }
          .footer { text-align: center; font-size: 12px; color: #666; margin-top: 30px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>🎓 Selamat Datang di Sistem Informasi Akademik</h2>
          </div>
          
          <p>Assalamu'alaikum <span class="highlight">$name</span>,</p>
          
          <p>Anda telah berhasil terdaftar di <strong>Sistem Informasi Akademik Mahasiswa</strong>.</p>
          
          <div class="content">
            <h3>Data Profil Anda:</h3>
            <ul>
              <li><strong>Nama:</strong> $name</li>
              <li><strong>NIM:</strong> $nim</li>
              <li><strong>Jurusan:</strong> $jurusan</li>
            </ul>
          </div>
          
          <h3>Fitur-Fitur yang Tersedia:</h3>
          <ul>
            <li>📊 <strong>Dashboard</strong> - Lihat ringkasan akademik Anda</li>
            <li>📈 <strong>Nilai</strong> - Pantau semua nilai per semester</li>
            <li>📄 <strong>Laporan</strong> - Export KHS dalam format PDF</li>
            <li>📧 <strong>Notifikasi</strong> - Terima update otomatis nilai baru</li>
          </ul>
          
          <p>Anda dapat mengakses semua fitur melalui aplikasi mobile kami.</p>
          
          <p>Jika ada pertanyaan atau membutuhkan bantuan, silakan hubungi admin akademik.</p>
          
          <div class="footer">
            <p>Email ini dikirim secara otomatis oleh Sistem Informasi Akademik Mahasiswa</p>
            <p>© ${DateTime.now().year} Universitas XXX - Semua Hak Dilindungi</p>
          </div>
        </div>
      </body>
    </html>
    ''';
  }
}
