import 'package:flutter/material.dart';
import 'week5_firestore_service.dart';
import 'week5_grade_model.dart';
import 'week5_course_model.dart';
import 'week5_user_model.dart';
import 'week5_admin_service.dart';
import 'week5_email_service.dart';

class Week5AddGradePage extends StatefulWidget {
  final String? studentUid;
  const Week5AddGradePage({super.key, this.studentUid});

  @override
  State<Week5AddGradePage> createState() => _Week5AddGradePageState();
}

class _Week5AddGradePageState extends State<Week5AddGradePage> {
  final _firestoreService = FirestoreService();
  final _adminService = AdminService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  StudentUser? _selectedStudent;
  final _nilaiController = TextEditingController();
  final _searchStudentController = TextEditingController();
  
  Course? _selectedCourse;
  List<Course> _filteredCourses = [];
  List<StudentUser> _searchedStudents = [];
  bool _isSearchingStudent = false;
  Grade? _existingGrade;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load all courses
    final courses = await _firestoreService.getAllCoursesStream().first;
    // Load current lecturer profile to filter courses
    final adminProfile = await _adminService.getAdminProfile(_adminService.currentUser?.uid ?? '');
    
    if (mounted) {
      setState(() {
        if (adminProfile?.role == 'admin') {
          _filteredCourses = courses;
        } else {
          _filteredCourses = courses.where((c) => 
            adminProfile?.matkulList.contains(c.nama) ?? false
          ).toList();
        }
      });
    }

