// ============================================
// FILE 3: qr_camera_scanner_page.dart
// Shared QR Camera Scanner for both Student and Staff
// ============================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCameraScannerPage extends StatefulWidget {
  final String apiUrl;
  final Function(int) onScanned;

  const QRCameraScannerPage({
    super.key,
    required this.apiUrl,
    required this.onScanned,
  });

  @override
  State<QRCameraScannerPage> createState() => _QRCameraScannerPageState();
}

class _QRCameraScannerPageState extends State<QRCameraScannerPage> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool isScanned = false;
  bool isFlashOn = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() => isScanned = true);

    try {
      final studentId = int.parse(barcode.rawValue!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ QR Code Scanned Successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      Navigator.pop(context);
      widget.onScanned(studentId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR Code format'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => isScanned = false);
    }
  }

  Future<void> _toggleFlash() async {
    await cameraController.toggleTorch();
    setState(() => isFlashOn = !isFlashOn);
  }

  Future<void> _switchCamera() async {
    await cameraController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleFlash,
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: _switchCamera,
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // Scanning Frame Overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner indicators (top-left)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.green, width: 6),
                          left: BorderSide(color: Colors.green, width: 6),
                        ),
                      ),
                    ),
                  ),
                  // Corner indicators (top-right)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.green, width: 6),
                          right: BorderSide(color: Colors.green, width: 6),
                        ),
                      ),
                    ),
                  ),
                  // Corner indicators (bottom-left)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.green, width: 6),
                          left: BorderSide(color: Colors.green, width: 6),
                        ),
                      ),
                    ),
                  ),
                  // Corner indicators (bottom-right)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.green, width: 6),
                          right: BorderSide(color: Colors.green, width: 6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instructions Panel
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The code will be scanned automatically',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
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
