import 'package:flutter/material.dart';
import '../../logic/services/admin_service.dart';
import 'add_grade_page.dart';
import 'manage_students_page.dart';
import 'manage_lecturers_page.dart';
import 'manage_courses_page.dart';
import 'manage_majors_page.dart';
import 'grade_recap_page.dart';
import 'global_report_page.dart';
import 'audit_logs_page.dart';

class Week5AdminDashboard extends StatefulWidget {
  const Week5AdminDashboard({super.key});

  @override
  State<Week5AdminDashboard> createState() => _Week5AdminDashboardState();
}

class _Week5AdminDashboardState extends State<Week5AdminDashboard> {
  final _adminService = AdminService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminUser?>(
      stream: _adminService.currentUser != null
          ? _adminService.getAdminProfileStream(_adminService.currentUser!.uid)
          : Stream.value(null),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        AdminUser? admin = adminSnapshot.data;
        final currentUid = _adminService.currentUser?.uid;

        // Fail-safe jika data stream belum sampai tapi kita tahu ini master admin
        if (admin == null && currentUid == 'YXiA3QBe5acGWdwNabpGP2xOwLz2') {
          admin = AdminUser(
            uid: 'YXiA3QBe5acGWdwNabpGP2xOwLz2',
            nama: 'Rasyid Kurniawan (Admin)',
            email: 'krasyid822@gmail.com',
            role: 'admin',
            createdAt: DateTime.now(),
          );
        }

        // Tentukan role secara eksplisit
        final String effectiveRole = (currentUid == 'YXiA3QBe5acGWdwNabpGP2xOwLz2') 
            ? 'admin' 
            : (admin?.role ?? 'dosen');

        if (admin == null && currentUid != 'YXiA3QBe5acGWdwNabpGP2xOwLz2') {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Akses Ditolak: Profil Admin/Dosen tidak ditemukan.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _handleLogout(context),
                    child: const Text('Keluar & Login Ulang'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            elevation: 0,
            backgroundColor: Colors.orange.shade600,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
          body: [
            _buildDashboardPage(context, admin, effectiveRole),
            _buildManagePage(context, admin),
          ][_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Manajemen',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardPage(BuildContext context, AdminUser? admin, String effectiveRole) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang,',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    admin?.nama ?? 'Admin',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    admin?.role == 'admin' ? 'Administrator' : 'Dosen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Actions Section
          Text(
            admin?.role == 'admin' ? 'Manajemen Sistem (Admin)' : 'Layanan Akademik (Dosen)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: effectiveRole == 'admin'
              ? [ // MENU KHUSUS ADMIN
                  _buildActionCard(
                    context,
                    icon: Icons.people_alt,
                    title: 'Kelola Dosen',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Week5ManageLecturersPage(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.school,
                    title: 'Kelola Mahasiswa',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Week5ManageStudentsPage(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.account_tree,
                    title: 'Jurusan & Prodi',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Week5ManageMajorsPage(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.menu_book,
                    title: 'Data Matkul',
                    color: Colors.brown,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Week5ManageCoursesPage(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.summarize,
                    title: 'Laporan Global',
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Week5GlobalReportPage(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.history,
                    title: 'Aktivitas Dosen',
                    color: Colors.blueGrey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Week5AuditLogsPage(),
                        ),
                      );
                    },
                  ),
                ]
              : [ // MENU KHUSUS DOSEN
                  _buildActionCard(
                    context,
                    icon: Icons.grade,
                    title: 'Input Nilai',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Week5AddGradePage(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.analytics,
                    title: 'Rekap Nilai',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Week5GradeRecapPage(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.group,
                    title: 'Daftar Mahasiswa',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Week5ManageStudentsPage(),
                        ),
                      );
                    },
                  ),
                ],
          ),
          const SizedBox(height: 24),

          // System Info
          Text(
            'Informasi Sistem',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Role', admin?.role ?? '-'),
                  const Divider(),
                  _buildInfoRow('Email', admin?.email ?? '-'),
                  const Divider(),
                  _buildInfoRow(
                    'Status',
                    'Online',
                    statusColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagePage(BuildContext context, AdminUser? admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil Saya',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(admin?.nama ?? '-'),
                    subtitle: Text(admin?.email ?? '-'),
                  ),
                  const Divider(),
                  _buildInfoRow('UID', admin?.uid ?? '-'),
                  _buildInfoRow('Dibuat Pada', admin?.createdAt.toString().split(' ')[0] ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (admin?.role == 'dosen') ...[
            Text(
              'Mata Kuliah Diampu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: admin?.matkulList.length ?? 0,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.book, color: Colors.orange),
                    title: Text(admin!.matkulList[index]),
                  );
                },
              ),
            ),
          ],
          if (admin?.role == 'admin') ...[
            Text(
              'Status Sistem',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.blue),
                    title: const Text('Status Server'),
                    trailing: const Text('Normal', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.update, color: Colors.orange),
                    title: const Text('Versi Aplikasi'),
                    trailing: const Text('v1.0.5'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Remove the duplicate logout button here
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          if (statusColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(value),
        ],
      ),
    );
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
        await _adminService.signOut();
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
