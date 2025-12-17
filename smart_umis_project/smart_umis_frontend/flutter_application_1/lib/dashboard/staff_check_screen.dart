import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;

class StaffCheckScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const StaffCheckScreen({super.key, required this.userData});

  @override
  State<StaffCheckScreen> createState() => _StaffCheckScreenState();
}

class _StaffCheckScreenState extends State<StaffCheckScreen> {
  final String apiUrl = 'http://10.140.66.28:5000/api';

  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedSection;

  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  bool _hasSearched = false;

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
    if (widget.userData['role'] != 'Staff') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAccessDeniedDialog();
      });
    }
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Access Denied'),
          ],
        ),
        content: const Text(
          'This page is only accessible to Staff members.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Go Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _searchStudents() async {
    if (_selectedDepartment == null ||
        _selectedYear == null ||
        _selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select department, year, and section'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '$apiUrl/staff/students?department=$_selectedDepartment&year=$_selectedYear&section=$_selectedSection'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _students = List<Map<String, dynamic>>.from(data['students']);
          _hasSearched = true;
        });
      } else {
        final error = jsonDecode(response.body);
        _showError(error['message'] ?? 'Failed to fetch students');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Connection error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _viewStudentDetails(int studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailsScreen(
          studentId: studentId,
          apiUrl: apiUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userData['role'] != 'Staff') {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'Staff Check - Student Records',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Staff Access Portal',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Welcome, ${widget.userData['fullName']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.filter_list, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text(
                          'Filter Students',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Department',
                      value: _selectedDepartment,
                      items: departments,
                      onChanged: (value) =>
                          setState(() => _selectedDepartment = value),
                      icon: Icons.school,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Year',
                      value: _selectedYear,
                      items: years,
                      onChanged: (value) =>
                          setState(() => _selectedYear = value),
                      icon: Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Section',
                      value: _selectedSection,
                      items: sections,
                      onChanged: (value) =>
                          setState(() => _selectedSection = value),
                      icon: Icons.class_,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _searchStudents,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Search Students',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Results Section
              if (_hasSearched)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Student List',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_students.length} Students',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_students.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No students found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _students.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2E7D32),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                student['fullName'] ??
                                    student['studentNameCertificate'] ??
                                    'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'ID: ${student['id']} • ${student['department']}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF2E7D32),
                              ),
                              onTap: () => _viewStudentDetails(student['id']),
                            );
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text('Select $label'),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Text(item),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// STUDENT DETAILS SCREEN - FIXED VERSION
// ============================================
class StudentDetailsScreen extends StatefulWidget {
  final int studentId;
  final String apiUrl;

