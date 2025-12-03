// lib/pages/part_removal/part_removal_scanner.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:majdur_p/datamodel/assets_datamodel.dart';
import 'package:majdur_p/pages/remove/part_removal_detail.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PartRemovalScanner extends StatefulWidget {
  const PartRemovalScanner({super.key});

  @override
  State<PartRemovalScanner> createState() => _PartRemovalScannerState();
}

class _PartRemovalScannerState extends State<PartRemovalScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _handleRawJson(String raw) async {
    try {
      final Map<String, dynamic> parsed = json.decode(raw);
      final asset = AssetDataModel.fromMap(parsed);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PartRemovalDetail(asset: asset)),
      );
    } catch (e) {
      _showSnack('Invalid JSON: $e');
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    if (capture.barcodes.isEmpty) return;
    _processing = true;
    final raw = capture.barcodes.first.rawValue ?? '';
    await _handleRawJson(raw);
    await Future.delayed(const Duration(milliseconds: 600));
    _processing = false;
  }

  Future<void> _onPaste() async {
    String initial = '';
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      initial = clip?.text ?? '';
    } catch (_) {}
    final controller = TextEditingController(text: initial);
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Paste Asset JSON'),
          content: TextField(
            controller: controller,
            maxLines: 12,
            decoration: const InputDecoration(hintText: '{"id":"..."}'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Open')),
          ],
        );
      },
    );

    if (res == null || res.isEmpty) return;
    await _handleRawJson(res);
  }

  @override
  Widget build(BuildContext context) {
    final bottomBar = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan'),
                onPressed: () => _controller.start(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.paste_outlined),
                label: const Text('Paste'),
                onPressed: _onPaste,
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Part Removal (Scan)')),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
          ),
          Positioned(top: 24, left: 0, right: 0, child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
            child: const Text('Point camera at asset QR (JSON) or use Paste', style: TextStyle(color: Colors.white)),
          ))),
          Positioned(left: 0, right: 0, bottom: 0, child: bottomBar),
        ],
      ),
    );
  }
}
