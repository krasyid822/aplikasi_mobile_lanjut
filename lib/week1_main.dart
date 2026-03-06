import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'week1_login_page.dart';
import 'week1_dashboard_page.dart';
import 'week1_firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Week1App());
}

class Week1App extends StatelessWidget {
  const Week1App({super.key});
  @override
  Widget build(BuildContext context) {
    return AdaptiveMaterialApp(
      title: 'Task 1 - Firebase Auth',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return DashboardPage();
          }
          return LoginPage();
        },
      ),
    );
  }
}
