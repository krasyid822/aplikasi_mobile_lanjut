import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'week1_main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LauncherApp());
}

class LauncherApp extends StatelessWidget {
  const LauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Launcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeLauncherPage(),
    );
  }
}

class ModuleEntry {
  final String title;
  final String description;
  final WidgetBuilder builder;
  final String? learnAssetPath;

  const ModuleEntry({
    required this.title,
    required this.description,
    required this.builder,
    this.learnAssetPath,
  });

  bool matches(String q) {
    final query = q.toLowerCase();
    return title.toLowerCase().contains(query) ||
        description.toLowerCase().contains(query);
  }
}

class HomeLauncherPage extends StatefulWidget {
  const HomeLauncherPage({super.key});

  @override
  State<HomeLauncherPage> createState() => _HomeLauncherPageState();
}

class _HomeLauncherPageState extends State<HomeLauncherPage> {
  final searchController = TextEditingController();

  final List<ModuleEntry> modules = [
    ModuleEntry(
      title: 'Week 1 - Firebase Auth',
      description: 'Login, register, reset password dengan Firebase Auth.',
      builder: (_) => const Week1App(),
      learnAssetPath: 'assets/materi/Materi Praktik Aplikasi Mobile Lanjut.pdf',
    ),
  ];

  Future<void> _openLearn(String assetPath, String fileName) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka materi: $e')));
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = modules
        .where((m) => m.matches(searchController.text))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Homescreen Launcher')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Cari modul',
                border: const OutlineInputBorder(),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Modul tidak ditemukan'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final module = filtered[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  module.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (module.learnAssetPath != null)
                                      TextButton.icon(
                                        onPressed: () => _openLearn(
                                          module.learnAssetPath!,
                                          module.learnAssetPath!
                                              .split('/')
                                              .last,
                                        ),
                                        icon: const Icon(Icons.menu_book),
                                        label: const Text('Learn'),
                                      ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: module.builder,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Launch'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
