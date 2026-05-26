import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../task1/logic/services/firebase_options.dart';
import '../task1/ui/screens/login_page.dart';
import 'ui/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Week2App());
}

class Week2App extends StatelessWidget {
  const Week2App({super.key});
  @override
  Widget build(BuildContext context) {
    return AdaptiveMaterialApp(
      title: 'Task 2 - CRUD Firestore',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return Week2DashboardScreen();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
