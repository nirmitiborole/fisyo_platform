import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

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

  Future<void> _deletePatient(String id) async {
    try {
      // Remove patient from list
      _patients.removeWhere((patient) => patient['id'] == id);

      // Write updated list back to file
      final file = await _getPatientsFile();
      String jsonString = jsonEncode(_patients);
      await file.writeAsString(jsonString);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Patient deleted successfully'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error deleting patient: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting patient'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Delete Patient'),
        content: Text(
          'Are you sure you want to delete ${patient['name']}?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF7A9AAA)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePatient(patient['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
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
                            'Patient Reports',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0C4A5E),
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${_patients.length} patients registered',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5A7B8A),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Refresh button
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
                          Icons.refresh_rounded,
                          color: Color(0xFF6A1B9A),
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadPatients();
                        },
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
                          Icons.folder_open_rounded,
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
                        'Add patients to see them here',
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
                    return _buildPatientCard(patient);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    // Format date
    DateTime createdDate = DateTime.parse(patient['createdAt']);
    String formattedDate =
        '${createdDate.day}/${createdDate.month}/${createdDate.year}';

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
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFE0E8EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0C7C9E).withOpacity(0.06),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and delete button
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6A1B9A),
                        Color(0xFF8E24AA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['name'],
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0C4A5E),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Added on $formattedDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A9AAA),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded),
                  color: Colors.red,
                  onPressed: () => _showDeleteConfirmation(patient),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Patient details
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF8FBFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.height_rounded,
                          label: 'Height',
                          value: '${patient['height']} cm',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.monitor_weight_outlined,
                          label: 'Weight',
                          value: '${patient['weight']} kg',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildDetailItem(
                    icon: genderIcon,
                    label: 'Gender',
                    value: patient['gender'],
                    iconColor: genderColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor ?? Color(0xFF6A1B9A),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF7A9AAA),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF0C4A5E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
