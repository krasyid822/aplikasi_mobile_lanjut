import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'week1_login_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Center(
        child: Text(
          "Selamat datang ${user?.email}",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
