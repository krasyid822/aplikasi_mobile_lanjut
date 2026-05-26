import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../logic/services/firestore_service.dart';
import '../../logic/models/donation_model.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat Donasi')),
        body: const Center(child: Text('Anda belum login')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Donasi')),
      body: StreamBuilder<List<Donation>>(
        stream: FirestoreService().getDonationsForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          final donations = snapshot.data ?? const <Donation>[];
          if (donations.isEmpty) {
            return const Center(child: Text('Belum ada riwayat donasi'));
          }
          return ListView.builder(
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final d = donations[index];
              final date = d.date;
              return ListTile(
                title: Text('Campaign: ${d.campaignId}'),
                subtitle: Text('${d.amount} — ${date.toLocal()}'),
              );
            },
          );
        },
      ),
    );
  }
}
