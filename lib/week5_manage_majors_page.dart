import 'package:flutter/material.dart';
import 'week5_firestore_service.dart';
import 'week5_major_model.dart';

class Week5ManageMajorsPage extends StatefulWidget {
  const Week5ManageMajorsPage({super.key});

  @override
  State<Week5ManageMajorsPage> createState() => _Week5ManageMajorsPageState();
}

class _Week5ManageMajorsPageState extends State<Week5ManageMajorsPage> {
  final _firestoreService = FirestoreService();

  void _showMajorDialog({Major? major}) {
    final isEditing = major != null;
    final nameController = TextEditingController(text: major?.name);
    final prodiController = TextEditingController(text: major?.prodiList.join(', '));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Jurusan' : 'Tambah Jurusan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Jurusan', hintText: 'Contoh: Teknik Elektro'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: prodiController,
              decoration: const InputDecoration(
                labelText: 'Program Studi (pisahkan koma)',
                hintText: 'Contoh: D3 Teknik Listrik, D4 Sistem Kelistrikan',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final prodiList = prodiController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              final newMajor = Major(
                id: major?.id ?? '',
                name: nameController.text.trim(),
                prodiList: prodiList,
              );

              if (isEditing) {
                await _firestoreService.updateMajor(newMajor);
              } else {
                await _firestoreService.addMajor(newMajor);
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
        title: const Text('Kelola Jurusan & Prodi'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: StreamBuilder<List<Major>>(
        stream: _firestoreService.getAllMajorsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final majors = snapshot.data ?? [];
          if (majors.isEmpty) {
            return const Center(child: Text('Belum ada data jurusan.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: majors.length,
            itemBuilder: (context, index) {
              final major = majors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(major.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${major.prodiList.length} Program Studi'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _showMajorDialog(major: major),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Jurusan?'),
                              content: const Text('Seluruh data program studi di bawahnya akan terhapus.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _firestoreService.deleteMajor(major.id);
                          }
                        },
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: major.prodiList.map((prodi) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_right, size: 16),
                              const SizedBox(width: 8),
                              Text(prodi),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMajorDialog(),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
