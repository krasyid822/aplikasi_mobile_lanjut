import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import '../../logic/providers/chat_provider.dart';
import '../../logic/services/gemma_service.dart';
import '../widgets/chat_widgets.dart';
import 'settings_page.dart';

class UasPage extends StatefulWidget {
  const UasPage({super.key});
  @override
  State<UasPage> createState() => _UasPageState();
}

class _UasPageState extends State<UasPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().checkAndInit();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: SizedBox(
          height: 30,
          child: Marquee(
            text: "Local AI Agent",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            blankSpace: 40.0,
            velocity: 30.0,
            pauseAfterRound: const Duration(seconds: 2),
            startPadding: 10.0,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        ),
        backgroundColor: Colors.indigo.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Trigger the PopScope in AdaptiveMaterialApp
            Navigator.of(context).maybePop();
          },
          tooltip: "Kembali",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: "Pengaturan AI",
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.orangeAccent), 
            onPressed: () => _confirmRestart(context),
            tooltip: "Hard Restart App",
          ),
          IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.white), onPressed: () => provider.clearSession(), tooltip: "Reset Chat"),
          IconButton(icon: const Icon(Icons.terminal, color: Colors.white), onPressed: () => _showDiagnostics(context), tooltip: "Log"),
        ],
      ),
      body: Column(
        children: [
          _buildStatusHeader(provider),
          if (provider.isThinking || provider.tokenCount > 0) MetricsPanel(
            tokenCount: provider.tokenCount, 
            inferenceTime: provider.inferenceTime
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.messages.length,
              itemBuilder: (context, index) => ChatBubble(message: provider.messages[index]),
            ),
          ),
          _buildInputArea(provider),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ChatProvider p) {
    final isGpu = p.selectedUrl == GemmaService.gpuModelUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: p.isModelReady ? Colors.indigo.shade50 : Colors.amber.shade50,
        border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                p.isModelReady ? Icons.check_circle : (p.isDownloading ? Icons.sync : (p.statusMessage.contains("izin") ? Icons.security_outlined : Icons.error_outline)),
                size: 18,
                color: p.isModelReady ? Colors.green : (p.statusMessage.contains("izin") ? Colors.red : Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.statusMessage, 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: p.statusMessage.contains("izin") ? Colors.red.shade900 : Colors.black87)
                )
              ),
              if (p.statusMessage.contains("izin"))
                TextButton(
                  onPressed: () => p.requestPermission(),
                  child: const Text("Minta Izin", style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          if (p.isDownloading) LinearProgressIndicator(value: p.downloadProgress, minHeight: 6)
          else if (!p.isModelReady) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: p.statusMessage.contains("izin") 
                ? () => p.requestPermission()
                : (p.isFileAvailable ? () => p.loadActiveModel() : () => p.downloadAndInstall()),
              icon: Icon(p.statusMessage.contains("izin") ? Icons.security : (p.isFileAvailable ? Icons.bolt : Icons.download)),
              label: Text(p.statusMessage.contains("izin") ? "Beri Izin Akses" : (p.isFileAvailable ? "Muat ke RAM (Lokal)" : "Unduh ${isGpu ? 'GPU' : 'CPU'} Model")),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700, 
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact
              ),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatProvider p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: p.isModelReady && !p.isThinking,
                decoration: const InputDecoration(hintText: "Tanya sesuatu tentang kode...", border: InputBorder.none),
                onSubmitted: (v) {
                  p.sendMessage(v);
                  _controller.clear();
                  _scrollToBottom();
                },
              ),
            ),
            if (p.isThinking)
              IconButton(
                icon: const Icon(Icons.stop_circle, color: Colors.red, size: 30), 
                onPressed: () async => await p.stopInference()
              )
            else
              IconButton(icon: const Icon(Icons.send), onPressed: () {
                p.sendMessage(_controller.text);
                _controller.clear();
                _scrollToBottom();
              }),
          ],
        ),
      ),
    );
  }

  void _showDiagnostics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => Consumer<ChatProvider>(
        builder: (context, provider, child) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("AI PROCESS LOGS", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.thoughtLogs.length,
                  itemBuilder: (context, i) => Text(
                    provider.thoughtLogs[i], 
                    style: const TextStyle(color: Colors.lightGreenAccent, fontFamily: 'monospace', fontSize: 11)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRestart(BuildContext chatContext) {
    showDialog(
      context: chatContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Hard Restart"),
        content: const Text("Seluruh aplikasi akan dimuat ulang. Gunakan jika mesin AI benar-benar macet."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              // Gunakan context yang memiliki akses ke Provider
              await chatContext.read<ChatProvider>().disposeResources();
              await Future.delayed(const Duration(milliseconds: 300));
              Restart.restartApp();
            },
            child: const Text("Restart Sekarang"),
          ),
        ],
      ),
    );
  }
}
