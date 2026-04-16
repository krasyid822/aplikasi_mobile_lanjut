import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'week4_firestore_service.dart';
import 'week4_auth_service.dart';
import 'week4_messaging_service.dart';
import 'week4_add_campaign_screen.dart';
import 'week4_campaign_detail_screen.dart';
import 'week4_login_screen.dart';
import 'week4_donation_history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FirestoreService _fs = FirestoreService();
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final role = await _fs.getUserRole(uid);
    if (!mounted) return;
    setState(() => _role = role ?? 'user');
  }

  Future<void> _logout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await MessagingService.removeToken(uid);
      await MessagingService.unsubscribeFromCampaignsTopic();
    }
    await AuthService().logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Campaign'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
            ),
            icon: const Icon(Icons.history),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fs.getCampaigns(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final campaigns = snapshot.data!.docs;
          if (campaigns.isEmpty) {
            return const Center(child: Text('Belum ada campaign'));
          }
          return ListView.builder(
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final doc = campaigns[index];
              final id = doc.id;
              final raw =
                  doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
              final title = raw['title'] ?? '';
              final imageUrl = raw['imageUrl'] ?? '';
              final collected = raw['collected'] ?? 0;
              final target = raw['target'] ?? 0;
              final ownerId = raw['ownerId'] ?? '';
              final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final canEdit = _role == 'admin' || ownerId == currentUid;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(width: 64, height: 64),
                  title: Text(title),
                  subtitle: Text('Terkumpul: $collected / $target'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CampaignDetailScreen(
                          id: id,
                          title: title,
                          description: raw['description'] ?? '',
                          target: target,
                          collected: collected,
                          imageUrl: imageUrl,
                          ownerId: ownerId,
                          canEdit: canEdit,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _role == 'admin'
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCampaignScreen()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
