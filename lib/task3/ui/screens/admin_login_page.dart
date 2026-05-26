import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../task1/task1_main.dart';
import '../../logic/services/admin_role_service.dart';

class Week3AdminLoginPage extends StatefulWidget {
  const Week3AdminLoginPage({
    super.key,
    this.roleService = const Week3AdminRoleService(),
  });

  final Week3AdminRoleService roleService;

  @override
  State<Week3AdminLoginPage> createState() => _Week3AdminLoginPageState();
}

class _Week3AdminLoginPageState extends State<Week3AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openWeek1AuthFlow() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const Week1App()));
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        await widget.roleService.bootstrapFirstAdminIfMatched(
          uid: user.uid,
          email: user.email,
        );
      }

      final isAdmin = user != null
          ? await widget.roleService.isAdmin(user.uid)
          : false;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAdmin
                ? 'Login berhasil. Anda masuk sebagai admin.'
                : 'Login berhasil. Anda masuk sebagai pelanggan.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login admin gagal')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Login Akun',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masuk dengan akun Firebase. Akun admin akan membuka panel admin, akun biasa akan masuk ke profil pelanggan.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email wajib diisi';
                        if (!email.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) {
                        final password = value ?? '';
                        if (password.isEmpty) return 'Password wajib diisi';
                        if (password.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _login,
                      child: Text(_isSubmitting ? 'Memproses...' : 'Masuk'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isSubmitting ? null : _openWeek1AuthFlow,
                      child: const Text('Belum punya akun atau lupa'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