  const StudentDetailsScreen({
    super.key,
    required this.studentId,
    required this.apiUrl,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentDetails();
  }

  Future<void> _loadStudentDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/staff/students/${widget.studentId}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _studentData = data['student'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load student details');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _copyAllDetails() {
    if (_studentData == null) return;

    final allDetails = '''
COMPLETE STUDENT DETAILS
========================

BASIC INFORMATION:
------------------
Student ID: ${_studentData!['id']}
Salutation: ${_studentData!['salutation'] ?? 'N/A'}
Student Name (Certificate): ${_studentData!['studentNameCertificate'] ?? _studentData!['fullName'] ?? 'N/A'}
Student Name (Aadhaar): ${_studentData!['studentNameAadhaar'] ?? 'N/A'}
Full Name: ${_studentData!['fullName'] ?? 'N/A'}

ACADEMIC DETAILS:
-----------------
Department: ${_studentData!['department'] ?? 'N/A'}
Year: ${_studentData!['year'] ?? 'N/A'}
Section: ${_studentData!['section'] ?? 'N/A'}

PERSONAL DETAILS:
-----------------
Nationality: ${_studentData!['nationality'] ?? 'N/A'}
Gender: ${_studentData!['gender'] ?? 'N/A'}
Date of Birth: ${_studentData!['dateOfBirth'] ?? 'N/A'}
Blood Group: ${_studentData!['bloodGroup'] ?? 'N/A'}
Religion: ${_studentData!['religion'] ?? 'N/A'}
Community: ${_studentData!['community'] ?? 'N/A'}
Caste: ${_studentData!['caste'] ?? 'N/A'}

IDENTIFICATION:
---------------
Aadhaar Number: ${_studentData!['aadhaarNumber'] ?? 'N/A'}
Community Certificate Number: ${_studentData!['communityCertificateNumber'] ?? 'N/A'}

FAMILY DETAILS:
---------------
Father's Name: ${_studentData!['fatherName'] ?? 'N/A'}
Father's Occupation: ${_studentData!['fatherOccupation'] ?? 'N/A'}
Mother's Name: ${_studentData!['motherName'] ?? 'N/A'}
Mother's Occupation: ${_studentData!['motherOccupation'] ?? 'N/A'}

FIRST GRADUATE STATUS:
----------------------
Is First Graduate: ${_studentData!['isFirstGraduate'] ?? 'N/A'}
First Graduate Certificate Number: ${_studentData!['firstGraduateCertificateNumber'] ?? 'N/A'}

RECORD INFORMATION:
-------------------
Entered By: ${_studentData!['enteredBy'] ?? 'N/A'}
Created At: ${_studentData!['createdAt'] ?? 'N/A'}
Updated At: ${_studentData!['updatedAt'] ?? 'N/A'}

UPLOADED DOCUMENTS:
-------------------
12th Marksheet: ${_studentData!['marksheetFileName'] ?? 'Not uploaded'}
Aadhaar Certificate: ${_studentData!['aadhaarFileName'] ?? 'Not uploaded'}
PAN Card Certificate: ${_studentData!['panCardFileName'] ?? 'Not uploaded'}
''';

    Clipboard.setData(ClipboardData(text: allDetails));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ All details copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadDocument(String documentType) async {
    if (_studentData == null) return;

    String? base64Data;
    String? fileName;

    switch (documentType) {
      case '12th Marksheet':
        base64Data = _studentData!['marksheetFile'];
        fileName = _studentData!['marksheetFileName'];
        break;
      case 'Aadhar Certificate':
        base64Data = _studentData!['aadhaarFile'];
        fileName = _studentData!['aadhaarFileName'];
        break;
      case 'PAN Card Certificate':
        base64Data = _studentData!['panCardFile'];
        fileName = _studentData!['panCardFileName'];
        break;
    }

    if (base64Data == null || fileName == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$documentType not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final bytes = base64Decode(base64Data);

      if (kIsWeb) {
        await _downloadForWeb(bytes, fileName);
      } else {
        await _downloadForMobile(bytes, fileName);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ $documentType downloaded successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadForWeb(List<int> bytes, String fileName) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _downloadForMobile(List<int> bytes, String fileName) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission denied'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String directory;
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      directory = '${dir!.path.split('Android')[0]}Download';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      directory = dir.path;
    }

    final file = File('$directory/$fileName');
    await file.writeAsBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'Complete Student Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all, color: Colors.white),
            onPressed: _studentData != null ? _copyAllDetails : null,
            tooltip: 'Copy All Details',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentData == null
              ? const Center(child: Text('Failed to load student details'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Student Header Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _studentData!['fullName'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Student ID: ${_studentData!['id']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildDetailCard('Academic Information', Icons.school, [
                          _buildDetailRow('Department',
                              _studentData!['department'] ?? 'N/A'),
                          _buildDetailRow(
                              'Year', _studentData!['year'] ?? 'N/A'),
                          _buildDetailRow(
                              'Section', _studentData!['section'] ?? 'N/A'),
                        ]),
                        const SizedBox(height: 16),

                        _buildDetailCard('Personal Information', Icons.person, [
                          _buildDetailRow('Salutation',
                              _studentData!['salutation'] ?? 'N/A'),
                          _buildDetailRow(
                              'Student Name (Certificate)',
                              _studentData!['studentNameCertificate'] ??
                                  _studentData!['fullName'] ??
                                  'N/A'),
                          _buildDetailRow('Student Name (Aadhaar)',
                              _studentData!['studentNameAadhaar'] ?? 'N/A'),
                          _buildDetailRow('Nationality',
                              _studentData!['nationality'] ?? 'N/A'),
                          _buildDetailRow(
                              'Gender', _studentData!['gender'] ?? 'N/A'),
                          _buildDetailRow('Date of Birth',
                              _studentData!['dateOfBirth'] ?? 'N/A'),
                          _buildDetailRow('Blood Group',
                              _studentData!['bloodGroup'] ?? 'N/A'),
                          _buildDetailRow(
                              'Religion', _studentData!['religion'] ?? 'N/A'),
                          _buildDetailRow(
                              'Community', _studentData!['community'] ?? 'N/A'),
                          _buildDetailRow(
                              'Caste', _studentData!['caste'] ?? 'N/A'),
                        ]),
                        const SizedBox(height: 16),

                        _buildDetailCard(
                            'Identification Details', Icons.badge, [
                          _buildDetailRow('Aadhaar Number',
                              _studentData!['aadhaarNumber'] ?? 'N/A'),
                          _buildDetailRow(
                              'Community Certificate Number',
                              _studentData!['communityCertificateNumber'] ??
                                  'N/A'),
                        ]),
                        const SizedBox(height: 16),

                        _buildDetailCard(
                            'Family Information', Icons.family_restroom, [
                          _buildDetailRow('Father Name',
                              _studentData!['fatherName'] ?? 'N/A'),
                          _buildDetailRow("Father's Occupation",
                              _studentData!['fatherOccupation'] ?? 'N/A'),
                          _buildDetailRow('Mother Name',
                              _studentData!['motherName'] ?? 'N/A'),
                          _buildDetailRow("Mother's Occupation",
                              _studentData!['motherOccupation'] ?? 'N/A'),
                        ]),
                        const SizedBox(height: 16),

                        _buildDetailCard(
                            'First Graduate Status', Icons.school_outlined, [
                          _buildDetailRow('Is First Graduate',
                              _studentData!['isFirstGraduate'] ?? 'N/A'),
                          if (_studentData!['isFirstGraduate'] == 'Yes')
                            _buildDetailRow(
                                'First Graduate Certificate Number',
                                _studentData![
                                        'firstGraduateCertificateNumber'] ??
                                    'N/A'),
                        ]),
                        const SizedBox(height: 16),

                        _buildDocumentCard(),
                        const SizedBox(height: 16),

                        _buildDetailCard('Record Information', Icons.info, [
                          _buildDetailRow('Entered By',
                              _studentData!['enteredBy'] ?? 'N/A'),
                          _buildDetailRow('Created At',
                              _studentData!['createdAt'] ?? 'N/A'),
                          _buildDetailRow('Updated At',
                              _studentData!['updatedAt'] ?? 'N/A'),
                        ]),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _copyAllDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon:
                                const Icon(Icons.copy_all, color: Colors.white),
                            label: const Text(
                              'Copy All Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDetailCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDocumentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.folder_open, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Uploaded Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDocumentItem(
            '12th Marksheet',
            _studentData!['marksheetFileName'],
            _studentData!['marksheetFile'] != null,
          ),
          const SizedBox(height: 12),
          _buildDocumentItem(
            'Aadhar Certificate',
            _studentData!['aadhaarFileName'],
            _studentData!['aadhaarFile'] != null,
          ),
          const SizedBox(height: 12),
          _buildDocumentItem(
            'PAN Card Certificate',
            _studentData!['panCardFileName'],
            _studentData!['panCardFile'] != null,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
      String documentName, String? fileName, bool hasFile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasFile ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFile ? Colors.green : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasFile ? Icons.check_circle : Icons.cancel,
            color: hasFile ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasFile && fileName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else
                  Text(
                    'Not uploaded',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (hasFile) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _downloadDocument(documentName),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(
                kIsWeb ? Icons.cloud_download : Icons.download,
                size: 18,
              ),
              label: const Text(kIsWeb ? 'Download' : 'Save'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  color: const Color(0xFF2E7D32),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _copyToClipboard(value, label),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
