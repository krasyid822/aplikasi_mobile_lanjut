import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_theme.dart';
import 'week3_admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(Week3App());
}

class Week3App extends StatelessWidget {
  const Week3App({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveMaterialApp(
      title: 'Task 3 - Firebase Storage',
      home: AdminDashboard(),
    );
  }
}