    if (widget.studentUid != null) {
      final student = await _firestoreService.getUserProfile(widget.studentUid!);
      if (mounted) {
        setState(() {
          _selectedStudent = student;
        });
      }
    }
  }

  Future<void> _searchStudents(String query) async {
    if (query.isEmpty) {
      setState(() => _searchedStudents = []);
      return;
    }

    setState(() => _isSearchingStudent = true);
    final all = await _firestoreService.getAllStudents();
    final q = query.toLowerCase();
    
    setState(() {
      _searchedStudents = all.where((s) => 
        s.nama.toLowerCase().contains(q) || 
        s.nim.toLowerCase().contains(q) ||
        s.jurusan.toLowerCase().contains(q) ||
        s.prodi.toLowerCase().contains(q)
      ).toList();
      _isSearchingStudent = false;
    });
  }

  @override
  void dispose() {
    _nilaiController.dispose();
    _searchStudentController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingGrade() async {
    if (_selectedStudent == null || _selectedCourse == null) return;
    
    setState(() => _isLoading = true);
    try {
      final grade = await _firestoreService.getGradeByDetail(
        _selectedStudent!.uid, 
        _selectedCourse!.nama, 
      );
      setState(() {
        _existingGrade = grade;
        if (grade != null) {
          _nilaiController.text = grade.nilai.toString();
        } else {
          _nilaiController.clear();
        }
      });
    } catch (e) {
      debugPrint('Error checking existing grade: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGrade() async {
    if (!_formKey.currentState!.validate() || _selectedCourse == null || _selectedStudent == null) {
      String error = '';
      if (_selectedStudent == null) {
        error = 'Pilih mahasiswa terlebih dahulu';
      } else if (_selectedCourse == null) {
        error = 'Pilih mata kuliah';
      }
      
      if (error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nilai = double.parse(_nilaiController.text);
      final grade = Grade.getGradeFromValue(nilai);

      final newGrade = Grade(
        id: '', // ID akan ditentukan oleh FirestoreService
        uid: _selectedStudent!.uid,
        namaMahasiswa: _selectedStudent!.nama,
        matkul: _selectedCourse!.nama,
        kodeMatkul: _selectedCourse!.kodeMatkul,
        nilai: nilai,
        grade: grade,
        sks: _selectedCourse!.sks,
        semester: _selectedCourse!.semester,
        dosenUid: _adminService.currentUser?.uid ?? '',
        tanggalInput: DateTime.now(),
      );

      await _firestoreService.addGrade(newGrade);
      
      // Log Aktivitas Dosen
      final dosenProfile = await _adminService.getAdminProfile(_adminService.currentUser?.uid ?? '');
      await _firestoreService.addAuditLog(
        action: _existingGrade != null ? 'Update Nilai' : 'Input Nilai',
        details: 'Dosen ${dosenProfile?.nama} ${_existingGrade != null ? 'mengubah' : 'menginput'} nilai ${_selectedCourse!.nama} untuk ${_selectedStudent!.nama} ($nilai)',
        dosenUid: dosenProfile?.uid ?? 'Unknown',
        dosenNama: dosenProfile?.nama ?? 'Dosen',
      );
      
      // Trigger Notification (In-App)
      final notifId = await _firestoreService.sendNotification(
        uid: _selectedStudent!.uid,
        email: _selectedStudent!.email,
        subject: 'Nilai Baru Diumumkan: ${_selectedCourse!.nama}',
        message: 'Dosen telah menginput nilai untuk mata kuliah ${_selectedCourse!.nama}. Silakan cek aplikasi untuk detailnya.',
        type: _existingGrade != null ? 'grade_updated' : 'grade_released',
        extraData: {
          'matkul': _selectedCourse!.nama,
          'grade': grade,
          'nilai': nilai,
        }
      );

      // Trigger Email via Supabase (Optional based on student preference)
      if (_selectedStudent!.emailNotificationsEnabled) {
        await EmailService.sendEmailViaSupabase(
          toEmail: _selectedStudent!.email,
          subject: 'Laporan Nilai: ${_selectedCourse!.nama}',
          message: 'Halo ${_selectedStudent!.nama}, nilai Anda untuk mata kuliah ${_selectedCourse!.nama} adalah $grade ($nilai).',
        );
      }
      
      // Jika proses email/antrean selesai, update status di Firestore jadi 'sent'
      if (notifId != null) {
        await _firestoreService.updateNotificationStatus(notifId, 'sent');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existingGrade != null 
              ? 'Nilai berhasil diperbarui (Overwritten)' 
              : 'Nilai berhasil ditambahkan'),
            backgroundColor: _existingGrade != null ? Colors.orange : Colors.green,
          ),
        );
      }
      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _nilaiController.clear();
    _searchStudentController.clear();
    setState(() {
      _selectedCourse = null;
      _existingGrade = null;
      if (widget.studentUid == null) _selectedStudent = null;
      _searchedStudents = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Nilai'),
        backgroundColor: Colors.orange.shade600,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cari Mahasiswa',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (_selectedStudent == null) ...[
                TextFormField(
                  controller: _searchStudentController,
                  onChanged: _searchStudents,
                  decoration: InputDecoration(
                    labelText: 'Cari Nama, NIM, atau Jurusan...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                if (_isSearchingStudent)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_searchedStudents.isNotEmpty)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _searchedStudents.length,
                      itemBuilder: (context, index) {
                        final s = _searchedStudents[index];
                        return ListTile(
                          title: Text(s.nama),
                          subtitle: Text('${s.nim} | ${s.jurusan} - ${s.prodi}'),
                          onTap: () {
                            setState(() {
                              _selectedStudent = s;
                              _searchedStudents = [];
                              _searchStudentController.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
              ] else ...[
                Card(
                  color: Colors.blue.shade50,
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(_selectedStudent!.nama),
                    subtitle: Text('${_selectedStudent!.nim} | ${_selectedStudent!.jurusan} - ${_selectedStudent!.prodi}'),
                    trailing: widget.studentUid == null 
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _selectedStudent = null),
                        )
                      : null,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Pilih Mata Kuliah',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Course>(
                hint: const Text('Pilih Mata Kuliah'),
                items: _filteredCourses.map((course) {
                  return DropdownMenuItem(
                    value: course,
                    child: Text('${course.kodeMatkul} - ${course.nama}'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCourse = val;
                  });
                  _checkExistingGrade();
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                validator: (value) => value == null ? 'Pilih mata kuliah' : null,
              ),
              if (_selectedCourse != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem('SKS', _selectedCourse!.sks.toString()),
                      _buildInfoItem('Semester', _selectedCourse!.semester.toString()),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Simpan Nilai',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (_existingGrade != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'PERINGATAN: Mahasiswa ini sudah memiliki nilai untuk mata kuliah tersebut. Menyimpan akan menimpa (overwrite) data lama.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _nilaiController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nilai (0-100)',
                  hintText: 'Contoh: 85',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Nilai tidak boleh kosong';
                  }
                  final nilai = double.tryParse(value!);
                  if (nilai == null || nilai < 0 || nilai > 100) {
                    return 'Nilai harus antara 0-100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitGrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Simpan Nilai',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
