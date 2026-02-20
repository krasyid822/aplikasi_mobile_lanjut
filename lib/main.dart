import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'week1_main.dart';
import 'week2_main.dart';

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
  final List<String>? docsAssetPaths;

  const ModuleEntry({
    required this.title,
    required this.description,
    required this.builder,
    this.learnAssetPath,
    this.docsAssetPaths,
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
      docsAssetPaths: const ['assets/dokumentasi/week1.md'],
    ),
    ModuleEntry(
      title: 'Week 2 - CRUD Firestore',
      description: 'Create, Read, Update, Delete data di Firestore.',
      builder: (_) => const Week2App(),
      learnAssetPath: 'assets/materi/Materi Ajar PAML CRUD.pdf',
      docsAssetPaths: const ['assets/dokumentasi/week2.md'],
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

  Future<void> _openDocs(ModuleEntry module) async {
    final docs = module.docsAssetPaths;
    if (docs == null || docs.isEmpty) return;

    Future<void> open(String path) async {
      try {
        final content = await rootBundle.loadString(path);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _DocsPage(title: path.split('/').last, content: content),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka docs: $e')));
      }
    }

    if (docs.length == 1) {
      await open(docs.first);
      return;
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final path = docs[index];
              final name = path.split('/').last;
              return ListTile(
                leading: const Icon(Icons.description),
                title: Text(name),
                onTap: () {
                  Navigator.of(context).pop();
                  open(path);
                },
              );
            },
          ),
        );
      },
    );
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
                                    if (module.docsAssetPaths?.isNotEmpty ==
                                        true)
                                      TextButton.icon(
                                        onPressed: () => _openDocs(module),
                                        icon: const Icon(Icons.description),
                                        label: const Text('Docs'),
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

class _DocsPage extends StatelessWidget {
  const _DocsPage({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Markdown(
        padding: const EdgeInsets.all(16),
        data: content,
        selectable: true,
      ),
    );
  }
}
