import 'package:flutter/material.dart';
import '../../logic/services/firestore_service.dart';
import '../../logic/models/course_model.dart';

class Week5ManageCoursesPage extends StatefulWidget {
  const Week5ManageCoursesPage({super.key});

  @override
  State<Week5ManageCoursesPage> createState() => _Week5ManageCoursesPageState();
}

class _Week5ManageCoursesPageState extends State<Week5ManageCoursesPage> {
  final _firestoreService = FirestoreService();

  void _showCourseDialog({Course? course}) {
    final isEditing = course != null;
    final kodeController = TextEditingController(text: course?.kodeMatkul);
    final namaController = TextEditingController(text: course?.nama);
    final sksController = TextEditingController(text: course?.sks.toString() ?? '3');
    final semesterController = TextEditingController(text: course?.semester.toString() ?? '1');
    final deskripsiController = TextEditingController(text: course?.deskripsi);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kodeController,
                decoration: const InputDecoration(labelText: 'Kode Matkul', hintText: 'Contoh: IF4001'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Matkul'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sksController,
                      decoration: const InputDecoration(labelText: 'SKS'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: semesterController,
                      decoration: const InputDecoration(labelText: 'Semester'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newCourse = Course(
                id: course?.id ?? '',
                kodeMatkul: kodeController.text.trim(),
                nama: namaController.text.trim(),
                sks: int.tryParse(sksController.text) ?? 0,
                semester: int.tryParse(semesterController.text) ?? 0,
                deskripsi: deskripsiController.text.trim(),
              );

              if (isEditing) {
                await _firestoreService.updateCourse(newCourse);
              } else {
                await _firestoreService.addCourse(newCourse);
              }

              if (mounted) {
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Mata Kuliah'),
        backgroundColor: Colors.brown.shade600,
      ),
      body: StreamBuilder<List<Course>>(
        stream: _firestoreService.getAllCoursesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const Center(child: Text('Belum ada mata kuliah.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                child: ListTile(
                  title: Text('${course.kodeMatkul} - ${course.nama}'),
                  subtitle: Text('Semester ${course.semester} | ${course.sks} SKS'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showCourseDialog(course: course),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Matkul?'),
                              content: const Text('Data yang dihapus tidak bisa dikembalikan.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _firestoreService.deleteCourse(course.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourseDialog(),
        backgroundColor: Colors.brown.shade600,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
