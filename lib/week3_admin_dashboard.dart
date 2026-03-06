import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  File? _image;
  final picker = ImagePicker();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadProduct() async {
    if (_image == null) return;

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final uploadTask = FirebaseStorage.instance
        .ref('products/$fileName.jpg')
        .putFile(_image!);
    final snapshot = await uploadTask;
    final imageUrl = await snapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('products').add({
      'name': nameController.text,
      'price': double.parse(priceController.text),
      'description': descController.text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk berhasil ditambahkan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Produk'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Harga'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            const SizedBox(height: 10),
            _image == null
                ? const Text('Belum ada gambar')
                : Image.file(_image!, height: 150),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text('Pilih Gambar'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: uploadProduct,
              child: const Text('Upload Produk'),
            ),
          ],
        ),
      ),
    );
  }
}
