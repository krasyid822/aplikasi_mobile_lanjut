import 'package:flutter/material.dart';
import '../../logic/services/firestore_service.dart';
import '../../logic/models/user_model.dart';
import 'add_grade_page.dart';
import '../../logic/services/admin_service.dart';
import '../../logic/models/major_model.dart';

class Week5ManageStudentsPage extends StatefulWidget {
  const Week5ManageStudentsPage({super.key});

  @override
  State<Week5ManageStudentsPage> createState() => _Week5ManageStudentsPageState();
}

class _Week5ManageStudentsPageState extends State<Week5ManageStudentsPage> {
  final _firestoreService = FirestoreService();
  final _adminService = AdminService();
  String _searchQuery = '';
  final _searchController = TextEditingController();

  void _showEditStudentDialog(StudentUser student) {
    final namaController = TextEditingController(text: student.nama);
    final nimController = TextEditingController(text: student.nim);
    final semesterController = TextEditingController(text: student.semester);
    
    String? selectedJurusan = student.jurusan.isNotEmpty ? student.jurusan : null;
    String? selectedProdi = student.prodi.isNotEmpty ? student.prodi : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Data Mahasiswa'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama')),
                  TextField(controller: nimController, decoration: const InputDecoration(labelText: 'NIM')),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Major>>(
                    stream: _firestoreService.getAllMajorsStream(),
                    builder: (context, snapshot) {
                      final majors = snapshot.data ?? [];
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedJurusan,
                            hint: const Text('Pilih Jurusan'),
                            items: majors.map((m) => DropdownMenuItem(
                              value: m.name, 
                              child: Text(m.name) // Tampilan penuh saat menu terbuka
                            )).toList(),
                            selectedItemBuilder: (context) {
                              return majors.map((m) => Text(
                                m.name, 
                                overflow: TextOverflow.ellipsis, // Potong saat tertutup
                              )).toList();
                            },
                            onChanged: (val) {
                              setDialogState(() {
                                selectedJurusan = val;
                                selectedProdi = null; // Reset prodi if major changes
                              });
                            },
                            decoration: const InputDecoration(labelText: 'Jurusan'),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedProdi,
                            hint: const Text('Pilih Program Studi'),
                            items: selectedJurusan == null 
                              ? [] 
                              : majors
                                  .firstWhere((m) => m.name == selectedJurusan)
                                  .prodiList
                                  .map((p) => DropdownMenuItem(
                                    value: p, 
                                    child: Text(p) // Tampilan penuh saat menu terbuka
                                  ))
                                  .toList(),
                            selectedItemBuilder: (context) {
                              if (selectedJurusan == null) return [];
                              return majors
                                  .firstWhere((m) => m.name == selectedJurusan)
                                  .prodiList
                                  .map((p) => Text(
                                    p, 
                                    overflow: TextOverflow.ellipsis, // Potong saat tertutup
                                  )).toList();
                            },
                            onChanged: (val) => setDialogState(() => selectedProdi = val),
                            decoration: const InputDecoration(labelText: 'Program Studi'),
                          ),
                        ],
                      );
                    }
                  ),
                  TextField(controller: semesterController, decoration: const InputDecoration(labelText: 'Semester')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final updatedStudent = student.copyWith(
                  nama: namaController.text.trim(),
                  nim: nimController.text.trim(),
                  jurusan: selectedJurusan ?? '',
                  prodi: selectedProdi ?? '',
                  semester: semesterController.text.trim(),
                );
                await _firestoreService.updateUserProfile(updatedStudent);
                if (mounted) {
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Mahasiswa'),
        backgroundColor: Colors.green.shade600,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari NIM, Nama, atau Jurusan...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<AdminUser?>(
        stream: _adminService.getAdminProfileStream(_adminService.currentUser?.uid ?? ''),
        builder: (context, adminSnapshot) {
          // Detect role with master admin fail-safe
          String currentUserRole = adminSnapshot.data?.role ?? 'dosen';
          final currentUid = _adminService.currentUser?.uid;
          
          if (currentUid == 'YXiA3QBe5acGWdwNabpGP2xOwLz2') {
            currentUserRole = 'admin';
          }

          return StreamBuilder<List<StudentUser>>(
            stream: _firestoreService.getAllStudentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filter ketat berdasarkan pencarian dan role
              final allUsers = snapshot.data ?? [];
              final students = allUsers.where((u) {
                final matchRole = u.uid != currentUid && 
                                u.nim.isNotEmpty && 
                                u.email != 'krasyid822@gmail.com';
                
                if (!matchRole) return false;

                final matchQuery = u.nama.toLowerCase().contains(_searchQuery) ||
                                  u.nim.toLowerCase().contains(_searchQuery) ||
                                  u.jurusan.toLowerCase().contains(_searchQuery) ||
                                  u.prodi.toLowerCase().contains(_searchQuery);
                
                return matchQuery;
              }).toList();

              if (students.isEmpty) {
                return const Center(child: Text('Tidak ada mahasiswa terdaftar'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          student.nama.isNotEmpty ? student.nama[0] : '?',
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                      ),
                      title: Text(
                        student.nama,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NIM: ${student.nim}'),
                          Text('Jurusan: ${student.jurusan}'),
                          Text('Prodi: ${student.prodi}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentUserRole == 'dosen')
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                              tooltip: 'Tambah Nilai',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Week5AddGradePage(
                                      studentUid: student.uid,
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (currentUserRole == 'admin') ...[
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              tooltip: 'Edit Data',
                              onPressed: () => _showEditStudentDialog(student),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Hapus Mahasiswa',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Hapus Mahasiswa?'),
                                    content: Text('Seluruh data nilai dan KRS ${student.nama} akan ikut terhapus.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _firestoreService.deleteStudent(student.uid);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
      ),
    );
  }
}
