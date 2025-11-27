import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'MotionDetector.dart';
import 'shoulder_page.dart';
import 'wrist_page.dart';
import 'ankle_page.dart';
import 'fingers_page.dart';
import 'left_right.dart';

class ButtonsPage extends StatelessWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  ButtonsPage({
    required this.device,
    required this.characteristic,
  });

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
              // Professional Header
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
                            'Joint Assessment',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0C4A5E),
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Select body part for measurement',
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
                            Color(0xFF0C7C9E),
                            Color(0xFF1A9DBF),
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

              // Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.healing_rounded,
                      color: Color(0xFF0C7C9E),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Assessment Categories',
                      style: TextStyle(
                        color: Color(0xFF0C4A5E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Joint Options Grid
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildJointCard(
                        context,
                        icon: Icons.accessibility_new_rounded,
                        title: 'Shoulder',
                        description: 'Shoulder joint mobility test',
                        color: Color(0xFF0C7C9E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShoulderPage(device: device),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      _buildJointCard(
                        context,
                        icon: Icons.back_hand_rounded,
                        title: 'Wrist',
                        description: 'Wrist flexion and extension test',
                        color: Color(0xFF1A9DBF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WristPage(device: device),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      _buildJointCard(
                        context,
                        icon: Icons.directions_walk_rounded,
                        title: 'Ankle',
                        description: 'Ankle mobility assessment',
                        color: Color(0xFF0C7C9E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnklePage(device: device),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      _buildJointCard(
                        context,
                        icon: Icons.fingerprint_rounded,
                        title: 'Fingers',
                        description: 'Finger joint movement test',
                        color: Color(0xFF1A9DBF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FingersPage(device: device),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      _buildJointCard(
                        context,
                        icon: Icons.timeline_rounded,
                        title: 'Motion Detector',
                        description: 'Real-time motion analysis',
                        color: Color(0xFF0C7C9E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MotionDetectorScreen(device: device),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      _buildJointCard(
                        context,
                        icon: Icons.swap_horiz_rounded,
                        title: 'Left/Right Movement',
                        description: 'Lateral movement assessment',
                        color: Color(0xFF1A9DBF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeftRight(device: device),
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

  Widget _buildJointCard(
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
                // Icon Container
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

                // Text Content
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

                // Arrow Icon
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
