import 'package:flutter/material.dart';
import '../../logic/services/admin_service.dart';
import '../../logic/services/firestore_service.dart';
import '../../logic/models/course_model.dart';

class Week5ManageLecturersPage extends StatelessWidget {
  const Week5ManageLecturersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Dosen'),
        backgroundColor: Colors.indigo.shade600,
      ),
      body: StreamBuilder<List<AdminUser>>(
        stream: adminService.getAllLecturersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final lecturers = snapshot.data ?? [];

          if (lecturers.isEmpty) {
            return const Center(child: Text('Tidak ada dosen terdaftar'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lecturers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lecturer = lecturers[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(lecturer.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lecturer.email),
                      const SizedBox(height: 4),
                      Text('Matkul: ${lecturer.matkulList.join(", ")}', 
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showEditLecturerDialog(context, lecturer, adminService),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, lecturer, adminService),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditLecturerDialog(BuildContext context, AdminUser lecturer, AdminService service) {
    final namaController = TextEditingController(text: lecturer.nama);
    final firestoreService = FirestoreService();
    List<String> selectedMatkul = List.from(lecturer.matkulList);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Data Dosen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                const SizedBox(height: 16),
                const Text('Pilih Mata Kuliah yang Diampu:', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                StreamBuilder<List<Course>>(
                  stream: firestoreService.getAllCoursesStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final allCourses = snapshot.data!;
                    return Column(
                      children: allCourses.map((course) {
                        final isSelected = selectedMatkul.contains(course.nama);
                        return CheckboxListTile(
                          title: Text('${course.kodeMatkul} - ${course.nama}'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedMatkul.add(course.nama);
                              } else {
                                selectedMatkul.remove(course.nama);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final updated = AdminUser(
                  uid: lecturer.uid,
                  nama: namaController.text.trim(),
                  email: lecturer.email,
                  role: lecturer.role,
                  matkulList: selectedMatkul,
                  createdAt: lecturer.createdAt,
                );

                await service.updateLecturer(updated);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminUser lecturer, AdminService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Dosen'),
        content: Text('Anda yakin ingin menghapus ${lecturer.nama}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await service.deleteLecturer(lecturer.uid);
              if (context.mounted) Navigator.pop(context);
            }, 
            child: const Text('Hapus', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}
