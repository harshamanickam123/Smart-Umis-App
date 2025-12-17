// ============================================
// QR CODE VERIFICATION SCREEN - FIXED VERSION
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
// Conditional import for web
import 'package:universal_html/html.dart' as html;

class QRVerificationScreen extends StatefulWidget {
  final int studentId;
  final String apiUrl;

  const QRVerificationScreen({
    super.key,
    required this.studentId,
    required this.apiUrl,
  });

  @override
  State<QRVerificationScreen> createState() => _QRVerificationScreenState();
}

class _QRVerificationScreenState extends State<QRVerificationScreen> {
  Map<String, dynamic>? _studentData;
  String? _qrData;
  bool _isLoading = true;
  bool _showDetails = false;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/students/${widget.studentId}'),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle both direct data and nested 'student' object
        final studentInfo = data['student'] ?? data;

        setState(() {
          _studentData = studentInfo;
          _qrData = jsonEncode({
            'studentId': widget.studentId,
            'name': studentInfo['studentNameCertificate'] ??
                studentInfo['fullName'] ??
                'N/A',
            'department': studentInfo['department'] ?? 'N/A',
            'year': studentInfo['year'] ?? 'N/A',
            'section': studentInfo['section'] ?? 'N/A',
            'aadhaar': studentInfo['aadhaarNumber'] ?? 'N/A',
          });
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load student data');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading student data: ${e.toString()}');
      debugPrint('Error fetching student data: $e');
    }
  }

  Future<void> _copyQRData() async {
    if (_qrData != null) {
      await Clipboard.setData(ClipboardData(text: _qrData!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR data copied to clipboard!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<Uint8List?> _captureQRCode() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR code: $e');
      return null;
    }
  }

  Future<void> _shareQRCode() async {
    try {
      final pngBytes = await _captureQRCode();
      if (pngBytes == null) {
        _showError('Failed to capture QR code');
        return;
      }

      if (kIsWeb) {
        // For web: Try to use Web Share API if available, otherwise download
        try {
          final blob = html.Blob([pngBytes], 'image/png');
          final file = html.File([blob], 'student_qr_${widget.studentId}.png');

          final studentName = _studentData?['studentNameCertificate'] ??
              _studentData?['fullName'] ??
              'Student';
          final department = _studentData?['department'] ?? '';

          // Try to share using Web Share API
          try {
            final shareData = {
              'files': [file],
              'title': 'Student QR Code',
              'text': 'Student QR Code - $studentName\n'
                  'Department: $department\n'
                  'Student ID: ${widget.studentId}'
            };

            // Attempt to share
            await html.window.navigator.share(shareData);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR code shared successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (shareError) {
            // If share fails, fallback to download
            debugPrint('Web share not supported, using download: $shareError');
            _downloadForWeb(pngBytes);
          }
        } catch (e) {
          debugPrint('Web share error: $e');
          // Fallback to download
          _downloadForWeb(pngBytes);
        }
        return;
      }

      // For mobile platforms
      final tempDir = Directory.systemTemp;
      final fileName = 'student_qr_${widget.studentId}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      final studentName = _studentData?['studentNameCertificate'] ??
          _studentData?['fullName'] ??
          'Student';
      final department = _studentData?['department'] ?? '';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Student QR Code - $studentName\n'
            'Department: $department\n'
            'Student ID: ${widget.studentId}\n'
            'This QR code contains encrypted student information for secure verification.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code shared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError('Error sharing QR code: ${e.toString()}');
    }
  }

  void _downloadForWeb(Uint8List bytes) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'student_qr_${widget.studentId}.png';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR code downloaded successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _downloadQRCode() async {
    try {
      final pngBytes = await _captureQRCode();
      if (pngBytes == null) {
        _showError('Failed to capture QR code');
        return;
      }

      if (kIsWeb) {
        // For web platform
        _downloadForWeb(pngBytes);
        return;
      }

      // For mobile platforms
      String downloadPath;
      final fileName =
          'student_qr_${widget.studentId}_${DateTime.now().millisecondsSinceEpoch}.png';

      // Use system temp directory as fallback
      downloadPath = Directory.systemTemp.path;

      // Try to use Downloads folder for Android
      try {
        if (Platform.isAndroid) {
          // Try standard Downloads path
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            downloadPath = downloadsDir.path;
          }
        }
      } catch (e) {
        debugPrint('Could not access Downloads folder: $e');
      }

      final file = File('$downloadPath/$fileName');

      // Ensure directory exists and write file
      await file.parent.create(recursive: true);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR code saved successfully!\nLocation: ${file.path}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Error downloading QR code: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  String _getFieldValue(String field) {
    if (_studentData == null) return 'N/A';
    return _studentData![field]?.toString() ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'QR Code Verification',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Success Message
                    if (!_showDetails) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Student Data Saved Successfully!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'QR Code generated for verification',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // QR Code Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (!_showDetails) ...[
                            const Text(
                              'Student QR Code',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan this code for instant verification',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // QR Code with RepaintBoundary for capture
                          RepaintBoundary(
                            key: _qrKey,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFF2E7D32),
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _qrData != null
                                  ? QrImageView(
                                      data: _qrData!,
                                      version: QrVersions.auto,
                                      size: 280,
                                      backgroundColor: Colors.white,
                                    )
                                  : const SizedBox(
                                      height: 280,
                                      child: Center(
                                        child: Text('No QR data available'),
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Action Buttons - ONLY 3 BUTTONS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: Icons.copy,
                                label: 'Copy',
                                onTap: _copyQRData,
                              ),
                              _buildActionButton(
                                icon: Icons.share,
                                label: 'Share',
                                onTap: _shareQRCode,
                              ),
                              _buildActionButton(
                                icon: Icons.download,
                                label: 'Download',
                                onTap: _downloadQRCode,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Info Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This QR code contains encrypted student information for secure verification. Keep it safe and share only with authorized personnel.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Student Details (collapsible)
                    if (_studentData != null) ...[
                      InkWell(
                        onTap: _toggleDetails,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showDetails
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: const Color(0xFF2E7D32),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'View Student Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showDetails) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: const Color(0xFF2E7D32),
                                child: Text(
                                  (_getFieldValue('studentNameCertificate')
                                              .isNotEmpty &&
                                          _getFieldValue(
                                                  'studentNameCertificate') !=
                                              'N/A')
                                      ? _getFieldValue('studentNameCertificate')
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : (_getFieldValue('fullName')
                                                  .isNotEmpty &&
                                              _getFieldValue('fullName') !=
                                                  'N/A')
                                          ? _getFieldValue('fullName')
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : 'S',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getFieldValue('studentNameCertificate') !=
                                        'N/A'
                                    ? _getFieldValue('studentNameCertificate')
                                    : _getFieldValue('fullName'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Student ID: ${widget.studentId}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildDetailRow(
                                Icons.school,
                                'Department',
                                _getFieldValue('department'),
                              ),
                              _buildDetailRow(
                                Icons.calendar_today,
                                'Year',
                                _getFieldValue('year'),
                              ),
                              _buildDetailRow(
                                Icons.class_,
                                'Section',
                                _getFieldValue('section'),
                              ),
                              _buildDetailRow(
                                Icons.person,
                                'Father Name',
                                _getFieldValue('fatherName'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),

                    // Dashboard Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.popUntil(
                            context, (route) => route.isFirst),
                        icon: const Icon(Icons.home, color: Colors.white),
                        label: const Text(
                          'Go to Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
