import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'week3_supabase_config.dart';
import 'week4_messaging_service.dart';
import 'week4_supabase_messaging.dart';
import 'app_theme.dart';
import 'week1_main.dart';
import 'week2_main.dart';
import 'week3_main.dart';
import 'week4_main.dart';
import 'week5_main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ensureWeek3SupabaseInitialized();
  await MessagingService.init();
  await SupabaseMessagingService.init();
  runApp(const LauncherApp());
}

class LauncherApp extends StatelessWidget {
  const LauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveMaterialApp(
      title: 'Launcher',
      home: HomeLauncherPage(),
    );
  }
}

class ModuleEntry {
  final String title;
  final String description;
  final WidgetBuilder builder;
  final String? learnAssetPath;
  final List<String>? docsAssetPaths;
  final String? cardBackgroundAssetPath;

  const ModuleEntry({
    required this.title,
    required this.description,
    required this.builder,
    this.learnAssetPath,
    this.docsAssetPaths,
    this.cardBackgroundAssetPath,
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
  final Map<String, Color> _cardBackgroundColors = {};

  final List<ModuleEntry> modules = [
    ModuleEntry(
      title: 'Task 1 - Firebase Auth',
      description: 'Login, register, reset password dengan Firebase Auth.',
      builder: (_) => const Week1App(),
      learnAssetPath: 'assets/materi/Materi Praktik Aplikasi Mobile Lanjut.pdf',
      docsAssetPaths: const ['assets/dokumentasi/week1.md'],
      cardBackgroundAssetPath: 'assets/background/week1.png',
    ),
    ModuleEntry(
      title: 'Task 2 - CRUD Firestore',
      description: 'Create, Read, Update, Delete data di Firestore.',
      builder: (_) => const Week2App(),
      learnAssetPath: 'assets/materi/Materi Ajar PAML CRUD.pdf',
      docsAssetPaths: const ['assets/dokumentasi/week2.md'],
      cardBackgroundAssetPath: 'assets/background/week2.png',
    ),
    ModuleEntry(
      title: 'Task 3 - F̶i̶r̶e̶b̶a̶s̶e̶ Supabase Storage',
      description:
          'Upload dan download file menggunakan F̶i̶r̶e̶b̶a̶s̶e̶ Supabase Storage. Membangun aplikasi toko online dengan fitur upload gambar produk pada dasbor admin.',
      builder: (_) => Week3App(),
      learnAssetPath:
          'assets/materi/Membangun Aplikasi Toko Online Menggunakan Flutter dan Firebase.pdf',
      docsAssetPaths: const ['assets/dokumentasi/week3.md'],
      cardBackgroundAssetPath: 'assets/background/week3.png',
    ),
    ModuleEntry(
      title: 'Task 4 - Aplikasi Donasi Online',
      description:
          'Membangun aplikasi donasi online dengan fitur upload gambar campaign, halaman detail campaign, dan fitur donasi.',
      builder: (_) => const Week4App(),
      learnAssetPath:
          'assets/materi/MATERI AJAR PRAKTIK.pdf',
      docsAssetPaths: const ['assets/dokumentasi/week4.md'],
      cardBackgroundAssetPath: 'assets/background/week4.png',
    ),
    ModuleEntry(
      title: 'Task 5 - Aplikasi Sistem Imformasi Akademik Mahasiswa',
      description:
      'Membangun aplikasi akademik untuk mengelola data akademik.',
      builder: (_) => const Week5App(),
      learnAssetPath:
      'assets/materi/Aplikasi Mobile Sistem Informasi Akademik Mahasiswa.pdf',
      docsAssetPaths: const ['assets/dokumentasi/week5.md'],
      cardBackgroundAssetPath: 'assets/background/week5.jpeg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _preloadCardBackgroundColors();
  }

  Future<void> _preloadCardBackgroundColors() async {
    final assetPaths = modules
        .map((module) => module.cardBackgroundAssetPath)
        .whereType<String>()
        .toSet();

    for (final assetPath in assetPaths) {
      final color = await _extractEdgeColor(assetPath);
      if (!mounted || color == null) continue;
      setState(() {
        _cardBackgroundColors[assetPath] = color;
      });
    }
  }

  Future<Color?> _extractEdgeColor(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 48,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) {
        image.dispose();
        codec.dispose();
        return null;
      }

      final pixels = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;

      var red = 0;
      var green = 0;
      var blue = 0;
      var alpha = 0;
      var count = 0;

      void samplePixelAtOffset(int offset) {
        final pixelAlpha = pixels[offset + 3];
        if (pixelAlpha == 0) return;

        red += pixels[offset];
        green += pixels[offset + 1];
        blue += pixels[offset + 2];
        alpha += pixelAlpha;
        count++;
      }

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final offset = (y * width + x) * 4;
          if (pixels[offset + 3] == 0) continue;
          samplePixelAtOffset(offset);
          break;
        }
      }

      image.dispose();
      codec.dispose();

      if (count == 0) return null;

      return Color.fromARGB(
        (alpha / count).round(),
        (red / count).round(),
        (green / count).round(),
        (blue / count).round(),
      );
    } catch (_) {
      return null;
    }
  }

  Color _resolveCardBaseColor(ColorScheme colorScheme, ModuleEntry module) {
    final assetPath = module.cardBackgroundAssetPath;
    if (assetPath == null) {
      return colorScheme.surfaceContainerLow;
    }

    final imageColor = _cardBackgroundColors[assetPath];
    if (imageColor == null) {
      return colorScheme.surfaceContainerHigh;
    }

    return imageColor;
  }

  Color _resolveCardForegroundColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) ==
            Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

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
      appBar: AppBar(title: const Text('Praktik Aplikasi Mobile Lanjut')),
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
                          final colorScheme = Theme.of(context).colorScheme;
                          final cardBaseColor = _resolveCardBaseColor(
                            colorScheme,
                            module,
                          );
                          final cardForegroundColor = _resolveCardForegroundColor(
                            cardBaseColor,
                          );
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: EdgeInsets.zero,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBaseColor,
                                  image: module.cardBackgroundAssetPath != null
                                      ? DecorationImage(
                                          image: AssetImage(
                                            module.cardBackgroundAssetPath!,
                                          ),
                                          fit: BoxFit.contain,
                                          alignment: Alignment.centerRight,
                                        )
                                      : null,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient:
                                        module.cardBackgroundAssetPath != null
                                        ? LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: 0.18,
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        module.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  module.cardBackgroundAssetPath !=
                                                      null
                                                  ? cardForegroundColor
                                                  : null,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        module.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  module.cardBackgroundAssetPath !=
                                                      null
                                                  ? cardForegroundColor
                                                        .withValues(alpha: 0.82)
                                                  : null,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: [
                                                  if (module.learnAssetPath !=
                                                      null)
                                                    TextButton.icon(
                                                      onPressed: () => _openLearn(
                                                        module.learnAssetPath!,
                                                        module.learnAssetPath!
                                                            .split('/')
                                                            .last,
                                                      ),
                                                      icon: const Icon(
                                                        Icons.menu_book,
                                                      ),
                                                      label: const Text('Learn'),
                                                      style:
                                                          module.cardBackgroundAssetPath !=
                                                              null
                                                          ? TextButton.styleFrom(
                                                              foregroundColor:
                                                                  cardForegroundColor,
                                                            )
                                                          : null,
                                                    ),
                                                  if (module.learnAssetPath !=
                                                          null &&
                                                      module
                                                              .docsAssetPaths
                                                              ?.isNotEmpty ==
                                                          true)
                                                    const SizedBox(width: 8),
                                                  if (module
                                                          .docsAssetPaths
                                                          ?.isNotEmpty ==
                                                      true)
                                                    TextButton.icon(
                                                      onPressed: () =>
                                                          _openDocs(module),
                                                      icon: const Icon(
                                                        Icons.description,
                                                      ),
                                                      label: const Text('Docs'),
                                                      style:
                                                          module.cardBackgroundAssetPath !=
                                                              null
                                                          ? TextButton.styleFrom(
                                                              foregroundColor:
                                                                  cardForegroundColor,
                                                            )
                                                          : null,
                                                    ),
                                                ],
                                              ),
                                            ),
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
