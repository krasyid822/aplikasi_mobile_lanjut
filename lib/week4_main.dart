import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'week4_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Week4App());
}

class Week4App extends StatelessWidget {
  const Week4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Donasi',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
