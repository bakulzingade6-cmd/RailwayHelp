// lib/pages/install_scanner.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'installation_DB.dart';
import 'package:flutter/services.dart';

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

  Future<void> _processData(String rawData) async {
    if (_processing) return;
    _processing = true;
    try {
      final parsed = json.decode(rawData);
      if (parsed is Map<String, dynamic>) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InstallationDb(rawJson: rawData))
        );
      } else {
        _showSnack('QR Data is not a valid JSON object');
      }
    } catch (e) {
      _showSnack('Invalid Data format: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final raw = barcode.rawValue;

    if (raw == null || raw.trim().isEmpty) {
      _showSnack('Empty QR Code');
      return;
    }

    await _processData(raw);
  }

  Future<void> _onPaste() async {
    String initial = '';
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      if (clip?.text != null) initial = clip!.text!.trim();
    } catch (_) {}
    final controllerText = TextEditingController(text: initial);

    if (!mounted) return;
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Manual Input'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Paste or type JSON object for installation:'),
              const SizedBox(height: 8),
              TextField(
                controller: controllerText,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{"asset_id": "A123", "location": {"lat": 19.0, "lng": 72.0}}'
                )
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controllerText.text.trim()), child: const Text('Process')),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      await _processData(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Asset QR')),
      body: Stack(children: [
        Positioned.fill(
          child: MobileScanner(controller: controller, onDetect: _onDetect),
        ),

        Positioned(
          top: 24, left: 20, right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: const Text('Align QR code within frame', style: TextStyle(color: Colors.white))
            )
          )
        ),

        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white, size: 30),
                  onPressed: () => controller.toggleTorch(),
                  tooltip: 'Toggle Flash',
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Manual Entry'),
                  onPressed: _onPaste,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                  onPressed: () => controller.switchCamera(),
                  tooltip: 'Switch Camera',
                ),
              ],
            ),
          )
        ),
      ]),
    );
  }
}
