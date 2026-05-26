import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/services/auth_service.dart';
import 'package:intl/intl.dart';

class Week5NotificationsPage extends StatelessWidget {
  const Week5NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUid = authService.currentUser?.uid ?? '';
    final firestore = FirebaseFirestore.instance;

    // Logic: Admin can see ALL notifications, Student only their own
    Query query = firestore.collection('notifications').orderBy('createdAt', descending: true);
    
    if (currentUid != 'YXiA3QBe5acGWdwNabpGP2xOwLz2') {
      query = query.where('uid', isEqualTo: currentUid);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUid == 'YXiA3QBe5acGWdwNabpGP2xOwLz2' ? 'Log Notifikasi (Admin)' : 'Notifikasi Akademik'),
        backgroundColor: currentUid == 'YXiA3QBe5acGWdwNabpGP2xOwLz2' ? Colors.blueGrey : Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final notif = docs[index].data() as Map<String, dynamic>;
              final date = notif['createdAt'] != null 
                  ? (notif['createdAt'] as Timestamp).toDate() 
                  : DateTime.now();
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getNotifColor(notif['type']).withValues(alpha: 0.1),
                  child: Icon(_getNotifIcon(notif['type']), color: _getNotifColor(notif['type'])),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(notif['subject'] ?? 'Pesan Baru', style: const TextStyle(fontWeight: FontWeight.bold))),
                    // Hanya tampilkan badge status (Pending/Sent) untuk Admin
                    if (currentUid == 'YXiA3QBe5acGWdwNabpGP2xOwLz2' && notif['status'] != null) 
                      _buildStatusBadge(notif['status']),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notif['message'] ?? ''),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(date),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isSent = status == 'sent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSent ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isSent ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: isSent ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }

  IconData _getNotifIcon(String? type) {
    switch (type) {
      case 'grade_released': return Icons.grade;
      case 'grade_updated': return Icons.update;
      case 'welcome': return Icons.celebration;
      default: return Icons.notifications;
    }
  }

  Color _getNotifColor(String? type) {
    switch (type) {
      case 'grade_released': return Colors.green;
      case 'grade_updated': return Colors.orange;
      case 'welcome': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
