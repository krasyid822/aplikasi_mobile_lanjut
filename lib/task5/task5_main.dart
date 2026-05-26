import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../task1/logic/services/firebase_options.dart';
import '../app_theme.dart';
import 'logic/services/auth_service.dart';
import 'logic/services/admin_service.dart';
import 'ui/screens/login_page.dart';
import 'ui/screens/admin_login_page.dart';
import 'ui/screens/student_dashboard.dart';
import 'ui/screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Try to initialize Firebase if available
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase initialization might not be needed for some configurations
    debugPrint('Firebase initialization skipped or failed: $e');
  }

  runApp(const Week5App());
}

class Week5App extends StatelessWidget {
  const Week5App({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveMaterialApp(
      title: 'Sistem Informasi Akademik Mahasiswa',
      home: Week5RoleLanding(),
    );
  }
}

class Week5RoleLanding extends StatelessWidget {
  const Week5RoleLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Kembali ke HomeLauncherPage di uas_main.dart
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                Text(
                  'Sistem Informasi Akademik',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih tipe pengguna Anda',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 48),
                _buildRoleButton(
                  context,
                  icon: Icons.person,
                  title: 'Mahasiswa',
                  description: 'Lihat nilai dan laporan akademik',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Week5StudentAuthWrapper(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildRoleButton(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'Admin/Dosen',
                  description: 'Input nilai dan kelola akademik',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Week5AdminAuthWrapper(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 40),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class Week5StudentAuthWrapper extends StatefulWidget {
  const Week5StudentAuthWrapper({super.key});

  @override
  State<Week5StudentAuthWrapper> createState() =>
      _Week5StudentAuthWrapperState();
}

class _Week5StudentAuthWrapperState extends State<Week5StudentAuthWrapper> {
  late final AuthService _authService;
  late final Stream<dynamic> _authStream;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _authStream = _authService.authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const Week5StudentDashboard();
        }

        return Week5LoginPage(
          onLoginSuccess: () {
            setState(() {});
          },
        );
      },
    );
  }
}

class Week5AdminAuthWrapper extends StatefulWidget {
  const Week5AdminAuthWrapper({super.key});

  @override
  State<Week5AdminAuthWrapper> createState() => _Week5AdminAuthWrapperState();
}

class _Week5AdminAuthWrapperState extends State<Week5AdminAuthWrapper> {
  late final AdminService _adminService;
  late final Stream<dynamic> _adminAuthStream;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService();
    _adminAuthStream = _adminService.authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _adminAuthStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data;
          final uid = user.uid;

          // Fail-safe untuk Master Admin UID
          if (uid == 'YXiA3QBe5acGWdwNabpGP2xOwLz2') {
            return const Week5AdminDashboard();
          }

          return FutureBuilder(
            future: _adminService.getAdminProfile(uid),
            builder: (context, adminDocSnapshot) {
              if (adminDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (adminDocSnapshot.hasData && adminDocSnapshot.data != null) {
                return const Week5AdminDashboard();
              }
              
              return Week5AdminLoginPage(
                onLoginSuccess: () => setState(() {}),
                errorMessage: 'Akun Anda tidak terdaftar sebagai Admin/Dosen.',
              );
            },
          );
        }

        return Week5AdminLoginPage(
          onLoginSuccess: () {
            setState(() {});
          },
        );
      },
    );
  }
}


