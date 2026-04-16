import 'package:flutter/material.dart';

import 'week4_firestore_service.dart';
import 'week4_add_campaign_screen.dart';

class CampaignDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  final String description;
  final int target;
  final int collected;
  final String imageUrl;
  final String ownerId;
  final bool canEdit;

  const CampaignDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.collected,
    required this.imageUrl,
    this.ownerId = '',
    this.canEdit = false,
  });

  @override
  CampaignDetailScreenState createState() => CampaignDetailScreenState();
}

class CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  bool _loading = false;
  late int _collected;

  @override
  void initState() {
    super.initState();
    _collected = widget.collected;
  }

  Future<void> _donate() async {
    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah donasi yang valid')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await FirestoreService().donate(widget.id, amount);
      // Refresh collected amount from server to reflect transaction result
      final latest = await FirestoreService().getCampaignCollected(widget.id);
      if (!mounted) return;
      setState(() => _collected = latest);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Donasi berhasil')));
      _amountCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editCampaign() async {
    final updated = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCampaignScreen(
          campaignId: widget.id,
          initialTitle: widget.title,
          initialDescription: widget.description,
          initialTarget: widget.target,
          initialImageUrl: widget.imageUrl,
        ),
      ),
    );
    if (updated == true) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus campaign?'),
        content: const Text('Yakin ingin menghapus campaign ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      try {
        await FirestoreService().deleteCampaign(widget.id);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Campaign dihapus')));
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.target > 0 ? (_collected / widget.target) : 0.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.canEdit
            ? [
                IconButton(
                  onPressed: _editCampaign,
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.imageUrl.isNotEmpty
                ? Image.network(widget.imageUrl, height: 200, fit: BoxFit.cover)
                : const SizedBox(height: 200),
            const SizedBox(height: 12),
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(widget.description),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
            const SizedBox(height: 8),
            Text('Terkumpul: $_collected / ${widget.target}'),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah donasi'),
            ),
            const SizedBox(height: 12),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _donate,
                    child: const Text('Donasi'),
                  ),
          ],
        ),
      ),
    );
  }
}
