import 'package:flutter/material.dart';

import '../../logic/services/firestore_service.dart';
import '../../logic/models/mahasiswa_model.dart';

class Week2DashboardScreen extends StatefulWidget {
  const Week2DashboardScreen({super.key});

  @override
  State<Week2DashboardScreen> createState() => _Week2DashboardScreenState();
}

class _Week2DashboardScreenState extends State<Week2DashboardScreen> {
  final FirestoreService _service = FirestoreService();
  Key _streamKey = UniqueKey();

  Future<void> _confirmDelete(BuildContext context, Mahasiswa mhs) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus data?'),
          content: Text('Yakin menghapus ${mhs.nama}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _service.deleteMahasiswa(mhs.id);
    }
  }

  Future<void> _showFormDialog(
    BuildContext context, {
    Mahasiswa? mahasiswa,
  }) async {
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: mahasiswa?.nama ?? '');
    final nimController = TextEditingController(text: mahasiswa?.nim ?? '');
    final jurusanController = TextEditingController(
      text: mahasiswa?.jurusan ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            mahasiswa == null ? 'Tambah Mahasiswa' : 'Ubah Mahasiswa',
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Nama wajib diisi' : null,
                ),
                TextFormField(
                  controller: nimController,
                  decoration: const InputDecoration(labelText: 'NIM'),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'NIM wajib diisi' : null,
                ),
                TextFormField(
                  controller: jurusanController,
                  decoration: const InputDecoration(labelText: 'Jurusan'),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Jurusan wajib diisi' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                final payload = Mahasiswa(
                  id: mahasiswa?.id ?? '',
                  nama: namaController.text.trim(),
                  nim: nimController.text.trim(),
                  jurusan: jurusanController.text.trim(),
                );

                if (mahasiswa == null) {
                  await _service.tambahMahasiswa(payload);
                } else {
                  await _service.updateMahasiswa(payload);
                }
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: Text(mahasiswa == null ? 'Simpan' : 'Perbarui'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _streamKey = UniqueKey();
    });
    // Wait for at least one event to satisfy pull-to-refresh UX
    await _service.getMahasiswa().first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Week 2 - Firestore CRUD'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder<List<Mahasiswa>>(
          key: _streamKey,
          stream: _service.getMahasiswa(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text('Terjadi kesalahan mengambil data'),
              );
            }

            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return const Center(child: Text('Belum ada data mahasiswa'));
            }

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final mhs = data[index];
                return ListTile(
                  title: Text(mhs.nama),
                  subtitle: Text('${mhs.nim} • ${mhs.jurusan}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showFormDialog(context, mahasiswa: mhs),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context, mhs),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
