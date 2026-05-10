import 'package:flutter/material.dart';
import 'week5_auth_service.dart';
import 'week5_firestore_service.dart';
import 'week5_major_model.dart';

class Week5LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const Week5LoginPage({
    required this.onLoginSuccess,
    super.key,
  });

  @override
  State<Week5LoginPage> createState() => _Week5LoginPageState();
}

class _Week5LoginPageState extends State<Week5LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false;
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  
  final _firestoreService = FirestoreService();
  String? _selectedJurusan;
  String? _selectedProdi;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        if (_selectedJurusan == null || _selectedProdi == null) {
          throw Exception('Pilih Jurusan dan Program Studi');
        }
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nama: _nameController.text.trim(),
          nim: _nimController.text.trim(),
          jurusan: _selectedJurusan!,
          prodi: _selectedProdi!,
        );
      } else {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Kembali ke halaman pemilihan peran (Role Landing)
            Navigator.of(context).pop();
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
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.school,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sistem Informasi Akademik',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mahasiswa',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!value!.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outlined,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(
                              () => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Password tidak boleh kosong';
                        }
                        if (!_isSignUp && value!.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sign Up Fields
                    if (_isSignUp) ...[
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nama Lengkap',
                        icon: Icons.person_outlined,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nimController,
                        label: 'NIM',
                        icon: Icons.badge_outlined,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'NIM tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<Major>>(
                        stream: _firestoreService.getAllMajorsStream(),
                        builder: (context, snapshot) {
                          final majors = snapshot.data ?? [];
                          return Column(
                            children: [
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedJurusan,
                                hint: const Text('Pilih Jurusan', style: TextStyle(color: Colors.white70)),
                                dropdownColor: Colors.blue.shade800,
                                items: majors.map((m) => DropdownMenuItem(
                                  value: m.name, 
                                  child: Text(m.name, style: const TextStyle(color: Colors.white)),
                                )).toList(),
                                selectedItemBuilder: (context) {
                                  return majors.map((m) => Text(
                                    m.name, 
                                    style: const TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  )).toList();
                                },
                                onChanged: (val) {
                                  setState(() {
                                    _selectedJurusan = val;
                                    _selectedProdi = null;
                                  });
                                },
                                decoration: _dropdownDecoration('Jurusan', Icons.business_outlined),
                                validator: (value) => value == null ? 'Pilih Jurusan' : null,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedProdi,
                                hint: const Text('Pilih Program Studi', style: TextStyle(color: Colors.white70)),
                                dropdownColor: Colors.blue.shade800,
                                items: _selectedJurusan == null 
                                  ? [] 
                                  : majors
                                      .firstWhere((m) => m.name == _selectedJurusan)
                                      .prodiList
                                      .map((p) => DropdownMenuItem(
                                        value: p, 
                                        child: Text(p, style: const TextStyle(color: Colors.white)),
                                      ))
                                      .toList(),
                                selectedItemBuilder: (context) {
                                  if (_selectedJurusan == null) return [];
                                  return majors
                                      .firstWhere((m) => m.name == _selectedJurusan)
                                      .prodiList
                                      .map((p) => Text(
                                        p, 
                                        style: const TextStyle(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      )).toList();
                                },
                                onChanged: (val) => setState(() => _selectedProdi = val),
                                decoration: _dropdownDecoration('Program Studi', Icons.account_tree_outlined),
                                validator: (value) => value == null ? 'Pilih Program Studi' : null,
                              ),
                            ],
                          );
                        }
                      ),
                      const SizedBox(height: 24),
                    ] else
                      const SizedBox(height: 8),

                    // Login/Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Daftar' : 'Masuk',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle Sign Up/Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp
                              ? 'Sudah punya akun? '
                              : 'Belum punya akun? ',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => setState(
                                  () => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp ? 'Masuk' : 'Daftar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white70),
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
    );
  }
}

