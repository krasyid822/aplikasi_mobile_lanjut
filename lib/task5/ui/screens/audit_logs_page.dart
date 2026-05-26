import 'package:flutter/material.dart';
import '../../logic/services/firestore_service.dart';
import 'package:intl/intl.dart';

class Week5AuditLogsPage extends StatelessWidget {
  const Week5AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas Dosen'),
        backgroundColor: Colors.blueGrey.shade800,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.getAuditLogsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(child: Text('Belum ada riwayat aktivitas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final date = log['timestamp'] != null 
                  ? (log['timestamp'] as dynamic).toDate() 
                  : DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getActionColor(log['action']),
                    child: Icon(_getActionIcon(log['action']), color: Colors.white, size: 20),
                  ),
                  title: Text(log['action'] ?? 'Aksi', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(log['details'] ?? ''),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Oleh: ${log['dosenNama']}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                          Text(DateFormat('dd/MM HH:mm').format(date), style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getActionIcon(String? action) {
    if (action == 'Update Nilai') return Icons.edit_note;
    if (action == 'Input Nilai') return Icons.add_chart;
    return Icons.history;
  }

  Color _getActionColor(String? action) {
    if (action == 'Update Nilai') return Colors.orange;
    if (action == 'Input Nilai') return Colors.blue;
    return Colors.grey;
  }
}
