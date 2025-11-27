import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'left_right.dart';
import 'add_patient_page.dart';
import 'reports_page.dart';
import 'select_patient_page.dart';

class BalanceBoardPage extends StatelessWidget {
  final BluetoothDevice device;

  BalanceBoardPage({required this.device});

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
                            'Balance Board',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0C4A5E),
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Stability and balance assessments',
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

              // Connected Device Info
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F9F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFFD4EFE0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6A1B9A),
                            Color(0xFF8E24AA),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.bluetooth_connected_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connected Device',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            device.name.isEmpty ? 'BLE Sensor' : device.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0C4A5E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                      size: 20,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Three Options
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildOptionCard(
                        context,
                        icon: Icons.monitor_heart_rounded,
                        title: 'Measure',
                        description: 'Left/Right movement assessment',
                        color: Color(0xFF8E24AA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SelectPatientPage(device: device),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      _buildOptionCard(
                        context,
                        icon: Icons.person_add_rounded,
                        title: 'Add Patients',
                        description: 'Register new patient information',
                        color: Color(0xFF6A1B9A),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddPatientPage(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      _buildOptionCard(
                        context,
                        icon: Icons.assessment_rounded,
                        title: 'Reports',
                        description: 'View patient assessment reports',
                        color: Color(0xFF8E24AA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportsPage(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.05),
          highlightColor: Color(0xFFF8FBFC),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0C4A5E),
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A9AAA),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFB0C4CE),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
