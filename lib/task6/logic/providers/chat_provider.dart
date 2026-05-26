import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../models/message_model.dart';
import '../services/gemma_service.dart';

class ChatProvider extends ChangeNotifier {
  final GemmaService _service = GemmaService();
  
  final List<MessageEntry> _messages = [];
  final List<String> _thoughtLogs = [];
  
  bool _isModelReady = false;
  bool _isDownloading = false;
  bool _isThinking = false;
  bool _shouldStop = false;
  bool _isFileAvailable = false;
  
  String _statusMessage = "Mengecek file...";
  double _downloadProgress = 0.0;
  
  int _tokenCount = 0;
  double _inferenceTime = 0.0;
  Timer? _metricsTimer;

  InferenceModel? _model;
  InferenceModelSession? _session;
  String _selectedUrl = GemmaService.cpuModelUrl;
  PreferredBackend? _activeBackend;

  // Getters
  List<MessageEntry> get messages => _messages;
  List<String> get thoughtLogs => _thoughtLogs;
  bool get isModelReady => _isModelReady;
  bool get isDownloading => _isDownloading;
  bool get isThinking => _isThinking;
  bool get isFileAvailable => _isFileAvailable;
  String get statusMessage => _statusMessage;
  double get downloadProgress => _downloadProgress;
  int get tokenCount => _tokenCount;
  double get inferenceTime => _inferenceTime;
  String get selectedUrl => _selectedUrl;

  void setSelectedUrl(String url) {
    _selectedUrl = url;
    checkFileStatus();
    notifyListeners();
  }

  void _log(String message) {
    _thoughtLogs.add("[${DateTime.now().toString().split(' ').last.substring(0, 8)}] $message");
    notifyListeners();
  }

  Future<void> checkFileStatus() async {
    _isFileAvailable = await _service.isFileDownloaded(_selectedUrl);
    _statusMessage = _isFileAvailable ? "File tersedia secara lokal" : "Model belum diunduh";
    notifyListeners();
  }

  Future<bool> requestPermission() async {
    final granted = await _service.requestStoragePermission();
    if (!granted) {
      _statusMessage = "Izin penyimpanan ditolak";
      notifyListeners();
    }
    return granted;
  }

  Future<void> checkAndInit() async {
    if (!await requestPermission()) return;
    await checkFileStatus();
    if (_isFileAvailable) {
      await loadActiveModel();
    }
  }

  Future<void> loadActiveModel() async {
    if (!await requestPermission()) return;
    _isModelReady = false;
    _statusMessage = "Memuat ke memori...";
    notifyListeners();
    
    try {
      _log("Mendaftarkan model...");
      await _service.installFromLocal(_selectedUrl);
      
      final target = _selectedUrl == GemmaService.gpuModelUrl ? PreferredBackend.gpu : PreferredBackend.cpu;
      _log("Inisialisasi ${target.name.toUpperCase()}...");
      
      try {
        await _session?.close();
        await _model?.close();
      } catch (_) {}
      
      _model = await _service.getModel(backend: target);
      _session = await _model!.createSession();
      
      _activeBackend = target;
      _isModelReady = true;
      _statusMessage = "Siap (${target.name.toUpperCase()})";
      _log("Berhasil.");
    } catch (e) {
      _log("CRITICAL ERROR: $e");
      _statusMessage = "Gagal memuat model";
      _isModelReady = false;
    }
    notifyListeners();
  }

  Future<void> downloadAndInstall() async {
    if (!await requestPermission()) return;
    _isDownloading = true;
    _downloadProgress = 0.0;
    _log("Mendownload...");
    notifyListeners();

    try {
      await _service.downloadModel(
        url: _selectedUrl,
        onProgress: (p) {
          _downloadProgress = p;
          _statusMessage = "Downloading: ${(p * 100).toStringAsFixed(1)}%";
          notifyListeners();
        },
      );
      _isFileAvailable = true;
      _isDownloading = false;
      await loadActiveModel();
    } catch (e) {
      _log("Download error: $e");
      _isDownloading = false;
      _statusMessage = "Unduhan gagal";
      notifyListeners();
    }
  }

