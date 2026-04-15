Deploy Cloud Functions to send FCM notifications

1. Prasyarat
- Pastikan Anda sudah menginisialisasi Firebase di project dan login: `firebase login` dan `firebase use --add`.
- Node.js 18 dan npm tersedia.

2. Install dependencies

```bash
cd functions
npm install
```

3. Deploy functions

```bash
npm run build # jika diperlukan
firebase deploy --only functions
```

Catatan:
- Fungsi `onCampaignCreated` mengirim notifikasi ke topic `campaigns`. Semua device yang subscribe ke topic ini akan menerima notifikasi ketika campaign baru dibuat.
- Fungsi `onDonationCreated` mengirim notifikasi ke donor dan owner campaign (jika ada). Pastikan user document memiliki field `fcmTokens` berisi array token FCM.
- Anda mungkin perlu mengatur billing atau region untuk Cloud Functions sesuai kebutuhan.
