// lib/pages/install_scanner.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'installation_DB.dart';

class InstallScannerPage extends StatefulWidget {
  const InstallScannerPage({super.key});

  @override
  State<InstallScannerPage> createState() => _InstallScannerPageState();
}

class _InstallScannerPageState extends State<InstallScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  bool _processing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    if (capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.first;
    final raw = barcode.rawValue;
    if (raw == null || raw.trim().isEmpty) {
      _showSnack('Empty QR');
      return;
    }
    _processing = true;
    try {
      // try parse
      final parsed = json.decode(raw);
      if (parsed is Map<String, dynamic>) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => InstallationDb(rawJson: raw)));
      } else {
        _showSnack('QR JSON is not an object');
      }
    } catch (e) {
      _showSnack('Invalid QR JSON: $e');
    } finally {
      // short delay
      await Future.delayed(const Duration(milliseconds: 700));
      _processing = false;
    }
  }

  Future<void> _onPaste() async {
    String initial = '';
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      if (clip?.text != null) initial = clip!.text!.trim();
    } catch (_) {}
    final controllerText = TextEditingController(text: initial);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Paste Installation JSON'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Paste JSON object for install event:'),
              const SizedBox(height: 8),
              TextField(controller: controllerText, maxLines: 10, decoration: const InputDecoration(border: OutlineInputBorder())),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controllerText.text.trim()), child: const Text('Open')),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty) return;
    try {
      final parsed = json.decode(result);
      if (parsed is Map<String, dynamic>) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => InstallationDb(rawJson: result)));
      } else {
        _showSnack('Provided JSON is not an object');
      }
    } catch (e) {
      _showSnack('Invalid JSON: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomBar = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.flash_on),
              label: const Text('Flash'),
              onPressed: () => controller.toggleTorch(),
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
        ]),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Installation QR')),
      body: Stack(children: [
        Positioned.fill(
          child: MobileScanner(controller: controller, onDetect: _onDetect),
        ),
        Positioned(top: 24, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)), child: const Text('Point camera at installation QR or Paste JSON', style: TextStyle(color: Colors.white))))),
        Positioned(left: 0, right: 0, bottom: 0, child: bottomBar),
      ]),
    );
  }
}
