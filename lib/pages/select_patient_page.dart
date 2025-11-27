import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'left_right.dart';

class SelectPatientPage extends StatefulWidget {
  final BluetoothDevice device;

  SelectPatientPage({required this.device});

  @override
  _SelectPatientPageState createState() => _SelectPatientPageState();
}

class _SelectPatientPageState extends State<SelectPatientPage> {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedPatient;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<File> _getPatientsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/patients.json');
  }

  Future<void> _loadPatients() async {
    try {
      final file = await _getPatientsFile();
      if (await file.exists()) {
        String contents = await file.readAsString();
        List<dynamic> jsonData = jsonDecode(contents);
        setState(() {
          _patients = jsonData.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
        print('Loaded ${_patients.length} patients');
      } else {
        setState(() {
          _patients = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading patients: $e');
      setState(() {
        _patients = [];
        _isLoading = false;
      });
    }
  }

  void _startMeasurement() {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navigate to LeftRight page with selected patient
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeftRight(
          device: widget.device,
          patientData: _selectedPatient!,
        ),
      ),
    );
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
                            'Select Patient',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0C4A5E),
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Choose patient for measurement',
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

              // Patient List
              Expanded(
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6A1B9A),
                  ),
                )
                    : _patients.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FBFC),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFFD5E3E8),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person_off_rounded,
                          size: 64,
                          color: Color(0xFFB0C4CE),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No Patients Found',
                        style: TextStyle(
                          color: Color(0xFF0C4A5E),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please add a patient first',
                        style: TextStyle(
                          color: Color(0xFF7A9AAA),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _patients.length,
                  itemBuilder: (context, index) {
                    final patient = _patients[index];
                    final isSelected = _selectedPatient != null &&
                        _selectedPatient!['id'] == patient['id'];
                    return _buildPatientCard(patient, isSelected);
                  },
                ),
              ),

              // Start Measurement Button
              if (_patients.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _startMeasurement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPatient != null
                            ? Color(0xFF6A1B9A)
                            : Color(0xFFB0C4CE),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Start Measurement',
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient, bool isSelected) {
    // Gender icon
    IconData genderIcon;
    Color genderColor;
    if (patient['gender'] == 'Male') {
      genderIcon = Icons.male_rounded;
      genderColor = Color(0xFF1976D2);
    } else if (patient['gender'] == 'Female') {
      genderIcon = Icons.female_rounded;
      genderColor = Color(0xFFE91E63);
    } else {
      genderIcon = Icons.transgender_rounded;
      genderColor = Color(0xFF6A1B9A);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Color(0xFF6A1B9A) : Color(0xFFE0E8EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Color(0xFF6A1B9A).withOpacity(0.2)
                : Color(0xFF0C7C9E).withOpacity(0.06),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPatient = patient;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Color(0xFF6A1B9A)
                          : Color(0xFFD5E3E8),
                      width: 2,
                    ),
                    color: isSelected ? Color(0xFF6A1B9A) : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                      : null,
                ),
                SizedBox(width: 12),

                // Patient icon
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [Color(0xFF6A1B9A), Color(0xFF8E24AA)]
                          : [Color(0xFFD5E3E8), Color(0xFFB0C4CE)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),

                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0C4A5E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(genderIcon, size: 14, color: genderColor),
                          SizedBox(width: 4),
                          Text(
                            patient['gender'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A9AAA),
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.height_rounded,
                              size: 14, color: Color(0xFF7A9AAA)),
                          SizedBox(width: 4),
                          Text(
                            '${patient['height']} cm',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A9AAA),
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.monitor_weight_outlined,
                              size: 14, color: Color(0xFF7A9AAA)),
                          SizedBox(width: 4),
                          Text(
                            '${patient['weight']} kg',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A9AAA),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
