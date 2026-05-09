import 'package:flutter/material.dart';
import 'week5_auth_service.dart';
import 'week5_firestore_service.dart';
import 'week5_grade_model.dart';
import 'week5_user_model.dart';
import 'week5_pdf_service.dart';
import 'week5_notifications_page.dart';

class Week5StudentDashboard extends StatefulWidget {
  const Week5StudentDashboard({super.key});

  @override
  State<Week5StudentDashboard> createState() => _Week5StudentDashboardState();
}

class _Week5StudentDashboardState extends State<Week5StudentDashboard> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudentUser?>(
      stream: _authService.getCurrentUserProfileStream(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final student = userSnapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard Akademik'),
            elevation: 0,
            backgroundColor: Colors.blue.shade600,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Week5NotificationsPage()),
                  );
                },
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Profil'),
                    onTap: () => _showProfileDialog(context, student),
                  ),
                  PopupMenuItem(
                    child: const Text('Logout'),
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ],
          ),
          body: [
            _buildHomePage(context, student),
            _buildGradesPage(context, student),
            _buildReportPage(context, student),
          ][_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grade),
                label: 'Nilai',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assessment),
                label: 'Laporan',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomePage(BuildContext context, StudentUser student) {
    return StreamBuilder<List<Grade>>(
      stream: _firestoreService.getGradesByUserStream(student.uid),
      builder: (context, gradesSnapshot) {
        if (gradesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final grades = gradesSnapshot.data ?? [];
        final recentGrades = grades.length > 3 ? grades.sublist(0, 3) : grades;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang,',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white70,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      student.nama,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildInfoCard(
                          title: 'NIM',
                          value: student.nim,
                          icon: Icons.badge,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoCard(
                          title: 'Semester',
                          value: student.semester,
                          icon: Icons.calendar_month,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoCard(
                          title: 'Jurusan',
                          value: student.jurusan,
                          icon: Icons.business,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoCard(
                          title: 'Prodi',
                          value: student.prodi,
                          icon: Icons.account_tree,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nilai Terbaru',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (recentGrades.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Belum ada nilai',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final grade = recentGrades[index];
                    return _buildGradeCard(context, grade);
                  },
                  childCount: recentGrades.length,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGradesPage(BuildContext context, StudentUser student) {
    return StreamBuilder<List<Grade>>(
      stream: _firestoreService.getGradesByUserStream(student.uid),
      builder: (context, gradesSnapshot) {
        if (gradesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final grades = gradesSnapshot.data ?? [];

        // Group by semester
        Map<int, List<Grade>> semesterMap = {};
        for (var grade in grades) {
          if (!semesterMap.containsKey(grade.semester)) {
            semesterMap[grade.semester] = [];
          }
          semesterMap[grade.semester]!.add(grade);
        }

        final semesters = semesterMap.keys.toList()..sort((a, b) => b.compareTo(a));

        if (grades.isEmpty) {
          return const Center(child: Text('Belum ada nilai'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: semesters.length,
          itemBuilder: (context, index) {
            final semester = semesters[index];
            final semesterGrades = semesterMap[semester]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0) const SizedBox(height: 24),
                Text(
                  'Semester $semester',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...semesterGrades
                    .map((grade) => _buildGradeCard(context, grade)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReportPage(BuildContext context, StudentUser student) {
    return StreamBuilder<List<Grade>>(
      stream: _firestoreService.getGradesByUserStream(student.uid),
      builder: (context, gradesSnapshot) {
        if (gradesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final grades = gradesSnapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Akademik',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<double>(
                future: _firestoreService.calculateGPA(student.uid, null),
                builder: (context, gpaSnapshot) {
                  return FutureBuilder<int>(
                    future: _firestoreService.getTotalSks(student.uid),
                    builder: (context, sksSnapshot) {
                      if (gpaSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          sksSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      final gpa = gpaSnapshot.data ?? 0.0;
                      final totalSks = sksSnapshot.data ?? 0;

                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'GPA Kumulatif',
                              value: gpa.toStringAsFixed(2),
                              color: Colors.blue,
                              icon: Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total SKS',
                              value: totalSks.toString(),
                              color: Colors.green,
                              icon: Icons.school,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildGPAExplanation(context),
              const SizedBox(height: 24),
              Text(
                'Daftar Nilai',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (grades.isEmpty)
                const Center(child: Text('Belum ada nilai'))
              else
                ...grades.map((grade) => _buildSimpleGradeRow(context, grade)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _generatePDFReport(context, student, grades),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Cetak KHS (PDF)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeCard(BuildContext context, Grade grade) {
    Color gradeColor = Colors.blue;
    if (grade.grade == 'A') {
      gradeColor = Colors.green;
    } else if (grade.grade == 'B') {
      gradeColor = Colors.blue;
    } else if (grade.grade == 'C') {
      gradeColor = Colors.orange;
    } else if (grade.grade == 'D' || grade.grade == 'E') {
      gradeColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gradeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                grade.grade,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.matkul,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Nilai: ${grade.nilai.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SKS: ${grade.sks}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Expanded(
      flex: fullWidth ? 1 : 1, // Simple flex handling
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title: $value'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleGradeRow(BuildContext context, Grade grade) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.matkul,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Semester ${grade.semester}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${grade.nilai.toStringAsFixed(1)} (${grade.grade})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGPAExplanation(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'Informasi Perhitungan Nilai',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
      leading: const Icon(Icons.info_outline, color: Colors.blue),
      childrenPadding: const EdgeInsets.all(16),
      expandedAlignment: Alignment.topLeft,
      children: [
        _buildInfoText('IP Semester (IPS)', 
          'Dihitung dari total (Bobot × SKS) pada semester tertentu dibagi total SKS semester tersebut.'),
        const SizedBox(height: 8),
        _buildInfoText('GPA Kumulatif (IPK)', 
          'Dihitung dari seluruh nilai yang pernah diperoleh (Semester 1 sampai sekarang) dibagi total seluruh SKS.'),
        const Divider(height: 24),
        const Text('Bobot Nilai:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildWeightBadge('A', '4.0'),
            _buildWeightBadge('B', '3.0'),
            _buildWeightBadge('C', '2.0'),
            _buildWeightBadge('D', '1.0'),
            _buildWeightBadge('E', '0.0'),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoText(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWeightBadge(String grade, String weight) {
    return Column(
      children: [
        Text(grade, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(weight, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
      ],
    );
  }

  void _showProfileDialog(BuildContext context, StudentUser student) {
    // Gunakan variabel lokal agar UI switch bisa terupdate di dalam dialog
    bool isEmailEnabled = student.emailNotificationsEnabled;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Profil Mahasiswa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileRow('Nama', student.nama),
                _profileRow('NIM', student.nim),
                _profileRow('Email', student.email),
                _profileRow('Jurusan', student.jurusan),
                _profileRow('Program Studi', student.prodi),
                _profileRow('Semester', student.semester),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifikasi Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Kirim salinan nilai ke email saya via Supabase', style: TextStyle(fontSize: 11)),
                  value: isEmailEnabled,
                  onChanged: (bool value) async {
                    // Update UI di dalam dialog secara instan
                    setDialogState(() {
                      isEmailEnabled = value;
                    });
                    
                    // Update ke database
                    final updatedStudent = student.copyWith(emailNotificationsEnabled: value);
                    await _firestoreService.updateUserProfile(updatedStudent);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _generatePDFReport(
    BuildContext context,
    StudentUser student,
    List<Grade> grades,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final pdfService = PDFService();

    if (grades.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tidak ada nilai untuk dicetak')),
      );
      return;
    }

    try {
      final gpa = await _firestoreService.calculateGPA(student.uid, null);
      final totalSks = await _firestoreService.getTotalSks(student.uid);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Mempersiapkan PDF...')),
        );
      }

      await pdfService.generateAndPrintKHS(
        student: student,
        grades: grades,
        gpa: gpa,
        totalSks: totalSks,
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await _authService.signOut();
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error logging out: $e')),
          );
        }
      }
    }
  }
}

