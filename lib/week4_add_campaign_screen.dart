import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'week4_storage_service.dart';
import 'week4_firestore_service.dart';

class AddCampaignScreen extends StatefulWidget {
  const AddCampaignScreen({super.key});

  @override
  AddCampaignScreenState createState() => AddCampaignScreenState();
}

class AddCampaignScreenState extends State<AddCampaignScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();
  File? _image;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;
    if (title.isEmpty || desc.isEmpty || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi dan gambar dipilih'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final imageUrl = await StorageService().uploadImage(_image!);
      final ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirestoreService().addCampaign({
        'title': title,
        'description': desc,
        'target': target,
        'collected': 0,
        'imageUrl': imageUrl,
        'ownerId': ownerId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign berhasil ditambahkan')),
      );
      Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Tambah Campaign')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _targetCtrl,
              decoration: const InputDecoration(labelText: 'Target (angka)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _image != null
                ? Image.file(_image!, height: 160, fit: BoxFit.cover)
                : const SizedBox(
                    height: 160,
                    child: Center(child: Text('Belum ada gambar')),
                  ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('Pilih Gambar'),
            ),
            const SizedBox(height: 12),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _save,
                    child: const Text('Simpan Campaign'),
                  ),
          ],
        ),
      ),
    );
  }
}
