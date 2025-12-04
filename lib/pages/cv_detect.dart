import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_vision/flutter_vision.dart';

class YoloImage11 extends StatefulWidget {
  const YoloImage11({super.key});

  @override
  State<YoloImage11> createState() => _YoloImage11State();
}

class _YoloImage11State extends State<YoloImage11> {
  late FlutterVision vision;

  File? imageFile;
  List<Map<String, dynamic>> yoloResults = [];

  int imageWidth = 1;
  int imageHeight = 1;
  bool isLoaded = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await vision.loadYoloModel(
        labels: 'assets/labels.txt',
        modelPath: 'assets/best_float32.tflite', // your float32 model
        modelVersion: "yolov11", // IMPORTANT for YOLO 11
        quantization: false, // float32 => false
        numThreads: 2,
        useGpu: false,
      );
      setState(() => isLoaded = true);
    } catch (e) {
      setState(() => errorMessage = e.toString());
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      imageFile = File(photo.path);
      yoloResults.clear();
    });
  }

  Future<void> _runDetection() async {
    if (imageFile == null) return;
    yoloResults.clear();

    // read bytes and decode to get width & height
    final Uint8List bytes = await imageFile!.readAsBytes();
    final ui.Image img = await decodeImageFromList(bytes);
    imageWidth = img.width;
    imageHeight = img.height;

    final result = await vision.yoloOnImage(
      bytesList: bytes,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      iouThreshold: 0.45,
      confThreshold: 0.25,
      classThreshold: 0.25,
    );

    debugPrint("Image detections: $result");

    if (!mounted) return;
    setState(() {
      yoloResults = List<Map<String, dynamic>>.from(result);
    });
  }

  @override
  void dispose() {
    vision.closeYoloModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error: $errorMessage',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("YOLO11 Image Detection")),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Show the picked image
          if (imageFile != null)
            Image.file(
              imageFile!,
              fit: BoxFit.contain,
              width: screenSize.width,
              height: screenSize.height,
            ),

          // Draw bounding boxes
          if (imageFile != null && yoloResults.isNotEmpty)
            CustomPaint(
              painter: YoloImageBoxPainter(
                results: yoloResults,
                imageW: imageWidth.toDouble(),
                imageH: imageHeight.toDouble(),
                screenW: screenSize.width,
                screenH: screenSize.height,
              ),
            ),

          // Buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _pickFromCamera,
                    child: const Text("Click Photo"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _runDetection,
                    child: const Text("Detect"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class YoloImageBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> results;
  final double imageW;
  final double imageH;
  final double screenW;
  final double screenH;

  YoloImageBoxPainter({
    required this.results,
    required this.imageW,
    required this.imageH,
    required this.screenW,
    required this.screenH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty) return;

    final boxPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final bgPaint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.7)
      ..style = PaintingStyle.fill;

    // Keep aspect ratio like the example
    final factorX = screenW / imageW;
    final imgRatio = imageW / imageH;
    final newW = imageW * factorX;
    final newH = newW / imgRatio;
    final factorY = newH / imageH;
    final pady = (screenH - newH) / 2;

    for (final r in results) {
      final List box = r['box']; // [x1,y1,x2,y2,conf]
      final String tag = r['tag'];
      final double conf = (box[4] as double) * 100;

      final left = box[0] * factorX;
      final top = box[1] * factorY + pady;
      final right = box[2] * factorX;
      final bottom = box[3] * factorY;

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), boxPaint);

      final span = TextSpan(
        text: '$tag ${conf.toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();

      const padH = 4.0;
      const padV = 2.0;
      final bgRect = Rect.fromLTWH(
        left,
        top - tp.height - 4,
        tp.width + padH * 2,
        tp.height + padV * 2,
      );

      canvas.drawRect(bgRect, bgPaint);
      tp.paint(canvas, Offset(bgRect.left + padH, bgRect.top + padV));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}