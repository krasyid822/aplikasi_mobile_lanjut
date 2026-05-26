import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Week5GlobalReportPage extends StatelessWidget {
  const Week5GlobalReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Global Akademik'),
        backgroundColor: Colors.red.shade700,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchGlobalStats(firestore),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final stats = snapshot.data ?? {};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatCard(
                context,
                title: 'Total Mahasiswa',
                value: stats['totalStudents'].toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                title: 'Total Dosen',
                value: stats['totalLecturers'].toString(),
                icon: Icons.supervisor_account,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                title: 'Total Mata Kuliah',
                value: stats['totalCourses'].toString(),
                icon: Icons.book,
                color: Colors.orange,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchGlobalStats(FirebaseFirestore firestore) async {
    // Hanya hitung mahasiswa yang benar-benar memiliki NIM dan bukan email admin
    final studentsQuery = await firestore.collection('users')
        .where('nim', isNotEqualTo: '')
        .get();
    
    // Filter tambahan secara manual untuk memastikan email master admin tidak terhitung jika ada di koleksi users
    final totalStudents = studentsQuery.docs.where((doc) {
      final data = doc.data();
      return data['email'] != 'krasyid822@gmail.com';
    }).length;

    final lecturers = await firestore.collection('admins').where('role', isEqualTo: 'dosen').get();
    final courses = await firestore.collection('courses').get();

    return {
      'totalStudents': totalStudents,
      'totalLecturers': lecturers.size,
      'totalCourses': courses.size,
    };
  }

  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
