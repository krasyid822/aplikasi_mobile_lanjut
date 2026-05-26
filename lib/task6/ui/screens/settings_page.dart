import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/chat_provider.dart';
import '../../logic/services/gemma_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan AI"),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Konfigurasi Backend",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ListTile(
            title: const Text("Mode Akselerasi"),
            subtitle: Text(provider.selectedUrl == GemmaService.gpuModelUrl 
                ? "GPU (Performa Tinggi)" 
                : "CPU (Lebih Stabil)"),
            trailing: const Icon(Icons.memory),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _backendOption(
                    context, 
                    provider, 
                    "GPU Mode", 
                    GemmaService.gpuModelUrl,
                    Icons.bolt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _backendOption(
                    context, 
                    provider, 
                    "CPU Mode", 
                    GemmaService.cpuModelUrl,
                    Icons.settings_suggest,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Informasi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Model"),
            subtitle: Text("Google Gemma 2B IT (INT4)"),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text("Status File"),
            subtitle: Text(provider.isFileAvailable ? "Terunduh" : "Belum diunduh"),
            trailing: provider.isFileAvailable && !provider.isModelReady 
                ? IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _confirmDelete(context, provider),
                    tooltip: "Hapus Model",
                  )
                : null,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChatProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Model"),
        content: const Text("Apakah Anda yakin ingin menghapus file model AI ini dari penyimpanan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteModel();
              Navigator.pop(context);
            }, 
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  Widget _backendOption(BuildContext context, ChatProvider p, String label, String url, IconData icon) {
    final isSelected = p.selectedUrl == url;
    return InkWell(
      onTap: p.isThinking ? null : () => p.setSelectedUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade700 : Colors.white,
          border: Border.all(color: isSelected ? Colors.indigo.shade900 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 8)] : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.indigo),
            const SizedBox(height: 8),
            Text(
              label, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isSelected ? Colors.white : Colors.black87
              ),
            ),
          ],
        ),
      ),
    );
  }
}
