// lib/pages/inspection/inspect_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:majdur_p/pages/inspection/inspection_form.dart';

class InspectionScanner extends StatefulWidget {
  const InspectionScanner({super.key});

  @override
  State<InspectionScanner> createState() => _InspectionScannerState();
}

class _InspectionScannerState extends State<InspectionScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onDetect(BarcodeCapture capture) async {
    // defensive: ensure not already navigating/processing
    if (_isProcessing) return;

    if (capture.barcodes.isEmpty) {
      return;
    }

    final barcode = capture.barcodes.first;
    final raw = barcode.rawValue;
    if (raw == null || raw.trim().isEmpty) {
      _showSnack('QR Code empty or unreadable');
      return;
    }

    _isProcessing = true;
    try {
      final parsed = json.decode(raw);
      if (parsed is Map<String, dynamic>) {
        // Navigate to form with prefill
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InspectionFormPage(prefill: parsed),
          ),
        );
      } else {
        _showSnack('QR does not contain a JSON object');
      }
    } catch (e) {
      _showSnack('Invalid QR JSON: ${e.toString()}');
    } finally {
      // small delay to avoid immediate re-trigger from camera
      await Future.delayed(const Duration(milliseconds: 700));
      _isProcessing = false;
    }
  }

  Future<void> _onPastePressed() async {
    // Try to read clipboard first
    String initialText = '';
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      if (clip != null && clip.text != null && clip.text!.trim().isNotEmpty) {
        initialText = clip.text!.trim();
      }
    } catch (_) {
      // ignore clipboard read errors
    }

    final controller = TextEditingController(text: initialText);

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Paste JSON'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Paste the inspection JSON below:'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '{"asset_id":"...","inspector":"..."}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Open')),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty) {
      return;
    }

    // Try parse JSON
    try {
      final parsed = json.decode(result);
      if (parsed is Map<String, dynamic>) {
        // navigate to form page with prefill
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InspectionFormPage(prefill: parsed)),
        );
      } else {
        _showSnack('Provided JSON is not an object');
      }
    } catch (e) {
      _showSnack('Invalid JSON: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bottom buttons style (similar to your screenshot)
    final bottomBar = SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan'),
                onPressed: () {
                  // toggle torch as example or just ensure camera active
                  // Here we simply ensure the controller is started and scanner visible
                  _controller.start();
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.paste_outlined),
                label: const Text('Paste'),
                onPressed: _onPastePressed,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Inspection QR'),
      ),
      body: Stack(
        children: [
          // Scanner fills the screen behind overlay
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              // use the current API without allowDuplicates
              onDetect: _onDetect,
            ),
          ),

          // Instruction overlay (subtle)
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                child: const Text('Point camera at QR (JSON) or use Paste', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),

          // Bottom paste/scan bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: bottomBar,
          ),
        ],
      ),
    );
  }
}
