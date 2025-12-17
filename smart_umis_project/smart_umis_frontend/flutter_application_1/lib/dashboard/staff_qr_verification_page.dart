// ============================================
// FILE 2: staff_qr_verification_page.dart
// Staff QR Verification with View and Download Only
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// Import shared components
import 'student_details_page.dart';

class StaffQRVerificationPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const StaffQRVerificationPage({super.key, required this.userData});

  @override
  State<StaffQRVerificationPage> createState() =>
      _StaffQRVerificationPageState();
}

class _StaffQRVerificationPageState extends State<StaffQRVerificationPage> {
  final String apiUrl = 'http://10.140.66.28:5000/api';
  List<dynamic> students = [];
  bool isLoading = false;
  String? errorMessage;
  bool hasAccess = true;

  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedSection;

  final List<String> departments = [
    'CSI - Computer Science',
    'ECE - Electronics',
    'VS - Visual Communication',
    'MECH - Mechanical',
    'CIVIL - Civil Engineering',
    'EEE - Electrical Engineering',
  ];

  final List<String> years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> sections = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    final userRole = widget.userData['role']?.toString().toLowerCase() ?? '';

    if (userRole != 'staff') {
      setState(() {
        hasAccess = false;
        errorMessage =
            'Access Denied: This page is only accessible to staff members';
      });
    }
  }

  Future<void> _loadFilteredStudents() async {
    if (_selectedDepartment == null ||
        _selectedYear == null ||
        _selectedSection == null) {
      setState(() {
        errorMessage = 'Please select all filters';
        students = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '$apiUrl/staff/students?department=$_selectedDepartment&year=$_selectedYear&section=$_selectedSection'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final studentsData = data['students'] as List;
        final List<dynamic> studentsWithQR = [];

        for (var student in studentsData) {
          try {
            final qrResponse = await http
                .get(Uri.parse('$apiUrl/getQRCodes/${student['id']}'));

            if (qrResponse.statusCode == 200) {
              final qrData = jsonDecode(qrResponse.body);
              studentsWithQR.add({
                ...student,
                'qrCode': qrData['qrCode'],
              });
            } else {
              studentsWithQR.add(student);
            }
          } catch (e) {
            studentsWithQR.add(student);
          }
        }

        setState(() {
          students = studentsWithQR;
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
        errorMessage = 'Error: $e';
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
              const SnackBar(
                  content: Text('✓ QR Code saved to gallery successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2)),
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
          title: const Text('Staff QR Verification',
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
        title: const Text('Staff QR Verification',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // Filter Section (Fixed at top)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.filter_list, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Text('Filter Students',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Department *',
                  value: _selectedDepartment,
                  hint: 'Select Department',
                  items: departments,
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                      students = [];
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Year *',
                        value: _selectedYear,
                        hint: 'Year',
                        items: years,
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                            students = [];
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Section *',
                        value: _selectedSection,
                        hint: 'Section',
                        items: sections,
                        onChanged: (value) {
                          setState(() {
                            _selectedSection = value;
                            students = [];
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadFilteredStudents,
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text('Search Students',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey[300]),
          // Results Section (Scrollable)
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2E7D32)),
                        SizedBox(height: 16),
                        Text('Loading students...',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  )
                : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 80, color: Colors.orange[400]),
                              const SizedBox(height: 20),
                              Text(errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )
                    : students.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search,
                                    size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 20),
                                Text('No students found',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('Try different filter options',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 14)),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                color: Colors.white,
                                child: Row(
                                  children: [
                                    const Icon(Icons.people,
                                        color: Color(0xFF2E7D32), size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                        '${students.length} Student${students.length != 1 ? 's' : ''} Found',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    int crossAxisCount =
                                        constraints.maxWidth < 600
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
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: const TextStyle(fontSize: 14)),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: items.map((item) {
                return DropdownMenuItem(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(dynamic student) {
    final studentId = student['id'] ?? 0;
    final studentName = student['studentNameCertificate'] ?? 'Unknown';
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
