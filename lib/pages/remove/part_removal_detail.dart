// lib/pages/part_removal/part_removal_detail.dart
import 'package:flutter/material.dart';
import 'package:majdur_p/datamodel/assets_datamodel.dart';
import 'package:majdur_p/datamodel/removal_event_datamodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartRemovalDetail extends StatefulWidget {
  final AssetDataModel asset;
  const PartRemovalDetail({super.key, required this.asset});

  @override
  State<PartRemovalDetail> createState() => _PartRemovalDetailState();
}

class _PartRemovalDetailState extends State<PartRemovalDetail> {
  bool _loading = false;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '—')),
        ],
      ),
    );
  }

  Future<void> _onRemovePressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm removal'),
        content: Text('Remove asset "${widget.asset.name ?? widget.asset.id}" from assets? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;

      // Insert removal event (audit)
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'unknown';
      final evt = RemovalEventDataModel(
        assetId: widget.asset.id ?? 'unknown',
        removedBy: userId,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await RemovalEventDataModel.createRemovalEvent(evt);

      // Delete asset
      final del = await supabase.from('assets').delete().eq('id', widget.asset.id ?? 'unknown').maybeSingle();

      // show result
      if (del == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset removed (no return record)')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset removed successfully')));
      }

      Navigator.of(context).pop({'removed': true, 'id': widget.asset.id});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remove failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    return Scaffold(
      appBar: AppBar(title: const Text('Part Removal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Asset ID', a.id),
            _buildRow('Name', a.name),
            _buildRow('Status', a.status),
            _buildRow('Location', a.location),
            _buildRow('Section', a.section),
            _buildRow('Part Type', a.partType),
            _buildRow('Vendor', a.vendor),
            _buildRow('Batch', a.batch),
            _buildRow('Quantity', a.quantity?.toString()),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Removal notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _onRemovePressed,
              icon: const Icon(Icons.delete_forever),
              label: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Remove part'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
