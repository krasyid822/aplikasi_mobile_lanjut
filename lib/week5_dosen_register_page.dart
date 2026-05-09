import 'package:flutter/material.dart';
import 'week5_admin_service.dart';
import 'week5_firestore_service.dart';
import 'week5_course_model.dart';

class Week5DosenRegisterPage extends StatefulWidget {
  const Week5DosenRegisterPage({super.key});

  @override
  State<Week5DosenRegisterPage> createState() => _Week5DosenRegisterPageState();
}

class _Week5DosenRegisterPageState extends State<Week5DosenRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _firestoreService = FirestoreService();

  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final List<String> _selectedMatkul = [];
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMatkul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu mata kuliah')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _adminService.registerDosen(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nama: _namaController.text.trim(),
        matkul: _selectedMatkul,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran Dosen Berhasil! Silakan Login.')),
        );
        Navigator.pop(context);
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
        title: const Text('Registrasi Dosen'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.orange.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat Akun Dosen',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              _buildField(
                controller: _namaController,
                label: 'Nama Lengkap',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _emailController,
                label: 'Email Institusi',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Pilih Mata Kuliah yang Diampu:', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              StreamBuilder<List<Course>>(
                stream: _firestoreService.getAllCoursesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  final courses = snapshot.data ?? [];
                  if (courses.isEmpty) return const Text('Belum ada data mata kuliah.');
                  
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: courses.map((course) {
                        return CheckboxListTile(
                          title: Text('${course.kodeMatkul} - ${course.nama}'),
                          value: _selectedMatkul.contains(course.nama),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedMatkul.add(course.nama);
                              } else {
                                _selectedMatkul.remove(course.nama);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Daftar Sebagai Dosen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => (value?.isEmpty ?? true) ? 'Tidak boleh kosong' : null,
    );
  }
}