  Future<void> stopInference() async {
    _shouldStop = true;
    _log("Permintaan stop dikirim...");
    
    // MediaPipe hanya mendukung pembatalan pada GPU. 
    // Pada CPU (XNNPACK), pembatalan akan memicu crash/state error.
    if (_session != null && _activeBackend == PreferredBackend.gpu) {
      try {
        await _session!.stopGeneration();
        _log("Generasi GPU dihentikan paksa.");
      } catch (e) {
        _log("Gagal stop native: $e");
      }
    } else {
      _log("Stop visual (CPU tidak mendukung native cancellation).");
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty || !_isModelReady || _isThinking || _session == null) return;
    
    _messages.add(MessageEntry(text: text, isUser: true));
    _isThinking = true;
    _shouldStop = false;
    _tokenCount = 0;
    _inferenceTime = 0.0;
    notifyListeners();

    _metricsTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_shouldStop) {
        _inferenceTime += 0.1;
        notifyListeners();
      }
    });

    try {
      _log("Mempersiapkan inferensi...");
      await _session!.addQueryChunk(Message.text(text: text, isUser: true));
      
      String response = "";
      final stream = _session!.getResponseAsync();
      
      _messages.add(MessageEntry(text: "...", isUser: false));
      notifyListeners();

      await for (final chunk in stream) {
        if (_shouldStop) {
          _log("Proses diputus secara visual.");
          // Pada CPU, kita harus membiarkan stream selesai di background agar tidak busy
          if (_activeBackend == PreferredBackend.gpu) break;
        }
        
        if (chunk.isNotEmpty) {
          if (!_shouldStop) {
            response += chunk;
            _tokenCount++;
            _messages[_messages.length - 1] = MessageEntry(text: response, isUser: false);
            notifyListeners();
          }
        }
      }
    } catch (e) { 
      _log("Error Inferensi: $e");
      if (e.toString().contains("busy") || e.toString().contains("processing")) {
        _log("Mesin terkunci. Mencoba reset paksa...");
        await clearSession();
      }
    } finally {
      _metricsTimer?.cancel();
      _isThinking = false;
      _shouldStop = false;
      notifyListeners();
    }
  }

  Future<void> disposeResources() async {
    _log("Membersihkan resource RAM sebelum reboot...");
    try {
      _metricsTimer?.cancel();
      await _session?.close();
      await _model?.close();
      _session = null;
      _model = null;
      _messages.clear();
      _thoughtLogs.clear();
      _isModelReady = false;
      _log("Resource berhasil dibebaskan.");
      notifyListeners();
    } catch (e) {
      debugPrint("Error saat dispose: $e");
    }
  }

  Future<void> clearSession() async {
    _statusMessage = "Mereset sesi...";
    notifyListeners();
    try {
      await _session?.close();
    } catch (e) {
      _log("Gagal menutup sesi lama: $e");
    }
    
    if (_model != null) {
      try {
        _session = await _model!.createSession();
        _log("Sesi baru dibuat.");
      } catch (e) {
        _log("Gagal membuat sesi baru, memuat ulang model...");
        await loadActiveModel();
      }
    }
    _messages.clear();
    _statusMessage = _isModelReady ? "Siap (${_activeBackend?.name.toUpperCase()})" : "Sesi direset";
    notifyListeners();
  }
  
  Future<void> deleteModel() async {
    if (!await requestPermission()) return;
    try {
      await _session?.close();
      await _model?.close();
    } catch (_) {}
    await _service.deleteFile(_selectedUrl);
    _isModelReady = false;
    _isFileAvailable = false;
    _statusMessage = "Model dihapus";
    _log("File dihapus dari disk.");
    notifyListeners();
  }
}
