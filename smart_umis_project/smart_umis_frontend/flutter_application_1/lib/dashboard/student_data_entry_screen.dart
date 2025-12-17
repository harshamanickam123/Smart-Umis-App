// ============================================
// FIXED STUDENT DATA ENTRY SCREEN
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'qr_verification_screen.dart';

class StudentDataEntryScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const StudentDataEntryScreen({super.key, required this.userData});

  @override
  State<StudentDataEntryScreen> createState() => _StudentDataEntryScreenState();
}

class _StudentDataEntryScreenState extends State<StudentDataEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _studentNameCertificateController = TextEditingController();
  final _studentNameAadhaarController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _casteController = TextEditingController();
  final _motherOccupationController = TextEditingController();
  final _fatherOccupationController = TextEditingController();
  final _communityCertificateNumberController = TextEditingController();
  final _aadhaarNumberController = TextEditingController();
  final _firstGraduateCertificateController = TextEditingController();

  // Dropdown values
  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedSection;
  String? _selectedSalutation;
  String? _selectedNationality;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedReligion;
  String? _selectedCommunity;
  String? _isFirstGraduate;

  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;

  // File upload variables
  String? _marksheetFileBase64;
  String? _aadhaarFileBase64;
  String? _panCardFileBase64;
  String? _marksheetFileName;
  String? _aadhaarFileName;
  String? _panCardFileName;

  // Dropdown options
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
  final List<String> salutations = ['Mr', 'Ms'];
  final List<String> nationalities = ['Indian', 'Others'];
  final List<String> genders = ['Male', 'Female', 'Transgender'];
  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  final List<String> religions = [
    'Hindu',
    'Muslim',
    'Christian',
    'Sikh',
    'Buddhist',
    'Jain',
    'Others'
  ];
  final List<String> communities = [
    'OC',
    'BC',
    'BCM',
    'MBC',
    'SC',
    'SCA',
    'ST'
  ];
  final List<String> yesNoOptions = ['Yes', 'No'];

  final String apiUrl = 'http://10.140.66.28:5000/api';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _pickFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        final fileName = result.files.first.name;

        if (bytes == null) {
          if (mounted) {
            _showError('Could not read file');
          }
          return;
        }

        // Check file size (max 5MB)
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            _showError('File size should not exceed 5MB');
          }
          return;
        }

        String base64File = base64Encode(bytes);

        setState(() {
          if (documentType == '12th Marksheet') {
            _marksheetFileBase64 = base64File;
            _marksheetFileName = fileName;
          } else if (documentType == 'Aadhar Certificate') {
            _aadhaarFileBase64 = base64File;
            _aadhaarFileName = fileName;
          } else if (documentType == 'PAN Card Certificate') {
            _panCardFileBase64 = base64File;
            _panCardFileName = fileName;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$documentType uploaded: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error picking file: ${e.toString()}');
      }
    }
  }

  void _removeFile(String documentType) {
    setState(() {
      if (documentType == '12th Marksheet') {
        _marksheetFileBase64 = null;
        _marksheetFileName = null;
      } else if (documentType == 'Aadhar Certificate') {
        _aadhaarFileBase64 = null;
        _aadhaarFileName = null;
      } else if (documentType == 'PAN Card Certificate') {
        _panCardFileBase64 = null;
        _panCardFileName = null;
      }
    });
  }

  Future<void> _submitData() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill all required text fields correctly');
      return;
    }

    // Create list of missing fields for better error message
    List<String> missingFields = [];

    if (_selectedDepartment == null) missingFields.add('Department');
    if (_selectedYear == null) missingFields.add('Year');
    if (_selectedSection == null) missingFields.add('Section');
    if (_selectedSalutation == null) missingFields.add('Salutation');
    if (_selectedNationality == null) missingFields.add('Nationality');
    if (_selectedGender == null) missingFields.add('Gender');
    if (_selectedBloodGroup == null) missingFields.add('Blood Group');
    if (_selectedReligion == null) missingFields.add('Religion');
    if (_selectedCommunity == null) missingFields.add('Community');
    if (_isFirstGraduate == null) missingFields.add('First Graduate Status');
    if (_selectedDateOfBirth == null) missingFields.add('Date of Birth');

    // Check text fields
    if (_studentNameCertificateController.text.trim().isEmpty) {
      missingFields.add('Student Name (Certificate)');
    }
    if (_studentNameAadhaarController.text.trim().isEmpty) {
      missingFields.add('Student Name (Aadhaar)');
    }
    if (_fatherNameController.text.trim().isEmpty) {
      missingFields.add('Father Name');
    }
    if (_motherNameController.text.trim().isEmpty) {
      missingFields.add('Mother Name');
    }
    if (_fatherOccupationController.text.trim().isEmpty) {
      missingFields.add('Father Occupation');
    }
    if (_motherOccupationController.text.trim().isEmpty) {
      missingFields.add('Mother Occupation');
    }
    if (_casteController.text.trim().isEmpty) {
      missingFields.add('Caste');
    }
    if (_aadhaarNumberController.text.trim().isEmpty) {
      missingFields.add('Aadhaar Number');
    }

    if (missingFields.isNotEmpty) {
      _showError(
          'Please fill the following required fields:\n${missingFields.join(', ')}');
      return;
    }

    // Validate Aadhaar number format
    if (_aadhaarNumberController.text.trim().length != 12) {
      _showError('Aadhaar number must be exactly 12 digits');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final requestBody = {
        'department': _selectedDepartment,
        'year': _selectedYear,
        'section': _selectedSection,
        'salutation': _selectedSalutation,
        'studentNameCertificate': _studentNameCertificateController.text.trim(),
        'studentNameAadhaar': _studentNameAadhaarController.text.trim(),
        // Add fullName for backend compatibility
        'fullName': _studentNameCertificateController.text.trim(),
        'nationality': _selectedNationality,
        'gender': _selectedGender,
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
        'bloodGroup': _selectedBloodGroup,
        'religion': _selectedReligion,
        'community': _selectedCommunity,
        'communityCertificateNumber':
            _communityCertificateNumberController.text.trim(),
        'caste': _casteController.text.trim(),
        'aadhaarNumber': _aadhaarNumberController.text.trim(),
        'isFirstGraduate': _isFirstGraduate,
        'firstGraduateCertificateNumber':
            _firstGraduateCertificateController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'motherName': _motherNameController.text.trim(),
        'motherOccupation': _motherOccupationController.text.trim(),
        'fatherOccupation': _fatherOccupationController.text.trim(),
        'enteredBy': widget.userData['username'],
        // PDF files as base64
        'marksheetFile': _marksheetFileBase64,
        'marksheetFileName': _marksheetFileName,
        'aadhaarFile': _aadhaarFileBase64,
        'aadhaarFileName': _aadhaarFileName,
        'panCardFile': _panCardFileBase64,
        'panCardFileName': _panCardFileName,
      };

      debugPrint('Sending request with data: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
        Uri.parse('$apiUrl/students/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout - Please check your server');
        },
      );

      setState(() => _isLoading = false);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int? studentId = data['studentId'] ?? data['student']?['id'];

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Student data saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;

            if (studentId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QRVerificationScreen(
                    studentId: studentId,
                    apiUrl: apiUrl,
                  ),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          });

          _clearForm();
        }
      } else {
        final error = jsonDecode(response.body);
        _showError(error['message'] ??
            'Failed to save data. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: ${e.toString()}');
      debugPrint('Error details: $e');
    }
  }

  void _clearForm() {
    _studentNameCertificateController.clear();
    _studentNameAadhaarController.clear();
    _fatherNameController.clear();
    _motherNameController.clear();
    _casteController.clear();
    _motherOccupationController.clear();
    _fatherOccupationController.clear();
    _communityCertificateNumberController.clear();
    _aadhaarNumberController.clear();
    _firstGraduateCertificateController.clear();

    setState(() {
      _selectedDepartment = null;
      _selectedYear = null;
      _selectedSection = null;
      _selectedSalutation = null;
      _selectedNationality = null;
      _selectedGender = null;
      _selectedBloodGroup = null;
      _selectedReligion = null;
      _selectedCommunity = null;
      _isFirstGraduate = null;
      _selectedDateOfBirth = null;
      _marksheetFileBase64 = null;
      _aadhaarFileBase64 = null;
      _panCardFileBase64 = null;
      _marksheetFileName = null;
      _aadhaarFileName = null;
      _panCardFileName = null;
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'Student Data Entry',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Data Entry',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter and manage student details',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Department Dropdown
                _buildDropdown(
                  label: 'Choose Department *',
                  value: _selectedDepartment,
                  hint: 'Select Department',
                  items: departments,
                  onChanged: (value) =>
                      setState(() => _selectedDepartment = value),
                ),
                const SizedBox(height: 16),

                // Year and Section Row
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Year *',
                        value: _selectedYear,
                        hint: 'Year',
                        items: years,
                        onChanged: (value) =>
                            setState(() => _selectedYear = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Section *',
                        value: _selectedSection,
                        hint: 'Section',
                        items: sections,
                        onChanged: (value) =>
                            setState(() => _selectedSection = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Personal Details Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person_outline, color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Personal Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Salutation
                _buildDropdown(
                  label: 'Salutation *',
                  value: _selectedSalutation,
                  hint: 'Select Salutation',
                  items: salutations,
                  onChanged: (value) =>
                      setState(() => _selectedSalutation = value),
                ),
                const SizedBox(height: 16),

                // Student Name (As on Certificate)
                _buildTextField(
                  controller: _studentNameCertificateController,
                  label: 'Student Name (As on Certificate) *',
                  hint: 'Enter name as on certificate',
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                ),
                const SizedBox(height: 16),

                // Student Name (As on Aadhaar)
                _buildTextField(
                  controller: _studentNameAadhaarController,
                  label: 'Student Name (As on Aadhaar) *',
                  hint: 'Enter name as on Aadhaar',
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                ),
                const SizedBox(height: 16),

                // Nationality
                _buildDropdown(
                  label: 'Nationality *',
                  value: _selectedNationality,
                  hint: 'Select Nationality',
                  items: nationalities,
                  onChanged: (value) =>
                      setState(() => _selectedNationality = value),
                ),
                const SizedBox(height: 16),

                // Gender
                _buildDropdown(
                  label: 'Gender *',
                  value: _selectedGender,
                  hint: 'Select Gender',
                  items: genders,
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),
                const SizedBox(height: 16),

                // Date of Birth
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Date of Birth *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Color(0xFF2E7D32)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDateOfBirth == null
                                    ? 'Select Date of Birth'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_selectedDateOfBirth!),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedDateOfBirth == null
                                      ? Colors.grey[600]
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Blood Group
                _buildDropdown(
                  label: 'Blood Group *',
                  value: _selectedBloodGroup,
                  hint: 'Select Blood Group',
                  items: bloodGroups,
                  onChanged: (value) =>
                      setState(() => _selectedBloodGroup = value),
                ),
                const SizedBox(height: 16),

                // Religion
                _buildDropdown(
                  label: 'Religion *',
                  value: _selectedReligion,
                  hint: 'Select Religion',
                  items: religions,
                  onChanged: (value) =>
                      setState(() => _selectedReligion = value),
                ),
                const SizedBox(height: 16),

                // Community
                _buildDropdown(
                  label: 'Community *',
                  value: _selectedCommunity,
                  hint: 'Select Community',
                  items: communities,
                  onChanged: (value) =>
                      setState(() => _selectedCommunity = value),
                ),
                const SizedBox(height: 16),

                // Community Certificate Number
                _buildTextField(
                  controller: _communityCertificateNumberController,
                  label: 'Community Certificate Number',
                  hint: 'Enter community certificate number',
                  isRequired: false,
                ),
                const SizedBox(height: 16),

                // Caste
                _buildTextField(
                  controller: _casteController,
                  label: 'Caste *',
                  hint: 'Enter caste',
                ),
                const SizedBox(height: 16),

                // Aadhaar Number
                _buildTextField(
                  controller: _aadhaarNumberController,
                  label: 'Aadhaar Number *',
                  hint: 'Enter 12-digit Aadhaar number',
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 16),

                // First Graduate
                _buildDropdown(
                  label: 'Is the student the first graduate in the family? *',
                  value: _isFirstGraduate,
                  hint: 'Select Yes or No',
                  items: yesNoOptions,
                  onChanged: (value) =>
                      setState(() => _isFirstGraduate = value),
                ),
                const SizedBox(height: 16),

                // First Graduate Certificate Number (conditional)
                if (_isFirstGraduate == 'Yes') ...[
                  _buildTextField(
                    controller: _firstGraduateCertificateController,
                    label: 'First Graduate Certificate Number',
                    hint: 'Enter first graduate certificate number',
                    isRequired: false,
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),

                // Family Details Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.family_restroom, color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Family Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _fatherNameController,
                  label: 'Father Name *',
                  hint: 'Enter father name',
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _motherNameController,
                  label: 'Mother Name *',
                  hint: 'Enter Mother name',
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _fatherOccupationController,
                  label: "Father's Occupation *",
                  hint: "Enter father's occupation",
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _motherOccupationController,
                  label: "Mother's Occupation *",
                  hint: "Enter mother's occupation",
                ),
                const SizedBox(height: 24),

                // Document Upload Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.upload_file, color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Document Upload (PDF Only)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildDocumentUpload('12th Marksheet', _marksheetFileName),
                const SizedBox(height: 12),
                _buildDocumentUpload('Aadhar Certificate', _aadhaarFileName),
                const SizedBox(height: 12),
                _buildDocumentUpload('PAN Card Certificate', _panCardFileName),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Save & Submit Data',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            counterText: maxLength != null ? '' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  if (label.contains('Aadhaar Number') && value.length != 12) {
                    return 'Aadhaar number must be exactly 12 digits';
                  }
                  if (label.contains('Name') && value.trim().length < 2) {
                    return 'Please enter a valid name';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDocumentUpload(String documentName, String? fileName) {
    bool hasFile = fileName != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFile ? const Color(0xFF2E7D32) : Colors.grey[300]!,
          width: hasFile ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasFile ? Icons.check_circle : Icons.picture_as_pdf,
                color: hasFile ? const Color(0xFF2E7D32) : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      documentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasFile) ...[
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
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasFile)
                IconButton(
                  onPressed: () => _removeFile(documentName),
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Remove file',
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _pickFile(documentName),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _studentNameCertificateController.dispose();
    _studentNameAadhaarController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _casteController.dispose();
    _motherOccupationController.dispose();
    _fatherOccupationController.dispose();
    _communityCertificateNumberController.dispose();
    _aadhaarNumberController.dispose();
    _firstGraduateCertificateController.dispose();
    super.dispose();
  }
}
