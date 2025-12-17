// ============================================
// FILE 1: student_qr_verification_page.dart
// Student QR Verification with Camera + Gallery Scanning
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';

// Import shared components
import 'qr_camera_scanner_page.dart';
import 'student_details_page.dart';

class QRVerificationPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const QRVerificationPage({super.key, required this.userData});

  @override
  State<QRVerificationPage> createState() => _QRVerificationPageState();
}

class _QRVerificationPageState extends State<QRVerificationPage> {
  final String apiUrl = 'http://10.140.66.28:5000/api';
  List<dynamic> students = [];
  bool isLoading = true;
  String? errorMessage;
  bool hasAccess = true;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  void _checkAccessAndLoad() {
    final userRole = widget.userData['role']?.toString().toLowerCase() ?? '';

    if (userRole != 'student') {
      setState(() {
        hasAccess = false;
        isLoading = false;
        errorMessage =
            'Access Denied: This page is only accessible to students';
      });
      return;
    }

    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$apiUrl/getAllQRCodes'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          students = data is List ? data : [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load students';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _navigateToStudentDetails(int studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentDetailsPage(
          studentId: studentId,
          apiUrl: apiUrl,
        ),
      ),
    );
  }

  void _showQRScannerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan QR Code',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose scanning method',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            // Camera Scanner Option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _openCameraScanner();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E7D32), width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan with Camera',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Open camera to scan QR code in real-time',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Color(0xFF2E7D32), size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Gallery Upload Option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _pickImageAndScan();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.blue[700], shape: BoxShape.circle),
                      child: const Icon(Icons.photo_library,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Upload from Gallery',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Select QR code image from your device',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.blue, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openCameraScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCameraScannerPage(
          apiUrl: apiUrl,
          onScanned: (studentId) => _navigateToStudentDetails(studentId),
        ),
      ),
    );
  }

  // ========== FIXED: Gallery Image QR Scanner ==========
  Future<void> _pickImageAndScan() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) return; // User cancelled

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Card(
              margin: const EdgeInsets.all(40),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    const SizedBox(height: 20),
                    const Text('Scanning QR Code...',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Please wait',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      try {
        // Use the image path directly with QrCodeToolsPlugin
        final result = await QrCodeToolsPlugin.decodeFrom(image.path);

        if (mounted) Navigator.pop(context); // Close loading

        if (result != null && result.isNotEmpty) {
          // Try to parse as JSON first (for full QR data)
          try {
            final qrData = jsonDecode(result);
            final studentId = qrData['id'];

            if (studentId != null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('✓ QR Code Scanned Successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              _navigateToStudentDetails(studentId);
              return;
            }
          } catch (e) {
            // If JSON parsing fails, try as plain student ID
            try {
              final studentId = int.parse(result);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('✓ QR Code Scanned Successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              _navigateToStudentDetails(studentId);
              return;
            } catch (e) {
              _showErrorDialog('Invalid QR Code format: $result');
              return;
            }
          }
        } else {
          _showErrorDialog(
              'No QR code detected in the image.\n\nPlease make sure:\n• The QR code is clearly visible\n• The image is not blurry\n• The QR code takes up most of the image');
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); // Close loading if still open
        _showErrorDialog(
            'Error scanning image: ${e.toString()}\n\nPlease try:\n• Taking a clearer photo\n• Using the camera scanner instead');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error selecting image: ${e.toString()}');
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Scan Failed'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(
                    color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQRCode(
      String qrCodeBase64, String studentName, int studentId) async {
    try {
      final base64Data = qrCodeBase64.contains(',')
          ? qrCodeBase64.split(',').last
          : qrCodeBase64;
      final bytes = base64Decode(base64Data);

      if (kIsWeb) {
        _downloadForWeb(bytes, studentName, studentId);
      } else {
        await _downloadForMobile(bytes, studentName, studentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to download: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  void _downloadForWeb(List<int> bytes, String studentName, int studentId) {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement;
      anchor.href = url;
      anchor.download = 'QR_${studentName}_ID$studentId.png';
      anchor.style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✓ QR Code downloaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3)),
      );
    }
  }

  Future<void> _downloadForMobile(
      List<int> bytes, String studentName, int studentId) async {
    try {
      if (await Permission.storage.request().isGranted ||
          await Permission.photos.request().isGranted) {
        final result = await ImageGallerySaverPlus.saveImage(
            Uint8List.fromList(bytes),
            quality: 100,
            name: 'QR_${studentName}_ID$studentId');
        if (mounted) {
          if (result['isSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('✓ QR Code saved: ${studentName}_ID$studentId.png'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Failed to save QR code'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2)),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Storage permission denied'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving QR code: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasAccess) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          title: const Text('Student QR Verification',
              style: TextStyle(color: Colors.white)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.orange[700]),
                const SizedBox(height: 24),
                Text('Access Denied',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700])),
                const SizedBox(height: 16),
                Text(
                    errorMessage ??
                        'You do not have permission to access this page',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('QR Verification (Student)',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // Scan QR Code Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner,
                        color: Color(0xFF2E7D32), size: 32),
                    SizedBox(width: 12),
                    Text('Scan QR Code',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Scan to view student details instantly',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showQRScannerOptions,
                    icon: const Icon(Icons.qr_code_scanner, size: 24),
                    label: const Text('Scan QR Code',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 8, color: Colors.grey[200]),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Row(
              children: [
                Icon(Icons.grid_view, color: Color(0xFF2E7D32), size: 20),
                SizedBox(width: 8),
                Text('Generated QR Codes',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Students Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 80, color: Colors.red),
                              const SizedBox(height: 20),
                              const Text('Error',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                              const SizedBox(height: 12),
                              Text(errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black87)),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _checkAccessAndLoad,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 16)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : students.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No students found',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600])),
                                const SizedBox(height: 8),
                                Text('No QR codes available at the moment',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[500])),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = constraints.maxWidth < 600
                                  ? 1
                                  : constraints.maxWidth < 900
                                      ? 2
                                      : 3;
                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: students.length,
                                itemBuilder: (context, index) =>
                                    _buildStudentCard(students[index]),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(dynamic student) {
    final studentId = student['id'] ?? 0;
    final studentName = student['studentNameCertificate'] ?? 'Unknown';
    final department = student['department'] ?? '';
    final year = student['year'] ?? '';
    final qrCode = student['qrCode'] ?? '';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (qrCode.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Image.memory(base64Decode(qrCode.split(',').last),
                    width: 110, height: 110, fit: BoxFit.contain),
              )
            else
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.qr_code, size: 50, color: Colors.grey),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16)),
              child: Text('ID: $studentId',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32))),
            ),
            const SizedBox(height: 10),
            Text(studentName,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(department,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Year: $year',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToStudentDetails(studentId),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _downloadQRCode(qrCode, studentName, studentId),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Save', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
