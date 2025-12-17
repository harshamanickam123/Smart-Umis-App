// ============================================
// FILE 4: student_details_page.dart
// Shared Student Details Display for both Student and Staff
// ============================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentDetailsPage extends StatefulWidget {
  final int studentId;
  final String apiUrl;

  const StudentDetailsPage({
    super.key,
    required this.studentId,
    required this.apiUrl,
  });

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudentDetails();
  }

  Future<void> _loadStudentDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/students/${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          studentData = data['student'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load student details';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'Student Details',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 16),
                  Text(
                    'Loading student details...',
                    style: TextStyle(fontSize: 16),
                  ),
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
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadStudentDetails,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section with Avatar
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2E7D32),
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFF2E7D32),
                                child: Text(
                                  (studentData?['studentNameCertificate'] ??
                                          'S')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              studentData?['studentNameCertificate'] ??
                                  'Unknown',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Student ID: ${widget.studentId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Academic Details Section
                      _buildSection('Academic Details', [
                        _buildDetailRow(
                            'Department', studentData?['department']),
                        _buildDetailRow('Year', studentData?['year']),
                        _buildDetailRow('Section', studentData?['section']),
                      ]),
                      const SizedBox(height: 16),

                      // Personal Details Section
                      _buildSection('Personal Details', [
                        _buildDetailRow(
                            'Salutation', studentData?['salutation']),
                        _buildDetailRow('Name (As on Certificate)',
                            studentData?['studentNameCertificate']),
                        _buildDetailRow('Name (As on Aadhaar)',
                            studentData?['studentNameAadhaar']),
                        _buildDetailRow(
                            'Nationality', studentData?['nationality']),
                        _buildDetailRow('Gender', studentData?['gender']),
                        _buildDetailRow(
                            'Date of Birth', studentData?['dateOfBirth']),
                        _buildDetailRow(
                            'Blood Group', studentData?['bloodGroup']),
                        _buildDetailRow('Religion', studentData?['religion']),
                        _buildDetailRow('Community', studentData?['community']),
                        _buildDetailRow('Caste', studentData?['caste']),
                        _buildDetailRow(
                            'Aadhaar Number', studentData?['aadhaarNumber']),
                      ]),
                      const SizedBox(height: 16),

                      // Certificate Details Section
                      _buildSection('Certificate Details', [
                        _buildDetailRow('Community Certificate Number',
                            studentData?['communityCertificateNumber']),
                        _buildDetailRow(
                            'First Graduate', studentData?['isFirstGraduate']),
                        if (studentData?['isFirstGraduate'] == 'Yes')
                          _buildDetailRow('First Graduate Certificate Number',
                              studentData?['firstGraduateCertificateNumber']),
                      ]),
                      const SizedBox(height: 16),

                      // Family Details Section
                      _buildSection('Family Details', [
                        _buildDetailRow(
                            'Father Name', studentData?['fatherName']),
                        _buildDetailRow('Father Occupation',
                            studentData?['fatherOccupation']),
                        _buildDetailRow(
                            'Mother Name', studentData?['motherName']),
                        _buildDetailRow('Mother Occupation',
                            studentData?['motherOccupation']),
                      ]),
                      const SizedBox(height: 16),

                      // Contact Information Section
                      _buildSection('Contact Information', [
                        _buildDetailRow('Email', studentData?['email']),
                        _buildDetailRow(
                            'Mobile Number', studentData?['mobileNumber']),
                        _buildDetailRow('Address', studentData?['address']),
                      ]),
                      const SizedBox(height: 16),

                      // Uploaded Documents Section
                      _buildSection('Uploaded Documents', [
                        _buildDetailRow(
                            '12th Marksheet',
                            studentData?['marksheetFileName'] ??
                                'Not uploaded'),
                        _buildDetailRow('Aadhaar Certificate',
                            studentData?['aadhaarFileName'] ?? 'Not uploaded'),
                        _buildDetailRow('PAN Card',
                            studentData?['panCardFileName'] ?? 'Not uploaded'),
                      ]),
                      const SizedBox(height: 16),

                      // Entry Information Section
                      _buildSection('Entry Information', [
                        _buildDetailRow(
                            'Entered By', studentData?['enteredBy']),
                        _buildDetailRow(
                            'Created At', studentData?['createdAt']),
                      ]),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    final displayValue = value?.toString() ?? 'N/A';

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
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
