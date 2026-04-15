import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'week4_auth_service.dart';
import 'week4_register_screen.dart';
import 'week4_home_screen.dart';
import 'week4_messaging_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _keepLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadKeepLoggedIn();
  }

  Future<void> _loadKeepLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final keep = prefs.getBool('keepLoggedIn') ?? false;
    if (!mounted) return;
    setState(() => _keepLoggedIn = keep);
    if (keep) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      }
    }
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await AuthService().login(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('keepLoggedIn', _keepLoggedIn);
      if (user != null) {
        if (_keepLoggedIn) {
          await prefs.setString('lastUserId', user.uid);
        } else {
          await prefs.remove('lastUserId');
        }
        // Save FCM token and subscribe to campaign topic
        await MessagingService.saveTokenToFirestore(user.uid);
        await MessagingService.subscribeToCampaignsTopic();
      }
      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login gagal')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _login, child: const Text('Login')),
            CheckboxListTile(
              value: _keepLoggedIn,
              onChanged: (v) => setState(() => _keepLoggedIn = v ?? false),
              title: const Text('Tetap masuk'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RegisterScreen()),
              ),
              child: const Text('Buat akun baru'),
            ),
          ],
        ),
      ),
    );
  }
}
