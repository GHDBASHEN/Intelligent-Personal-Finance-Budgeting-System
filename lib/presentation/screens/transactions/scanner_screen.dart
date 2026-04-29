import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine a responsive size for the scan window
    final scanWindowSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Product Barcode')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera view
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture capture) {
              if (_hasScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? barcode = barcodes.first.rawValue;
                if (barcode != null && barcode.isNotEmpty) {
                  _hasScanned = true;
                  Navigator.of(context).pop(barcode);
                }
              }
            },
          ),
          
          // Blurred and darkened overlay with a cutout hole
          ClipPath(
            clipper: _ScannerOverlayClipper(
              scanWindowSize: scanWindowSize,
              borderRadius: 24.0,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          
          // White border framing the cutout
          Center(
            child: Container(
              width: scanWindowSize,
              height: scanWindowSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3.0),
                borderRadius: BorderRadius.circular(24.0),
              ),
            ),
          ),
          
          // Instructional text at the bottom
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: const Text(
              'Align barcode within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayClipper extends CustomClipper<Path> {
  final double scanWindowSize;
  final double borderRadius;

  _ScannerOverlayClipper({
    required this.scanWindowSize,
    required this.borderRadius,
  });

  @override
  Path getClip(Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutOutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    // Using evenOdd fill type creates a hole where the inner and outer paths overlap
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)));
  }

  @override
  bool shouldReclip(covariant _ScannerOverlayClipper oldClipper) {
    return oldClipper.scanWindowSize != scanWindowSize ||
        oldClipper.borderRadius != borderRadius;
  }
}
