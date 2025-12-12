// lib/pages/part_removal/part_removal_detail.dart
import 'package:flutter/material.dart';
import 'package:majdur_p/datamodel/removal_event_datamodel.dart';

class PartRemovalDetail extends StatefulWidget {
  final Map<String, dynamic> assetMap;
  const PartRemovalDetail({super.key, required this.assetMap});

  @override
  State<PartRemovalDetail> createState() => _PartRemovalDetailState();
}

class _PartRemovalDetailState extends State<PartRemovalDetail> {
  bool _loading = false;

  // Minimal getters using exact keys from scanned JSON
  String get _assetId => widget.assetMap['asset_id']?.toString() ?? '';
  String get _name => widget.assetMap['part_name']?.toString() ?? '';
  String get _vendor => widget.assetMap['vendor_name']?.toString() ?? '';
  String get _location => widget.assetMap['depot_location']?.toString() ?? '';
  String get _batch => widget.assetMap['batch']?.toString() ?? '';
  String get _quantity => widget.assetMap['quantity']?.toString() ?? '';

  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text((value == null || value.isEmpty) ? '—' : value)),
        ],
      ),
    );
  }

  Future<void> _onRemovePressed() async {
    final assetId = _assetId;
    if (assetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remove failed: Could not determine asset identifier from scanned JSON.')),
      );
      return;
    }

    // show dialog to get removed_by from user
    final removedByController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm removal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Remove asset "${_name.isEmpty ? assetId : _name}" from assets?'),
              const SizedBox(height: 12),
              TextField(
                controller: removedByController,
                decoration: const InputDecoration(labelText: 'Removed by (your name or id)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () {
              if ((removedByController.text ?? '').trim().isEmpty) {
                // keep dialog open and show simple hint (could improve UI)
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter removed_by')));
                return;
              }
              Navigator.of(ctx).pop(true);
            }, child: const Text('Remove')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final removedBy = removedByController.text.trim();
    setState(() => _loading = true);

    try {
      // Call RPC via RemovalEventDataModel
      final res = await RemovalEventDataModel.createRemovalEvent(RemovalEventDataModel(
        assetId: assetId,
        partName: _name,
        removedBy: removedBy,
      ));

      // res contains RPC returned json (audit row + deleted counts) or throws
      // ignore: avoid_print
      print('RPC result: $res');

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed successfully')));
      Navigator.of(context).pop({'removed': true, 'id': assetId, 'rpc': res});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remove failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Part Removal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Asset ID', _assetId.isEmpty ? null : _assetId),
            _buildRow('Name', _name.isEmpty ? null : _name),
            _buildRow('Vendor', _vendor.isEmpty ? null : _vendor),
            _buildRow('Location', _location.isEmpty ? null : _location),
            _buildRow('Batch', _batch.isEmpty ? null : _batch),
            _buildRow('Quantity', _quantity.isEmpty ? null : _quantity),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _onRemovePressed,
              icon: const Icon(Icons.delete_forever),
              label: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Remove part'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
