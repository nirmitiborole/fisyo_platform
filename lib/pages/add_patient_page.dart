import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class AddPatientPage extends StatefulWidget {
  @override
  _AddPatientPageState createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _selectedGender = 'Male';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<File> _getPatientsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/patients.json');
  }

  Future<List<Map<String, dynamic>>> _readPatients() async {
    try {
      final file = await _getPatientsFile();
      if (await file.exists()) {
        String contents = await file.readAsString();
        List<dynamic> jsonData = jsonDecode(contents);
        return jsonData.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error reading patients: $e');
      return [];
    }
  }

  Future<void> _writePatients(List<Map<String, dynamic>> patients) async {
    final file = await _getPatientsFile();
    String jsonString = jsonEncode(patients);
    await file.writeAsString(jsonString);
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      print('Starting to save patient...');

      // Create patient object
      Map<String, dynamic> patient = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text.trim(),
        'height': double.parse(_heightController.text.trim()),
        'weight': double.parse(_weightController.text.trim()),
        'gender': _selectedGender,
        'createdAt': DateTime.now().toIso8601String(),
      };
      print('Patient object created: $patient');

      // Read existing patients
      List<Map<String, dynamic>> patients = await _readPatients();
      print('Current patients count: ${patients.length}');

      // Add new patient
      patients.add(patient);

      // Write back to file
      await _writePatients(patients);
      print('Patient saved successfully');

      setState(() => _isSaving = false);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Patient added successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Clear form
        _nameController.clear();
        _heightController.clear();
        _weightController.clear();
        setState(() => _selectedGender = 'Male');
      }

    } catch (e, stackTrace) {
      print('Error saving patient: $e');
      print('Stack trace: $stackTrace');

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving patient: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEBF4F5),
              Color(0xFFF8FEFF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFFE0E8EB),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF0C7C9E),
                          size: 24,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Patient',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0C4A5E),
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Register new patient information',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5A7B8A),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),

                        // Patient Name
                        Text(
                          'Patient Name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0C4A5E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter patient name',
                            hintStyle: TextStyle(
                              color: Color(0xFFB0C4CE),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF6A1B9A),
                              size: 22,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFD5E3E8),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFF6A1B9A),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Color(0xFFF8FBFC),
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF0C4A5E),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter patient name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // Height
                        Text(
                          'Height (cm)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0C4A5E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Enter height in cm',
                            hintStyle: TextStyle(
                              color: Color(0xFFB0C4CE),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.height_rounded,
                              color: Color(0xFF6A1B9A),
                              size: 22,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFD5E3E8),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFF6A1B9A),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Color(0xFFF8FBFC),
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF0C4A5E),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter height';
                            }
                            if (double.tryParse(value.trim()) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // Weight
                        Text(
                          'Weight (kg)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0C4A5E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Enter weight in kg',
                            hintStyle: TextStyle(
                              color: Color(0xFFB0C4CE),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.monitor_weight_outlined,
                              color: Color(0xFF6A1B9A),
                              size: 22,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFD5E3E8),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFF6A1B9A),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Color(0xFFF8FBFC),
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF0C4A5E),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter weight';
                            }
                            if (double.tryParse(value.trim()) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // Gender
                        Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0C4A5E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8FBFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFFD5E3E8),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wc_rounded,
                                color: Color(0xFF6A1B9A),
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedGender,
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: Color(0xFF6A1B9A),
                                    ),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF0C4A5E),
                                    ),
                                    items: ['Male', 'Female', 'Other'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedGender = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _savePatient,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6A1B9A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Color(0xFFB0C4CE),
                            ),
                            child: _isSaving
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Save Patient',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
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
}
