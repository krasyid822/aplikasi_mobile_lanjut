import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GemmaService {
  static const String gpuModelUrl = "https://huggingface.co/google/gemma-2b-it-tflite/resolve/main/gemma-2b-it-gpu-int4.bin";
  static const String cpuModelUrl = "https://huggingface.co/google/gemma-2b-it-tflite/resolve/main/gemma-2b-it-cpu-int4.bin";
  
  static String get hfToken => dotenv.env['HF_TOKEN'] ?? "";

  static bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    // Load .env file before initializing FlutterGemma
    await dotenv.load(fileName: "lib/task6/.env");
    await FlutterGemma.initialize(huggingFaceToken: hfToken);
    _isInitialized = true;
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<String> getLocalPath(String url) async {
    final fileName = url.contains("cpu") ? "gemma-2b-it-cpu-int4.bin" : "gemma-2b-it-gpu-int4.bin";
    final List<String> possiblePaths = [
      '/storage/emulated/0/Download/ai_bin',
      '/sdcard/Download/ai_bin',
    ];
    
    Directory? targetDir;
    for (String path in possiblePaths) {
      final dir = Directory(path);
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        targetDir = dir;
        break;
      } catch (e) {
        debugPrint("Gagal membuat direktori di $path: $e");
      }
    }

    if (targetDir == null) {
      final internal = await getApplicationDocumentsDirectory();
      targetDir = Directory("${internal.path}/ai_bin");
      if (!await targetDir.exists()) await targetDir.create(recursive: true);
    }
    
    return "${targetDir.path}/$fileName";
  }

  Future<bool> isFileDownloaded(String url) async {
    final path = await getLocalPath(url);
    final file = File(path);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > 1000000000;
  }

  Future<void> deleteFile(String url) async {
    final path = await getLocalPath(url);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> installFromLocal(String url) async {
    final path = await getLocalPath(url);
    await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromFile(path)
        .install();
  }

  Future<InferenceModel> getModel({required PreferredBackend backend, int maxTokens = 256}) async {
    return await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: backend,
    );
  }

  Future<void> downloadModel({
    required String url,
    required Function(double) onProgress,
  }) async {
    final savePath = await getLocalPath(url);
    final dio = Dio();
    await dio.download(
      url,
      savePath,
      options: Options(headers: {"Authorization": "Bearer $hfToken"}),
      onReceiveProgress: (received, total) {
        if (total != -1) onProgress(received / total);
      },
    );
    await installFromLocal(url);
  }
}
