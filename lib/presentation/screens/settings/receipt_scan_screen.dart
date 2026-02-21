import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: CameraPreview(_controller!),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final image = await _controller!.takePicture();
          // Simulated OCR / Result
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Receipt Captured: \${image.name}')),
          );
          Navigator.pop(context);
        },
        child: const Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
