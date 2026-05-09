/**
 * Cloud Functions untuk Sistem Informasi Akademik Mahasiswa
 * File ini untuk di-deploy ke Firebase Cloud Functions
 *
 * Setup:
 * 1. cd functions
 * 2. npm install
 * 3. firebase deploy --only functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

if (!admin.apps.length) {
  admin.initializeApp();
}

// Configure email service
// Replace dengan email dan password Anda
// Untuk Gmail: Enable "Less secure app access" atau gunakan App Password
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER || "your-email@gmail.com",
    pass: process.env.EMAIL_PASSWORD || "your-app-password",
  },
});

/**
 * Trigger: Saat document grades ditambahkan
 * Fungsi: Kirim email notifikasi ke mahasiswa
 */
exports.sendGradeNotification = functions.firestore
  .document("grades/{gradeId}")
  .onCreate(async (snap, context) => {
    try {
      const gradeData = snap.data();
      const gradeId = context.params.gradeId;

      // Get user data
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(gradeData.uid)
        .get();

      if (!userDoc.exists) {
        console.log("User tidak ditemukan");
        return;
      }

      const userData = userDoc.data();

      // Prepare email content
      const emailContent = `
        <h2>Nilai Baru - Sistem Informasi Akademik</h2>
        <p>Assalamu'alaikum ${userData.nama},</p>

        <p>Kami dengan senang hati memberitahukan bahwa nilai untuk mata kuliah berikut telah diumumkan:</p>

        <table border="1" cellpadding="10">
          <tr>
            <th>Keterangan</th>
            <th>Detail</th>
          </tr>
          <tr>
            <td>Mata Kuliah</td>
            <td>${gradeData.matkul}</td>
          </tr>
          <tr>
            <td>Kode Mata Kuliah</td>
            <td>${gradeData.kodeMatkul}</td>
          </tr>
          <tr>
            <td>Nilai</td>
            <td>${gradeData.nilai}</td>
          </tr>
          <tr>
            <td>Grade</td>
            <td>${gradeData.grade}</td>
          </tr>
          <tr>
            <td>SKS</td>
            <td>${gradeData.sks}</td>
          </tr>
          <tr>
            <td>Semester</td>
            <td>${gradeData.semester}</td>
          </tr>
        </table>

        <p>Untuk informasi lebih lengkap, silakan login ke aplikasi Sistem Informasi Akademik.</p>

        <p>Terima kasih.</p>
        <p>Tim Sistem Informasi Akademik</p>
      `;

      // Send email
      const mailOptions = {
        from: process.env.EMAIL_USER || "your-email@gmail.com",
        to: userData.email,
        subject: `Nilai Baru - ${gradeData.matkul}`,
        html: emailContent,
      };

      await transporter.sendMail(mailOptions);

      // Log success
      console.log(`Email sent to ${userData.email}`);

      // Update notification status in Firestore
      await admin
        .firestore()
        .collection("notifications")
        .add({
          uid: gradeData.uid,
          email: userData.email,
          subject: `Nilai Baru - ${gradeData.matkul}`,
          message: `Nilai untuk ${gradeData.matkul} telah keluar`,
          type: "grade_released",
          gradeId: gradeId,
          status: "sent",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (error) {
      console.error("Error sending email:", error);

      // Log error to Firestore
      await admin.firestore().collection("error_logs").add({
        function: "sendGradeNotification",
        error: error.message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

/**
 * Trigger: Saat document grades diupdate
 * Fungsi: Kirim email notifikasi update nilai
 */
exports.notifyGradeUpdate = functions.firestore
  .document("grades/{gradeId}")
  .onUpdate(async (change, context) => {
    try {
      const newGradeData = change.after.data();
      const oldGradeData = change.before.data();

      // Check if nilai berubah
      if (newGradeData.nilai === oldGradeData.nilai) {
        return; // No change in value
      }

      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(newGradeData.uid)
        .get();

      if (!userDoc.exists) return;

      const userData = userDoc.data();

      const emailContent = `
        <h2>Koreksi Nilai - Sistem Informasi Akademik</h2>
        <p>Assalamu'alaikum ${userData.nama},</p>

        <p>Nilai mata kuliah berikut telah diperbarui:</p>

        <table border="1" cellpadding="10">
          <tr>
            <th>Keterangan</th>
            <th>Nilai Lama</th>
            <th>Nilai Baru</th>
          </tr>
          <tr>
            <td>Nilai</td>
            <td>${oldGradeData.nilai}</td>
            <td>${newGradeData.nilai}</td>
          </tr>
          <tr>
            <td>Grade</td>
            <td>${oldGradeData.grade}</td>
            <td>${newGradeData.grade}</td>
          </tr>
        </table>

        <p>Silakan periksa sistem akademik untuk detail lebih lanjut.</p>
        <p>Terima kasih.</p>
      `;

      const mailOptions = {
        from: process.env.EMAIL_USER || "your-email@gmail.com",
        to: userData.email,
        subject: `Koreksi Nilai - ${newGradeData.matkul}`,
        html: emailContent,
      };

      await transporter.sendMail(mailOptions);
      console.log(`Update email sent to ${userData.email}`);
    } catch (error) {
      console.error("Error in notifyGradeUpdate:", error);
    }
  });

/**
 * Trigger: Saat user baru didaftar
 * Fungsi: Kirim welcome email
 */
exports.sendWelcomeEmail = functions.firestore
  .document("users/{uid}")
  .onCreate(async (snap, context) => {
    try {
      const userData = snap.data();

      const emailContent = `
        <h2>Selamat Datang - Sistem Informasi Akademik</h2>
        <p>Assalamu'alaikum ${userData.nama},</p>

        <p>Anda telah berhasil mendaftar di Sistem Informasi Akademik Mahasiswa.</p>

        <p>Data Profil:</p>
        <ul>
          <li>Nama: ${userData.nama}</li>
          <li>NIM: ${userData.nim}</li>
          <li>Email: ${userData.email}</li>
          <li>Jurusan: ${userData.jurusan}</li>
        </ul>

        <p>Anda dapat mengakses nilai dan laporan akademik melalui aplikasi mobile kami.</p>

        <p>Jika ada pertanyaan, silakan hubungi admin.</p>
        <p>Terima kasih</p>
      `;

      const mailOptions = {
        from: process.env.EMAIL_USER || "your-email@gmail.com",
        to: userData.email,
        subject: "Selamat Datang - Sistem Informasi Akademik",
        html: emailContent,
      };

      await transporter.sendMail(mailOptions);
      console.log(`Welcome email sent to ${userData.email}`);
    } catch (error) {
      console.error("Error in sendWelcomeEmail:", error);
    }
  });

// Test function untuk debug
exports.testEmail = functions.https.onCall(async (data, context) => {
  try {
    // Only allow for authenticated users in development
    if (!context.auth && !process.env.ALLOW_TEST) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const testEmail = data.email || "test@example.com";

    const mailOptions = {
      from: process.env.EMAIL_USER || "your-email@gmail.com",
      to: testEmail,
      subject: "Test Email - Sistem Informasi Akademik",
      html: "<h2>Email Test</h2><p>Test email berhasil dikirim!</p>",
    };

    await transporter.sendMail(mailOptions);

    return { success: true, message: "Test email sent successfully" };
  } catch (error) {
    console.error("Error in testEmail:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * SETUP INSTRUCTIONS:
 *
 * 1. Create folders:
 *    firebase init functions
 *
 * 2. Install dependencies in functions folder:
 *    npm install firebase-admin firebase-functions nodemailer
 *
 * 3. Set environment variables:
 *    firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="your-app-password"
 *
 * 4. Deploy:
 *    firebase deploy --only functions
 *
 * 5. For Gmail:
 *    - Enable "Less secure app access" OR
 *    - Use App Password (recommended):
 *      a. Enable 2FA in Google Account
 *      b. Go to myaccount.google.com/apppasswords
 *      c. Use generated 16-char password
 */

