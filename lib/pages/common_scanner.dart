// common_scanner.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Call this helper to open scanner and get scanned raw JSON/string:
/// final result = await showCommonScanner(context, title: 'Scan Receipt QR');
Future<String?> showCommonScanner(
  BuildContext context, {
  String title = 'Scan QR Code',
  bool allowPaste = true,
  bool showTorch = true,
  bool showCameraSwitch = true,
  double overlayWidth = 260,
  double overlayHeight = 180,
}) {
  return Navigator.push<String?>(
    context,
    MaterialPageRoute(
      builder: (_) => CommonScannerPage(
        title: title,
        allowPaste: allowPaste,
        showTorch: showTorch,
        showCameraSwitch: showCameraSwitch,
        overlayWidth: overlayWidth,
        overlayHeight: overlayHeight,
      ),
    ),
  );
}

class CommonScannerPage extends StatefulWidget {
  final String title;
  final bool allowPaste;
  final bool showTorch;
  final bool showCameraSwitch;
  final double overlayWidth;
  final double overlayHeight;

  const CommonScannerPage({
    super.key,
    this.title = 'Scan QR Code',
    this.allowPaste = true,
    this.showTorch = true,
    this.showCameraSwitch = true,
    this.overlayWidth = 260,
    this.overlayHeight = 180,
  });

  @override
  State<CommonScannerPage> createState() => _CommonScannerPageState();
}

class _CommonScannerPageState extends State<CommonScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_isScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) {
      _showTemporaryMessage('Empty/invalid QR payload');
      return;
    }

    setState(() => _isScanned = true);
    // Pause camera to avoid duplicate scans
    _controller.stop();

    // Return the scanned string to caller
    Navigator.pop(context, raw);
  }

  void _showTemporaryMessage(String text, {int seconds = 2}) {
    setState(() => _message = text);
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted) setState(() => _message = null);
    });
  }

  Future<void> _pasteManually() async {
    final controller = TextEditingController();
    final pasted = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste QR text'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste the raw string/JSON from QR here',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Open'),
          ),
        ],
      ),
    );

    if (pasted != null && pasted.isNotEmpty) {
      // Return pasted content to caller
      Navigator.pop(context, pasted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.showTorch)
            IconButton(
              tooltip: 'Toggle flash',
              icon: const Icon(Icons.flash_on),
              onPressed: () => _controller.toggleTorch(),
            ),
          if (widget.showCameraSwitch)
            IconButton(
              tooltip: 'Switch camera',
              icon: const Icon(Icons.cameraswitch),
              onPressed: () => _controller.switchCamera(),
            ),
          if (widget.allowPaste)
            IconButton(
              tooltip: 'Paste / Manual',
              icon: const Icon(Icons.paste),
              onPressed: _pasteManually,
            ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetection,
            // small performance options:
            fit: BoxFit.cover,
          ),

          // Simple center overlay to guide the user
          Center(
            child: Container(
              width: widget.overlayWidth,
              height: widget.overlayHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black26,
              ),
            ),
          ),

          // Info & messages
          Positioned(
            top: 18,
            left: 18,
            right: 18,
            child: Column(
              children: [
                if (_message != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_message!, style: const TextStyle(color: Colors.white)),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.qr_code, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Point camera at QR code', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),

          // Bottom controls/status
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isScanned
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Processing...', style: TextStyle(color: Colors.white)),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Scan'),
                            onPressed: () {
                              // No-op: scanning is automatic. Give user hint.
                              _showTemporaryMessage('Point the camera at a QR code');
                            },
                          ),
                          if (widget.allowPaste)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.paste),
                              label: const Text('Paste'),
                              onPressed: _pasteManually,
                            ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
