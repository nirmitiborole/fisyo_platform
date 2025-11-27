// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
//
// class SensorDataPoint {
//   final double timestamp;
//   final double angle;
//   final double ax, ay, az;
//   final double gx, gy, gz;
//   final double roll;
//   final double pitch;
//   final double positionX;
//   final double positionY;
//
//   SensorDataPoint({
//     required this.timestamp,
//     required this.angle,
//     required this.ax,
//     required this.ay,
//     required this.az,
//     required this.gx,
//     required this.gy,
//     required this.gz,
//     required this.roll,
//     required this.pitch,
//     required this.positionX,
//     required this.positionY,
//   });
//
//   Map<String, dynamic> toJson() {
//     return {
//       'timestamp': timestamp,
//       'angle': angle,
//       'ax': ax,
//       'ay': ay,
//       'az': az,
//       'gx': gx,
//       'gy': gy,
//       'gz': gz,
//       'roll': roll,
//       'pitch': pitch,
//       'position_x': positionX,
//       'position_y': positionY,
//     };
//   }
// }
//
// class LeftRight extends StatefulWidget {
//   final BluetoothDevice device;
//
//   LeftRight({required this.device});
//
//   @override
//   _LeftRightState createState() => _LeftRightState();
// }
//
// class _LeftRightState extends State<LeftRight> with TickerProviderStateMixin {
//   BluetoothCharacteristic? _characteristic;
//
//   double angle = 0.0;
//   double ax = 0.0, ay = 0.0, az = 0.0;
//   double gx = 0.0, gy = 0.0, gz = 0.0;
//
//   double currentRoll = 0.0;
//   double currentPitch = 0.0;
//
//   bool isConnected = false;
//
//   double circleX = 0.0;
//   double circleY = 0.0;
//   double outerCircleRadius = 150.0;
//   double innerCircleRadius = 85.0; // Reduced from 100.0
//   double smallCircleRadius = 20.0;
//
//   bool _isReading = false;
//   Timer? _readTimer;
//
//   late AnimationController _animationController;
//   late Animation<Offset> _positionAnimation;
//
//   List<double> _rollHistory = [];
//   List<double> _pitchHistory = [];
//   int _historySize = 5;
//
//   bool _isRecording = false;
//   List<Map<String, dynamic>> _recordedData = [];
//   DateTime? _recordingStartTime;
//   double _currentScore = 0.0;
//
//   double _totalDeviation = 0.0;
//   int _dataPointCount = 0;
//   double _previousX = 0.0;
//   double _previousY = 0.0;
//   double _totalJitter = 0.0;
//   double _timeInCenter = 0.0;
//   DateTime? _lastUpdateTime;
//
//   double _sessionTotalDeviation = 0.0;
//   double _sessionMaxDeviation = 0.0;
//   int _sessionDataPoints = 0;
//
//   double _northTime = 0.0;
//   double _northEastTime = 0.0;
//   double _eastTime = 0.0;
//   double _southEastTime = 0.0;
//   double _southTime = 0.0;
//   double _southWestTime = 0.0;
//   double _westTime = 0.0;
//   double _northWestTime = 0.0;
//   double _centerTime = 0.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: Duration(milliseconds: 150),
//       vsync: this,
//     );
//     _positionAnimation = Tween<Offset>(begin: Offset(0.0, 0.0), end: Offset(0.0, 0.0)).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//     _connectToDevice();
//   }
//
//   @override
//   void dispose() {
//     _stopReading();
//     _animationController.dispose();
//     widget.device.disconnect();
//     super.dispose();
//   }
//
//   Future<void> _connectToDevice() async {
//     try {
//       await widget.device.connect(timeout: Duration(seconds: 15));
//       print('Connected to ${widget.device.name}');
//
//       await Future.delayed(Duration(seconds: 1));
//       List<BluetoothService> services = await widget.device.discoverServices();
//
//       for (var service in services) {
//         for (var characteristic in service.characteristics) {
//           if (characteristic.uuid.toString() == 'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
//             _characteristic = characteristic;
//             print('Found characteristic: ${characteristic.uuid}');
//             setState(() {
//               isConnected = true;
//             });
//             return;
//           }
//         }
//       }
//       _showErrorDialog('Required characteristic not found');
//     } catch (e) {
//       _showErrorDialog('Connection failed: $e');
//     }
//   }
//
//   Future<void> _startReading() async {
//     if (_characteristic == null || _isReading) return;
//
//     setState(() {
//       _isReading = true;
//       _isRecording = true;
//       _recordedData.clear();
//       _recordingStartTime = DateTime.now();
//       _currentScore = 100.0;
//
//       _totalDeviation = 0.0;
//       _dataPointCount = 0;
//       _previousX = 0.0;
//       _previousY = 0.0;
//       _totalJitter = 0.0;
//       _timeInCenter = 0.0;
//       _lastUpdateTime = DateTime.now();
//
//       _sessionTotalDeviation = 0.0;
//       _sessionMaxDeviation = 0.0;
//       _sessionDataPoints = 0;
//
//       _northTime = 0.0;
//       _northEastTime = 0.0;
//       _eastTime = 0.0;
//       _southEastTime = 0.0;
//       _southTime = 0.0;
//       _southWestTime = 0.0;
//       _westTime = 0.0;
//       _northWestTime = 0.0;
//       _centerTime = 0.0;
//     });
//
//     _rollHistory.clear();
//     _pitchHistory.clear();
//
//     _readTimer = Timer.periodic(Duration(milliseconds: 100), (_) async {
//       if (!mounted) return;
//
//       try {
//         final data = await _characteristic!.read();
//         if (data.isNotEmpty) {
//           final dataString = utf8.decode(data).trim();
//           _parseAndUpdateData(dataString);
//         }
//       } catch (e) {
//         print('Error reading data: $e');
//         if (mounted) {
//           _stopReading();
//           _showErrorDialog('Error reading data: $e');
//         }
//       }
//     });
//
//     print('Started reading and recording data every 100ms.');
//   }
//
//   void _stopReading() {
//     _readTimer?.cancel();
//     _readTimer = null;
//
//     if (mounted) {
//       setState(() => _isReading = false);
//
//       if (_isRecording) {
//         _isRecording = false;
//         _generateReport();
//       }
//     }
//     print('Stopped reading data.');
//   }
//
//   double _smoothValue(double newValue, List<double> history) {
//     history.add(newValue);
//     if (history.length > _historySize) {
//       history.removeAt(0);
//     }
//     return history.reduce((a, b) => a + b) / history.length;
//   }
//
//   Offset _calculateCirclePosition(double rollAngle, double pitchAngle) {
//     double positionX = -rollAngle / 20.0; // Increased sensitivity
//     double positionY = -pitchAngle / 20.0;
//
//     if (positionX.abs() < 0.05) {
//       positionX = 0.0;
//     }
//     if (positionY.abs() < 0.05) {
//       positionY = 0.0;
//     }
//
//     return Offset(
//       positionX.clamp(-1.0, 1.0),
//       positionY.clamp(-1.0, 1.0),
//     );
//   }
//
//   void _parseAndUpdateData(String data) {
//     try {
//       List<String> values = data.split(',');
//       if (values.length >= 7) {
//         angle = double.tryParse(values[0]) ?? 0.0;
//         ax = double.tryParse(values[1]) ?? 0.0;
//         ay = double.tryParse(values[2]) ?? 0.0;
//         az = double.tryParse(values[3]) ?? 0.0;
//         gx = double.tryParse(values[4]) ?? 0.0;
//         gy = double.tryParse(values[5]) ?? 0.0;
//         gz = double.tryParse(values[6]) ?? 0.0;
//
//         currentRoll = atan2(ay, sqrt(ax * ax + az * az)) * 180.0 / pi;
//         currentPitch = atan2(-ax, sqrt(ay * ay + az * az)) * 180.0 / pi;
//
//         double smoothedRoll = _smoothValue(currentRoll, _rollHistory);
//         double smoothedPitch = _smoothValue(currentPitch, _pitchHistory);
//
//         Offset targetPosition = _calculateCirclePosition(smoothedRoll, smoothedPitch);
//         _animateToPosition(targetPosition);
//
//         if (_isRecording && _recordingStartTime != null) {
//           double timestamp = DateTime.now().difference(_recordingStartTime!).inMilliseconds / 1000.0;
//
//           SensorDataPoint dataPoint = SensorDataPoint(
//             timestamp: timestamp,
//             angle: angle,
//             ax: ax,
//             ay: ay,
//             az: az,
//             gx: gx,
//             gy: gy,
//             gz: gz,
//             roll: currentRoll,
//             pitch: currentPitch,
//             positionX: circleX,
//             positionY: circleY,
//           );
//
//           _recordedData.add(dataPoint.toJson());
//           _updateScore();
//         }
//       }
//     } catch (e) {
//       print("Error parsing data: $e");
//     }
//   }
//
//   void _updateScore() {
//     if (!_isRecording || _lastUpdateTime == null) return;
//
//     DateTime now = DateTime.now();
//     double timeDelta = now.difference(_lastUpdateTime!).inMilliseconds / 1000.0;
//     _lastUpdateTime = now;
//
//     _dataPointCount++;
//     _sessionDataPoints++;
//
//     _trackSectorData(timeDelta);
//
//     double currentDistance = sqrt(circleX * circleX + circleY * circleY);
//     double deviationScore = (1.0 - currentDistance.clamp(0.0, 1.0)) * 100.0;
//
//     double positionChangeX = (circleX - _previousX).abs();
//     double positionChangeY = (circleY - _previousY).abs();
//     double currentJitter = sqrt(positionChangeX * positionChangeX + positionChangeY * positionChangeY);
//     double jitterScore = (1.0 - (currentJitter * 10.0).clamp(0.0, 1.0)) * 100.0;
//
//     double stabilityScore = currentDistance < 0.2 ? 100.0 : 0.0;
//
//     _currentScore = (deviationScore * 0.5) + (jitterScore * 0.3) + (stabilityScore * 0.2);
//     _currentScore = _currentScore.clamp(0.0, 100.0);
//
//     _previousX = circleX;
//     _previousY = circleY;
//
//     _updateSessionTracking(currentDistance, timeDelta);
//
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   void _updateSessionTracking(double currentDistance, double timeDelta) {
//     _sessionTotalDeviation += currentDistance;
//     _totalDeviation += currentDistance;
//
//     if (currentDistance > _sessionMaxDeviation) {
//       _sessionMaxDeviation = currentDistance;
//     }
//
//     if (currentDistance < 0.2) {
//       _timeInCenter += timeDelta;
//     }
//   }
//
//   void _trackSectorData(double timeDelta) {
//     double distance = sqrt(circleX * circleX + circleY * circleY);
//
//     if (distance < 0.2) {
//       _centerTime += timeDelta;
//     } else {
//       double angleRad = atan2(circleY, circleX);
//       double angleDeg = angleRad * 180.0 / pi;
//
//       if (angleDeg < 0) angleDeg += 360;
//
//       if (angleDeg >= 337.5 || angleDeg < 22.5) {
//         _eastTime += timeDelta;
//       } else if (angleDeg >= 22.5 && angleDeg < 67.5) {
//         _southEastTime += timeDelta;
//       } else if (angleDeg >= 67.5 && angleDeg < 112.5) {
//         _southTime += timeDelta;
//       } else if (angleDeg >= 112.5 && angleDeg < 157.5) {
//         _southWestTime += timeDelta;
//       } else if (angleDeg >= 157.5 && angleDeg < 202.5) {
//         _westTime += timeDelta;
//       } else if (angleDeg >= 202.5 && angleDeg < 247.5) {
//         _northWestTime += timeDelta;
//       } else if (angleDeg >= 247.5 && angleDeg < 292.5) {
//         _northTime += timeDelta;
//       } else {
//         _northEastTime += timeDelta;
//       }
//     }
//   }
//
//   void _animateToPosition(Offset target) {
//     _positionAnimation = Tween<Offset>(
//       begin: Offset(circleX, circleY),
//       end: target,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
//
//     _animationController.reset();
//     _animationController.forward();
//
//     _positionAnimation.addListener(() {
//       if (mounted) {
//         setState(() {
//           circleX = _positionAnimation.value.dx;
//           circleY = _positionAnimation.value.dy;
//         });
//       }
//     });
//   }
//
//   Color _getColor(int index) {
//     const colors = [
//       Colors.red,
//       Colors.blue,
//       Colors.green,
//       Colors.orange,
//       Colors.purple,
//       Colors.cyan,
//       Colors.amber,
//     ];
//     return colors[index % colors.length];
//   }
//
//   Map<String, dynamic> _createJsonReport({
//     required String classification,
//     required double score,
//     required double duration,
//     required double avgDeviation,
//     required double maxDeviation,
//   }) {
//     String sessionId = _recordingStartTime != null
//         ? '${_recordingStartTime!.year}-${_recordingStartTime!.month.toString().padLeft(2, '0')}-${_recordingStartTime!.day.toString().padLeft(2, '0')}_${_recordingStartTime!.hour.toString().padLeft(2, '0')}-${_recordingStartTime!.minute.toString().padLeft(2, '0')}-${_recordingStartTime!.second.toString().padLeft(2, '0')}'
//         : 'unknown';
//
//     double totalTime = _centerTime + _northTime + _northEastTime + _eastTime +
//         _southEastTime + _southTime + _southWestTime + _westTime + _northWestTime;
//     Map<String, double> sectorPercentages = {};
//
//     if (totalTime > 0) {
//       sectorPercentages = {
//         'center': (_centerTime / totalTime) * 100,
//         'north': (_northTime / totalTime) * 100,
//         'north_east': (_northEastTime / totalTime) * 100,
//         'east': (_eastTime / totalTime) * 100,
//         'south_east': (_southEastTime / totalTime) * 100,
//         'south': (_southTime / totalTime) * 100,
//         'south_west': (_southWestTime / totalTime) * 100,
//         'west': (_westTime / totalTime) * 100,
//         'north_west': (_northWestTime / totalTime) * 100,
//       };
//     }
//
//     return {
//       'session_id': sessionId,
//       'duration_seconds': duration,
//       'total_data_points': _recordedData.length,
//       'final_score': score,
//       'classification': classification,
//       'summary': {
//         'average_deviation': avgDeviation,
//         'max_deviation': maxDeviation,
//         'time_in_center_seconds': _timeInCenter,
//         'average_jitter': _dataPointCount > 0 ? _totalJitter / _dataPointCount : 0.0,
//       },
//       'sector_analysis': sectorPercentages,
//       'data_points': _recordedData,
//     };
//   }
//
//   Future<String?> _saveJsonToFile(Map<String, dynamic> jsonData) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       String timestamp = jsonData['session_id'] ?? 'report';
//       String filename = 'stability_report_$timestamp.json';
//       final file = File('${directory.path}/$filename');
//       String jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
//       await file.writeAsString(jsonString);
//       print('Report saved to: ${file.path}');
//       return file.path;
//     } catch (e) {
//       print('Error saving file: $e');
//       return null;
//     }
//   }
//
//   Future<void> _shareReport(String filePath) async {
//     try {
//       final file = XFile(filePath);
//       await Share.shareXFiles(
//         [file],
//         subject: 'Stability Report',
//         text: 'Sensor stability test report from Goniometer App',
//       );
//     } catch (e) {
//       print('Error sharing file: $e');
//       _showErrorDialog('Error sharing report: $e');
//     }
//   }
//
//   void _generateReport() async {
//     if (_recordedData.isEmpty || _recordingStartTime == null) {
//       _showErrorDialog('No data recorded');
//       return;
//     }
//
//     double durationSeconds = DateTime.now().difference(_recordingStartTime!).inMilliseconds / 1000.0;
//     double avgDeviation = _sessionDataPoints > 0 ? _sessionTotalDeviation / _sessionDataPoints : 0.0;
//     double maxDeviation = _sessionMaxDeviation;
//
//     double sessionDeviationScore = (1.0 - avgDeviation.clamp(0.0, 1.0)) * 100.0;
//     double sessionCenterTimeRatio = durationSeconds > 0 ? (_timeInCenter / durationSeconds) : 0.0;
//     double sessionCenterScore = sessionCenterTimeRatio * 100.0;
//
//     double overallSessionScore = (sessionDeviationScore * 0.7) + (sessionCenterScore * 0.3);
//     overallSessionScore = overallSessionScore.clamp(0.0, 100.0);
//
//     String classification;
//     Color classificationColor;
//     IconData classificationIcon;
//
//     if (overallSessionScore >= 75) {
//       classification = 'Highly Stable';
//       classificationColor = Colors.blue;
//       classificationIcon = Icons.check_circle_outline;
//     } else if (overallSessionScore >= 50) {
//       classification = 'Stable';
//       classificationColor = Colors.green;
//       classificationIcon = Icons.check_circle;
//     } else {
//       classification = 'Unstable';
//       classificationColor = Colors.red;
//       classificationIcon = Icons.cancel;
//     }
//
//     Map<String, dynamic> jsonReport = _createJsonReport(
//       classification: classification,
//       score: overallSessionScore,
//       duration: durationSeconds,
//       avgDeviation: avgDeviation,
//       maxDeviation: maxDeviation,
//     );
//
//     String? savedFilePath = await _saveJsonToFile(jsonReport);
//
//     _showReportDialog(
//       classification: classification,
//       score: overallSessionScore,
//       duration: durationSeconds,
//       dataPoints: _recordedData.length,
//       avgDeviation: avgDeviation,
//       maxDeviation: maxDeviation,
//       timeInCenter: _timeInCenter,
//       color: classificationColor,
//       icon: classificationIcon,
//       filePath: savedFilePath,
//     );
//   }
//
//   Widget _buildHeatmapWidget() {
//     double totalTime = _centerTime + _northTime + _northEastTime + _eastTime +
//         _southEastTime + _southTime + _southWestTime + _westTime + _northWestTime;
//
//     if (totalTime == 0) {
//       return Container(
//         height: 120,
//         child: Center(child: Text('No movement data')),
//       );
//     }
//
//     double centerPercent = (_centerTime / totalTime) * 100;
//     double northPercent = (_northTime / totalTime) * 100;
//     double northEastPercent = (_northEastTime / totalTime) * 100;
//     double eastPercent = (_eastTime / totalTime) * 100;
//     double southEastPercent = (_southEastTime / totalTime) * 100;
//     double southPercent = (_southTime / totalTime) * 100;
//     double southWestPercent = (_southWestTime / totalTime) * 100;
//     double westPercent = (_westTime / totalTime) * 100;
//     double northWestPercent = (_northWestTime / totalTime) * 100;
//
//     Color getHeatColor(double percent) {
//       if (percent < 15) {
//         return Colors.red.withOpacity(0.6);
//       } else if (percent < 25) {
//         return Colors.green.withOpacity(0.7);
//       } else {
//         return Colors.blue.withOpacity(0.8);
//       }
//     }
//
//     return Container(
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey[300]!),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Text(
//             'Movement Heatmap',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 12),
//
//           Container(
//             width: 220,
//             height: 220,
//             child: CustomPaint(
//               size: Size(220, 220),
//               painter: CircularHeatmapPainter(
//                 centerPercent: centerPercent,
//                 northPercent: northPercent,
//                 northEastPercent: northEastPercent,
//                 eastPercent: eastPercent,
//                 southEastPercent: southEastPercent,
//                 southPercent: southPercent,
//                 southWestPercent: southWestPercent,
//                 westPercent: westPercent,
//                 northWestPercent: northWestPercent,
//                 getHeatColor: getHeatColor,
//               ),
//             ),
//           ),
//
//           SizedBox(height: 12),
//
//           Wrap(
//             spacing: 12,
//             runSpacing: 6,
//             alignment: WrapAlignment.center,
//             children: [
//               _buildSectorLabel('Center', centerPercent, Colors.green[700]!),
//               _buildSectorLabel('N', northPercent),
//               _buildSectorLabel('NE', northEastPercent),
//               _buildSectorLabel('E', eastPercent),
//               _buildSectorLabel('SE', southEastPercent),
//               _buildSectorLabel('S', southPercent),
//               _buildSectorLabel('SW', southWestPercent),
//               _buildSectorLabel('W', westPercent),
//               _buildSectorLabel('NW', northWestPercent),
//             ],
//           ),
//
//           SizedBox(height: 8),
//
//           Wrap(
//             spacing: 8,
//             alignment: WrapAlignment.center,
//             children: [
//               _buildLegendItem(Colors.red.withOpacity(0.6), 'Unstable (<15%)'),
//               _buildLegendItem(Colors.green.withOpacity(0.7), 'Stable (15-25%)'),
//               _buildLegendItem(Colors.blue.withOpacity(0.8), 'Highly Stable (>25%)'),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSectorLabel(String label, double percent, [Color? color]) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color: (color ?? Colors.grey[300])?.withOpacity(0.3),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         '$label: ${percent.toStringAsFixed(1)}%',
//         style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
//       ),
//     );
//   }
//
//   Widget _buildLegendItem(Color color, String label) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(2),
//             border: Border.all(color: Colors.grey),
//           ),
//         ),
//         SizedBox(width: 4),
//         Text(label, style: TextStyle(fontSize: 10)),
//       ],
//     );
//   }
//
//   void _showReportDialog({
//     required String classification,
//     required double score,
//     required double duration,
//     required int dataPoints,
//     required double avgDeviation,
//     required double maxDeviation,
//     required double timeInCenter,
//     required Color color,
//     required IconData icon,
//     String? filePath,
//   }) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Column(
//           children: [
//             Icon(icon, size: 64, color: color),
//             SizedBox(height: 12),
//             Text(
//               classification,
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: color, width: 2),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Overall Session Score',
//                       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                     ),
//                     Text(
//                       score.toStringAsFixed(1),
//                       style: TextStyle(
//                         fontSize: 42,
//                         fontWeight: FontWeight.bold,
//                         color: color,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               _buildReportRow('Duration', '${duration.toStringAsFixed(1)}s'),
//               _buildReportRow('Data Points', '$dataPoints'),
//               _buildReportRow('Avg Deviation', '${(avgDeviation * 100).toStringAsFixed(1)}%'),
//               _buildReportRow('Max Deviation', '${(maxDeviation * 100).toStringAsFixed(1)}%'),
//               _buildReportRow('Time in Center', '${timeInCenter.toStringAsFixed(1)}s'),
//
//               SizedBox(height: 16),
//
//               _buildHeatmapWidget(),
//             ],
//           ),
//         ),
//         actions: [
//           if (filePath != null)
//             ElevatedButton.icon(
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await _shareReport(filePath);
//               },
//               icon: Icon(Icons.share, color: Colors.white),
//               label: Text('Share Report', style: TextStyle(color: Colors.white)),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               ),
//             ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('Close', style: TextStyle(fontSize: 16)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReportRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildScoreDisplay() {
//     Color scoreColor;
//     String scoreLabel;
//
//     if (_currentScore >= 75) {
//       scoreColor = Colors.blue;
//       scoreLabel = 'Highly Stable';
//     } else if (_currentScore >= 50) {
//       scoreColor = Colors.green;
//       scoreLabel = 'Stable';
//     } else {
//       scoreColor = Colors.red;
//       scoreLabel = 'Unstable';
//     }
//
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [scoreColor.withOpacity(0.3), scoreColor.withOpacity(0.1)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: scoreColor, width: 2),
//       ),
//       child: Column(
//         children: [
//           Text(
//             'Current Stability Score',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[700],
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             _currentScore.toStringAsFixed(1),
//             style: TextStyle(
//               fontSize: 48,
//               fontWeight: FontWeight.bold,
//               color: scoreColor,
//             ),
//           ),
//           SizedBox(height: 4),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               color: scoreColor.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               scoreLabel,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: scoreColor,
//               ),
//             ),
//           ),
//           SizedBox(height: 12),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: LinearProgressIndicator(
//               value: _currentScore / 100,
//               minHeight: 8,
//               backgroundColor: Colors.grey[300],
//               valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildControlButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         ElevatedButton.icon(
//           onPressed: isConnected
//               ? (_isReading ? _stopReading : _startReading)
//               : null,
//           icon: Icon(_isReading ? Icons.stop : Icons.play_arrow),
//           label: Text(_isReading ? 'Stop' : 'Start'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: _isReading ? Colors.red : Colors.green,
//             foregroundColor: Colors.white,
//             padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildStatusIndicators() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         Container(
//           padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//           decoration: BoxDecoration(
//             color: isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
//             borderRadius: BorderRadius.circular(15),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
//                 size: 18,
//                 color: isConnected ? Colors.green : Colors.red,
//               ),
//               SizedBox(width: 6),
//               Text(
//                 isConnected ? 'Connected' : 'Disconnected',
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: isConnected ? Colors.green : Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         Container(
//           padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//           decoration: BoxDecoration(
//             color: _isReading ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
//             borderRadius: BorderRadius.circular(15),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 _isReading ? Icons.sensors : Icons.sensors_off,
//                 size: 18,
//                 color: _isReading ? Colors.blue : Colors.grey,
//               ),
//               SizedBox(width: 6),
//               Text(
//                 _isReading ? 'Reading' : 'Stopped',
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: _isReading ? Colors.blue : Colors.grey,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ✅ NEW: Display Angle, Accelerometer, and Gyroscope values
//   Widget _buildSensorDataDisplay() {
//     return Container(
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: Column(
//         children: [
//           // Angle
//           Text(
//             'Angle: ${angle.toStringAsFixed(2)}°',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           SizedBox(height: 8),
//
//           // Accelerometer values
//           Text(
//             'Accelerometer',
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[700],
//             ),
//           ),
//           SizedBox(height: 4),
//           Text(
//             'Ax: ${ax.toStringAsFixed(2)}  Ay: ${ay.toStringAsFixed(2)}  Az: ${az.toStringAsFixed(2)}',
//             style: TextStyle(fontSize: 12, color: Colors.black87),
//           ),
//
//           SizedBox(height: 8),
//
//           // Gyroscope values
//           Text(
//             'Gyroscope',
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[700],
//             ),
//           ),
//           SizedBox(height: 4),
//           Text(
//             'Gx: ${gx.toStringAsFixed(2)}  Gy: ${gy.toStringAsFixed(2)}  Gz: ${gz.toStringAsFixed(2)}',
//             style: TextStyle(fontSize: 12, color: Colors.black87),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCircleVisualization() {
//     double distance = sqrt(circleX * circleX + circleY * circleY);
//     double maxAllowedRadius = outerCircleRadius - smallCircleRadius;
//     double actualX, actualY;
//
//     if (distance <= 0.67) {
//       double maxRadius = innerCircleRadius - smallCircleRadius;
//       actualX = circleX * maxRadius;
//       actualY = circleY * maxRadius;
//     } else {
//       double scaleFactor = (distance - 0.67) / 0.33;
//       double extraRadius = (outerCircleRadius - innerCircleRadius) * scaleFactor;
//       double dirX = circleX / distance;
//       double dirY = circleY / distance;
//       double targetRadius = (innerCircleRadius - smallCircleRadius + extraRadius);
//       targetRadius = targetRadius.clamp(0.0, maxAllowedRadius);
//       actualX = dirX * targetRadius;
//       actualY = dirY * targetRadius;
//     }
//
//     return Container(
//       width: outerCircleRadius * 2,
//       height: outerCircleRadius * 2,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Container(
//             width: outerCircleRadius * 2,
//             height: outerCircleRadius * 2,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.grey, width: 2),
//               color: Colors.grey.withOpacity(0.1),
//             ),
//           ),
//
//           Container(
//             width: innerCircleRadius * 2,
//             height: innerCircleRadius * 2,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.lightBlue, width: 2),
//               color: Colors.lightBlue.withOpacity(0.1),
//             ),
//           ),
//
//           AnimatedPositioned(
//             duration: Duration(milliseconds: 100),
//             curve: Curves.easeInOut,
//             left: (outerCircleRadius - smallCircleRadius) + actualX,
//             top: (outerCircleRadius - smallCircleRadius) + actualY,
//             child: Container(
//               width: smallCircleRadius * 2,
//               height: smallCircleRadius * 2,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _getMovementColor(),
//                 boxShadow: [
//                   BoxShadow(
//                     color: _getMovementColor().withOpacity(0.6),
//                     blurRadius: 8,
//                     spreadRadius: 2,
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Container(
//                   width: smallCircleRadius * 1.2,
//                   height: smallCircleRadius * 1.2,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//
//           Container(
//             width: outerCircleRadius * 2,
//             height: 2,
//             color: Colors.black.withOpacity(0.4),
//           ),
//
//           Container(
//             width: 2,
//             height: outerCircleRadius * 2,
//             color: Colors.black.withOpacity(0.4),
//           ),
//
//           Positioned(
//             left: 15,
//             top: outerCircleRadius - 10,
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.8),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text('LEFT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
//             ),
//           ),
//           Positioned(
//             right: 15,
//             top: outerCircleRadius - 10,
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.8),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text('RIGHT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
//             ),
//           ),
//
//           Positioned(
//             top: 15,
//             left: outerCircleRadius - 12,
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//               decoration: BoxDecoration(
//                 color: Colors.purple.withOpacity(0.8),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text('UP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
//             ),
//           ),
//           Positioned(
//             bottom: 15,
//             left: outerCircleRadius - 18,
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//               decoration: BoxDecoration(
//                 color: Colors.orange.withOpacity(0.8),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text('DOWN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _getMovementColor() {
//     double distance = sqrt(circleX * circleX + circleY * circleY);
//
//     if (distance < 0.15) {
//       return Colors.green;
//     }
//
//     if (circleY.abs() > circleX.abs()) {
//       return circleY < 0 ? Colors.purple : Colors.orange;
//     } else {
//       return circleX < 0 ? Colors.blue : Colors.red;
//     }
//   }
//
//   String _getMovementText() {
//     double distance = sqrt(circleX * circleX + circleY * circleY);
//
//     if (distance < 0.15) {
//       return 'CENTER (Roll: ${currentRoll.toStringAsFixed(1)}°, Pitch: ${currentPitch.toStringAsFixed(1)}°)';
//     }
//
//     String horizontalDir = '';
//     String verticalDir = '';
//
//     if (circleX < -0.3) {
//       horizontalDir = 'STRONG LEFT';
//     } else if (circleX < -0.15) {
//       horizontalDir = 'LEFT';
//     } else if (circleX > 0.3) {
//       horizontalDir = 'STRONG RIGHT';
//     } else if (circleX > 0.15) {
//       horizontalDir = 'RIGHT';
//     }
//
//     if (circleY < -0.3) {
//       verticalDir = 'STRONG UP';
//     } else if (circleY < -0.15) {
//       verticalDir = 'UP';
//     } else if (circleY > 0.3) {
//       verticalDir = 'STRONG DOWN';
//     } else if (circleY > 0.15) {
//       verticalDir = 'DOWN';
//     }
//
//     String direction = '';
//     if (verticalDir.isNotEmpty && horizontalDir.isNotEmpty) {
//       direction = '$verticalDir-$horizontalDir';
//     } else if (verticalDir.isNotEmpty) {
//       direction = verticalDir;
//     } else if (horizontalDir.isNotEmpty) {
//       direction = horizontalDir;
//     }
//
//     return '$direction (Roll: ${currentRoll.toStringAsFixed(1)}°, Pitch: ${currentPitch.toStringAsFixed(1)}°)';
//   }
//
//   void _showErrorDialog(String message) {
//     if (mounted) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Error'),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text('OK'),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('4-Direction Tilt Detector'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               _buildStatusIndicators(),
//               SizedBox(height: 20),
//
//               _buildControlButtons(),
//               SizedBox(height: 20),
//
//               if (_isRecording && _isReading) ...[
//                 _buildScoreDisplay(),
//                 SizedBox(height: 20),
//               ],
//
//               if (_isReading)
//                 Container(
//                   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//                   decoration: BoxDecoration(
//                     color: _getMovementColor().withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         _getMovementText(),
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: _getMovementColor(),
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         'Position: X: ${(circleX * 100).toStringAsFixed(1)}%, Y: ${(circleY * 100).toStringAsFixed(1)}%',
//                         style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                       ),
//                     ],
//                   ),
//                 ),
//
//               SizedBox(height: 25),
//
//               _buildCircleVisualization(),
//
//               SizedBox(height: 20),
//
//               // ✅ CHANGED: Show sensor data instead of roll/pitch
//               if (_isReading) ...[
//                 _buildSensorDataDisplay(),
//                 SizedBox(height: 15),
//               ],
//
//               if (!_isReading) ...[
//                 SizedBox(height: 30),
//                 Text(
//                   'Press START to begin tilt detection',
//                   style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 12),
//                 Text(
//                   'Tilt the device in any direction and the circle will move accordingly.',
//                   style: TextStyle(fontSize: 13, color: Colors.grey[500]),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class CircularHeatmapPainter extends CustomPainter {
//   final double centerPercent;
//   final double northPercent;
//   final double northEastPercent;
//   final double eastPercent;
//   final double southEastPercent;
//   final double southPercent;
//   final double southWestPercent;
//   final double westPercent;
//   final double northWestPercent;
//   final Color Function(double) getHeatColor;
//
//   CircularHeatmapPainter({
//     required this.centerPercent,
//     required this.northPercent,
//     required this.northEastPercent,
//     required this.eastPercent,
//     required this.southEastPercent,
//     required this.southPercent,
//     required this.southWestPercent,
//     required this.westPercent,
//     required this.northWestPercent,
//     required this.getHeatColor,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = size.width / 2;
//     final centerRadius = radius * 0.3;
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;
//     canvas.drawCircle(center, radius, borderPaint);
//
//     final linePaint = Paint()
//       ..color = Colors.grey[600]!
//       ..strokeWidth = 1.5;
//
//     for (int i = 0; i < 8; i++) {
//       double angle = (i * 45) * pi / 180;
//       canvas.drawLine(
//         Offset(center.dx + centerRadius * cos(angle), center.dy + centerRadius * sin(angle)),
//         Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
//         linePaint,
//       );
//     }
//
//     _drawSector(canvas, center, centerRadius, radius, 0, pi/4, getHeatColor(eastPercent));
//     _drawSector(canvas, center, centerRadius, radius, pi/4, pi/2, getHeatColor(southEastPercent));
//     _drawSector(canvas, center, centerRadius, radius, pi/2, 3*pi/4, getHeatColor(southPercent));
//     _drawSector(canvas, center, centerRadius, radius, 3*pi/4, pi, getHeatColor(southWestPercent));
//     _drawSector(canvas, center, centerRadius, radius, pi, 5*pi/4, getHeatColor(westPercent));
//     _drawSector(canvas, center, centerRadius, radius, 5*pi/4, 3*pi/2, getHeatColor(northWestPercent));
//     _drawSector(canvas, center, centerRadius, radius, 3*pi/2, 7*pi/4, getHeatColor(northPercent));
//     _drawSector(canvas, center, centerRadius, radius, 7*pi/4, 2*pi, getHeatColor(northEastPercent));
//
//     final centerPaint = Paint()
//       ..color = getHeatColor(centerPercent)
//       ..style = PaintingStyle.fill;
//     canvas.drawCircle(center, centerRadius, centerPaint);
//
//     final centerBorderPaint = Paint()
//       ..color = Colors.green[700]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3;
//     canvas.drawCircle(center, centerRadius, centerBorderPaint);
//
//     _drawSectorLabels(canvas, center, centerRadius, radius);
//   }
//
//   void _drawSector(Canvas canvas, Offset center, double innerRadius, double outerRadius,
//       double startAngle, double endAngle, Color color) {
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.fill;
//
//     final path = Path();
//
//     path.moveTo(center.dx + innerRadius * cos(startAngle),
//         center.dy + innerRadius * sin(startAngle));
//     path.lineTo(center.dx + outerRadius * cos(startAngle),
//         center.dy + outerRadius * sin(startAngle));
//     path.arcTo(
//         Rect.fromCircle(center: center, radius: outerRadius),
//         startAngle, endAngle - startAngle, false
//     );
//     path.lineTo(center.dx + innerRadius * cos(endAngle),
//         center.dy + innerRadius * sin(endAngle));
//     path.arcTo(
//         Rect.fromCircle(center: center, radius: innerRadius),
//         endAngle, startAngle - endAngle, false
//     );
//     path.close();
//
//     canvas.drawPath(path, paint);
//   }
//
//   void _drawSectorLabels(Canvas canvas, Offset center, double centerRadius, double outerRadius) {
//     final textStyle = TextStyle(
//       color: Colors.black87,
//       fontSize: 9,
//       fontWeight: FontWeight.bold,
//     );
//
//     _drawText(canvas, '${centerPercent.toStringAsFixed(1)}%', center, textStyle.copyWith(fontSize: 11));
//
//     final labelRadius = centerRadius + (outerRadius - centerRadius) / 2;
//
//     List<Map<String, dynamic>> sectors = [
//       {'angle': pi/8, 'percent': eastPercent},
//       {'angle': 3*pi/8, 'percent': southEastPercent},
//       {'angle': 5*pi/8, 'percent': southPercent},
//       {'angle': 7*pi/8, 'percent': southWestPercent},
//       {'angle': 9*pi/8, 'percent': westPercent},
//       {'angle': 11*pi/8, 'percent': northWestPercent},
//       {'angle': 13*pi/8, 'percent': northPercent},
//       {'angle': 15*pi/8, 'percent': northEastPercent},
//     ];
//
//     for (var sector in sectors) {
//       double angle = sector['angle'];
//       double percent = sector['percent'];
//       Offset position = Offset(
//         center.dx + labelRadius * cos(angle),
//         center.dy + labelRadius * sin(angle),
//       );
//       _drawText(canvas, '${percent.toStringAsFixed(1)}%', position, textStyle);
//     }
//   }
//
//   void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
//     final textPainter = TextPainter(
//       text: TextSpan(text: text, style: style),
//       textAlign: TextAlign.center,
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(
//       position.dx - textPainter.width / 2,
//       position.dy - textPainter.height / 2,
//     ));
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// --- Step 1: Import your new separated files ---
// (We assume these are in the same 'left_right' folder)
import './left_right/report_service.dart';
import './left_right/circular_heatmap_painter.dart'; // We still need this for the `_generateReport` logic
import './left_right/left_right_widgets.dart';


// --- SensorDataPoint class ---
// (We'll keep this here as requested, since it's small)
class SensorDataPoint {
  final double timestamp;
  final double angle;
  final double ax, ay, az;
  final double gx, gy, gz;
  final double roll;
  final double pitch;
  final double positionX;
  final double positionY;

  SensorDataPoint({
    required this.timestamp,
    required this.angle,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.roll,
    required this.pitch,
    required this.positionX,
    required this.positionY,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'angle': angle,
      'ax': ax,
      'ay': ay,
      'az': az,
      'gx': gx,
      'gy': gy,
      'gz': gz,
      'roll': roll,
      'pitch': pitch,
      'position_x': positionX,
      'position_y': positionY,
    };
  }
}

// --- Main StatefulWidget ---
class LeftRight extends StatefulWidget {
  final BluetoothDevice device;

  LeftRight({required this.device});

  @override
  _LeftRightState createState() => _LeftRightState();
}

class _LeftRightState extends State<LeftRight> with TickerProviderStateMixin {
  // --- Step 2: Instantiate your service ---
  final ReportService _reportService = ReportService();

  // --- All State Variables Remain ---
  BluetoothCharacteristic? _characteristic;
  double angle = 0.0;
  double ax = 0.0, ay = 0.0, az = 0.0;
  double gx = 0.0, gy = 0.0, gz = 0.0;
  double currentRoll = 0.0;
  double currentPitch = 0.0;
  bool isConnected = false;
  double circleX = 0.0;
  double circleY = 0.0;
  double outerCircleRadius = 150.0;
  double innerCircleRadius = 85.0;
  double smallCircleRadius = 20.0;
  bool _isReading = false;
  Timer? _readTimer;
  late AnimationController _animationController;
  late Animation<Offset> _positionAnimation;
  List<double> _rollHistory = [];
  List<double> _pitchHistory = [];
  int _historySize = 5;
  bool _isRecording = false;
  List<Map<String, dynamic>> _recordedData = [];
  DateTime? _recordingStartTime;
  double _currentScore = 0.0;
  double _totalDeviation = 0.0;
  int _dataPointCount = 0;
  double _previousX = 0.0;
  double _previousY = 0.0;
  double _totalJitter = 0.0;
  double _timeInCenter = 0.0;
  DateTime? _lastUpdateTime;
  double _sessionTotalDeviation = 0.0;
  double _sessionMaxDeviation = 0.0;
  int _sessionDataPoints = 0;
  double _northTime = 0.0;
  double _northEastTime = 0.0;
  double _eastTime = 0.0;
  double _southEastTime = 0.0;
  double _southTime = 0.0;
  double _southWestTime = 0.0;
  double _westTime = 0.0;
  double _northWestTime = 0.0;
  double _centerTime = 0.0;

  // --- All Logic Methods Remain ---
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _positionAnimation = Tween<Offset>(begin: Offset(0.0, 0.0), end: Offset(0.0, 0.0)).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _connectToDevice();
  }

  @override
  void dispose() {
    _stopReading();
    _animationController.dispose();
    widget.device.disconnect();
    super.dispose();
  }

  Future<void> _connectToDevice() async {
    try {
      await widget.device.connect(timeout: Duration(seconds: 15));
      print('Connected to ${widget.device.name}');

      await Future.delayed(Duration(seconds: 1));
      List<BluetoothService> services = await widget.device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == 'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
            _characteristic = characteristic;
            print('Found characteristic: ${characteristic.uuid}');
            setState(() {
              isConnected = true;
            });
            return;
          }
        }
      }
      _showErrorDialog('Required characteristic not found');
    } catch (e) {
      _showErrorDialog('Connection failed: $e');
    }
  }

  Future<void> _startReading() async {
    if (_characteristic == null || _isReading) return;

    setState(() {
      _isReading = true;
      _isRecording = true;
      _recordedData.clear();
      _recordingStartTime = DateTime.now();
      _currentScore = 100.0;
      _totalDeviation = 0.0;
      _dataPointCount = 0;
      _previousX = 0.0;
      _previousY = 0.0;
      _totalJitter = 0.0;
      _timeInCenter = 0.0;
      _lastUpdateTime = DateTime.now();
      _sessionTotalDeviation = 0.0;
      _sessionMaxDeviation = 0.0;
      _sessionDataPoints = 0;
      _northTime = 0.0;
      _northEastTime = 0.0;
      _eastTime = 0.0;
      _southEastTime = 0.0;
      _southTime = 0.0;
      _southWestTime = 0.0;
      _westTime = 0.0;
      _northWestTime = 0.0;
      _centerTime = 0.0;
    });

    _rollHistory.clear();
    _pitchHistory.clear();

    _readTimer = Timer.periodic(Duration(milliseconds: 100), (_) async {
      if (!mounted) return;

      try {
        final data = await _characteristic!.read();
        if (data.isNotEmpty) {
          final dataString = utf8.decode(data).trim();
          _parseAndUpdateData(dataString);
        }
      } catch (e) {
        print('Error reading data: $e');
        if (mounted) {
          _stopReading();
          _showErrorDialog('Error reading data: $e');
        }
      }
    });

    print('Started reading and recording data every 100ms.');
  }

  void _stopReading() {
    _readTimer?.cancel();
    _readTimer = null;

    if (mounted) {
      setState(() => _isReading = false);

      if (_isRecording) {
        _isRecording = false;
        _generateReport();
      }
    }
    print('Stopped reading data.');
  }

  double _smoothValue(double newValue, List<double> history) {
    history.add(newValue);
    if (history.length > _historySize) {
      history.removeAt(0);
    }
    return history.reduce((a, b) => a + b) / history.length;
  }

  Offset _calculateCirclePosition(double rollAngle, double pitchAngle) {
    double positionX = -rollAngle / 20.0; // Increased sensitivity
    double positionY = -pitchAngle / 20.0;

    if (positionX.abs() < 0.05) {
      positionX = 0.0;
    }
    if (positionY.abs() < 0.05) {
      positionY = 0.0;
    }

    return Offset(
      positionX.clamp(-1.0, 1.0),
      positionY.clamp(-1.0, 1.0),
    );
  }

  void _parseAndUpdateData(String data) {
    try {
      List<String> values = data.split(',');
      if (values.length >= 7) {
        angle = double.tryParse(values[0]) ?? 0.0;
        ax = double.tryParse(values[1]) ?? 0.0;
        ay = double.tryParse(values[2]) ?? 0.0;
        az = double.tryParse(values[3]) ?? 0.0;
        gx = double.tryParse(values[4]) ?? 0.0;
        gy = double.tryParse(values[5]) ?? 0.0;
        gz = double.tryParse(values[6]) ?? 0.0;

        currentRoll = atan2(ay, sqrt(ax * ax + az * az)) * 180.0 / pi;
        currentPitch = atan2(-ax, sqrt(ay * ay + az * az)) * 180.0 / pi;

        double smoothedRoll = _smoothValue(currentRoll, _rollHistory);
        double smoothedPitch = _smoothValue(currentPitch, _pitchHistory);

        Offset targetPosition = _calculateCirclePosition(smoothedRoll, smoothedPitch);
        _animateToPosition(targetPosition);

        if (_isRecording && _recordingStartTime != null) {
          double timestamp = DateTime.now().difference(_recordingStartTime!).inMilliseconds / 1000.0;

          SensorDataPoint dataPoint = SensorDataPoint(
            timestamp: timestamp,
            angle: angle,
            ax: ax,
            ay: ay,
            az: az,
            gx: gx,
            gy: gy,
            gz: gz,
            roll: currentRoll,
            pitch: currentPitch,
            positionX: circleX,
            positionY: circleY,
          );

          _recordedData.add(dataPoint.toJson());
          _updateScore();
        }
      }
    } catch (e) {
      print("Error parsing data: $e");
    }
  }

  void _updateScore() {
    if (!_isRecording || _lastUpdateTime == null) return;

    DateTime now = DateTime.now();
    double timeDelta = now.difference(_lastUpdateTime!).inMilliseconds / 1000.0;
    _lastUpdateTime = now;

    _dataPointCount++;
    _sessionDataPoints++;

    _trackSectorData(timeDelta);

    double currentDistance = sqrt(circleX * circleX + circleY * circleY);
    double deviationScore = (1.0 - currentDistance.clamp(0.0, 1.0)) * 100.0;

    double positionChangeX = (circleX - _previousX).abs();
    double positionChangeY = (circleY - _previousY).abs();
    double currentJitter = sqrt(positionChangeX * positionChangeX + positionChangeY * positionChangeY);
    double jitterScore = (1.0 - (currentJitter * 10.0).clamp(0.0, 1.0)) * 100.0;

    double stabilityScore = currentDistance < 0.2 ? 100.0 : 0.0;

    _currentScore = (deviationScore * 0.5) + (jitterScore * 0.3) + (stabilityScore * 0.2);
    _currentScore = _currentScore.clamp(0.0, 100.0);

    _previousX = circleX;
    _previousY = circleY;

    _updateSessionTracking(currentDistance, timeDelta);

    if (mounted) {
      setState(() {});
    }
  }

  void _updateSessionTracking(double currentDistance, double timeDelta) {
    _sessionTotalDeviation += currentDistance;
    _totalDeviation += currentDistance;

    if (currentDistance > _sessionMaxDeviation) {
      _sessionMaxDeviation = currentDistance;
    }

    if (currentDistance < 0.2) {
      _timeInCenter += timeDelta;
    }
  }

  void _trackSectorData(double timeDelta) {
    double distance = sqrt(circleX * circleX + circleY * circleY);

    if (distance < 0.2) {
      _centerTime += timeDelta;
    } else {
      double angleRad = atan2(circleY, circleX);
      double angleDeg = angleRad * 180.0 / pi;

      if (angleDeg < 0) angleDeg += 360;

      if (angleDeg >= 337.5 || angleDeg < 22.5) {
        _eastTime += timeDelta;
      } else if (angleDeg >= 22.5 && angleDeg < 67.5) {
        _southEastTime += timeDelta;
      } else if (angleDeg >= 67.5 && angleDeg < 112.5) {
        _southTime += timeDelta;
      } else if (angleDeg >= 112.5 && angleDeg < 157.5) {
        _southWestTime += timeDelta;
      } else if (angleDeg >= 157.5 && angleDeg < 202.5) {
        _westTime += timeDelta;
      } else if (angleDeg >= 202.5 && angleDeg < 247.5) {
        _northWestTime += timeDelta;
      } else if (angleDeg >= 247.5 && angleDeg < 292.5) {
        _northTime += timeDelta;
      } else {
        _northEastTime += timeDelta;
      }
    }
  }

  void _animateToPosition(Offset target) {
    _positionAnimation = Tween<Offset>(
      begin: Offset(circleX, circleY),
      end: target,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.reset();
    _animationController.forward();

    _positionAnimation.addListener(() {
      if (mounted) {
        setState(() {
          circleX = _positionAnimation.value.dx;
          circleY = _positionAnimation.value.dy;
        });
      }
    });
  }

  Color _getColor(int index) {
    const colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  Map<String, dynamic> _createJsonReport({
    required String classification,
    required double score,
    required double duration,
    required double avgDeviation,
    required double maxDeviation,
  }) {
    String sessionId = _recordingStartTime != null
        ? '${_recordingStartTime!.year}-${_recordingStartTime!.month.toString().padLeft(2, '0')}-${_recordingStartTime!.day.toString().padLeft(2, '0')}_${_recordingStartTime!.hour.toString().padLeft(2, '0')}-${_recordingStartTime!.minute.toString().padLeft(2, '0')}-${_recordingStartTime!.second.toString().padLeft(2, '0')}'
        : 'unknown';

    double totalTime = _centerTime + _northTime + _northEastTime + _eastTime +
        _southEastTime + _southTime + _southWestTime + _westTime + _northWestTime;
    Map<String, double> sectorPercentages = {};

    if (totalTime > 0) {
      sectorPercentages = {
        'center': (_centerTime / totalTime) * 100,
        'north': (_northTime / totalTime) * 100,
        'north_east': (_northEastTime / totalTime) * 100,
        'east': (_eastTime / totalTime) * 100,
        'south_east': (_southEastTime / totalTime) * 100,
        'south': (_southTime / totalTime) * 100,
        'south_west': (_southWestTime / totalTime) * 100,
        'west': (_westTime / totalTime) * 100,
        'north_west': (_northWestTime / totalTime) * 100,
      };
    }

    return {
      'session_id': sessionId,
      'duration_seconds': duration,
      'total_data_points': _recordedData.length,
      'final_score': score,
      'classification': classification,
      'summary': {
        'average_deviation': avgDeviation,
        'max_deviation': maxDeviation,
        'time_in_center_seconds': _timeInCenter,
        'average_jitter': _dataPointCount > 0 ? _totalJitter / _dataPointCount : 0.0,
      },
      'sector_analysis': sectorPercentages,
      'data_points': _recordedData,
    };
  }

  // --- Step 3: DELETE file/share logic. They are in ReportService ---
  // (Future<String?> _saveJsonToFile(...) is DELETED)
  // (Future<void> _shareReport(...) is DELETED)

  // --- Step 4: UPDATE _generateReport to use the service and new widget ---
  void _generateReport() async {
    if (_recordedData.isEmpty || _recordingStartTime == null) {
      _showErrorDialog('No data recorded');
      return;
    }

    // All calculation logic stays
    double durationSeconds = DateTime.now().difference(_recordingStartTime!).inMilliseconds / 1000.0;
    double avgDeviation = _sessionDataPoints > 0 ? _sessionTotalDeviation / _sessionDataPoints : 0.0;
    double maxDeviation = _sessionMaxDeviation;
    double sessionDeviationScore = (1.0 - avgDeviation.clamp(0.0, 1.0)) * 100.0;
    double sessionCenterTimeRatio = durationSeconds > 0 ? (_timeInCenter / durationSeconds) : 0.0;
    double sessionCenterScore = sessionCenterTimeRatio * 100.0;
    double overallSessionScore = (sessionDeviationScore * 0.7) + (sessionCenterScore * 0.3);
    overallSessionScore = overallSessionScore.clamp(0.0, 100.0);

    String classification;
    Color classificationColor;
    IconData classificationIcon;

    if (overallSessionScore >= 75) {
      classification = 'Highly Stable';
      classificationColor = Colors.blue;
      classificationIcon = Icons.check_circle_outline;
    } else if (overallSessionScore >= 50) {
      classification = 'Stable';
      classificationColor = Colors.green;
      classificationIcon = Icons.check_circle;
    } else {
      classification = 'Unstable';
      classificationColor = Colors.red;
      classificationIcon = Icons.cancel;
    }

    Map<String, dynamic> jsonReport = _createJsonReport(
      classification: classification,
      score: overallSessionScore,
      duration: durationSeconds,
      avgDeviation: avgDeviation,
      maxDeviation: maxDeviation,
    );

    // Use the service to save the file
    String? savedFilePath = await _reportService.saveJsonToFile(jsonReport);

    // Calculate sectorPercentages to pass to the new dialog
    double totalTime = _centerTime + _northTime + _northEastTime + _eastTime +
        _southEastTime + _southTime + _southWestTime + _westTime + _northWestTime;
    Map<String, double> sectorPercentages = {};
    if (totalTime > 0) {
      sectorPercentages = {
        'center': (_centerTime / totalTime) * 100,
        'north': (_northTime / totalTime) * 100,
        'north_east': (_northEastTime / totalTime) * 100,
        'east': (_eastTime / totalTime) * 100,
        'south_east': (_southEastTime / totalTime) * 100,
        'south': (_southTime / totalTime) * 100,
        'south_west': (_southWestTime / totalTime) * 100,
        'west': (_westTime / totalTime) * 100,
        'north_west': (_northWestTime / totalTime) * 100,
      };
    }

    if (!mounted) return;

    // Show the new dialog from left_right_widgets.dart
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionReportDialog(
        classification: classification,
        score: overallSessionScore,
        duration: durationSeconds,
        dataPoints: _recordedData.length,
        avgDeviation: avgDeviation,
        maxDeviation: maxDeviation,
        timeInCenter: _timeInCenter,
        color: classificationColor,
        icon: classificationIcon,
        filePath: savedFilePath,
        sectorPercentages: sectorPercentages,
      ),
    );
  }

  // --- Step 5: DELETE ALL UI-building methods ---
  // (_buildHeatmapWidget DELETED)
  // (_buildSectorLabel DELETED)
  // (_buildLegendItem DELETED)
  // (_showReportDialog DELETED)
  // (_buildReportRow DELETED)
  // (_buildScoreDisplay DELETED)
  // (_buildControlButtons DELETED)
  // (_buildStatusIndicators DELETED)
  // (_buildSensorDataDisplay DELETED)
  // (_buildCircleVisualization DELETED)

  // --- Helper methods for logic/state (These stay) ---
  Color _getMovementColor() {
    double distance = sqrt(circleX * circleX + circleY * circleY);

    if (distance < 0.15) {
      return Colors.green;
    }

    if (circleY.abs() > circleX.abs()) {
      return circleY < 0 ? Colors.purple : Colors.orange;
    } else {
      return circleX < 0 ? Colors.blue : Colors.red;
    }
  }

  String _getMovementText() {
    double distance = sqrt(circleX * circleX + circleY * circleY);

    if (distance < 0.15) {
      return 'CENTER (Roll: ${currentRoll.toStringAsFixed(1)}°, Pitch: ${currentPitch.toStringAsFixed(1)}°)';
    }

    String horizontalDir = '';
    String verticalDir = '';

    if (circleX < -0.3) {
      horizontalDir = 'STRONG LEFT';
    } else if (circleX < -0.15) {
      horizontalDir = 'LEFT';
    } else if (circleX > 0.3) {
      horizontalDir = 'STRONG RIGHT';
    } else if (circleX > 0.15) {
      horizontalDir = 'RIGHT';
    }

    if (circleY < -0.3) {
      verticalDir = 'STRONG UP';
    } else if (circleY < -0.15) {
      verticalDir = 'UP';
    } else if (circleY > 0.3) {
      verticalDir = 'STRONG DOWN';
    } else if (circleY > 0.15) {
      verticalDir = 'DOWN';
    }

    String direction = '';
    if (verticalDir.isNotEmpty && horizontalDir.isNotEmpty) {
      direction = '$verticalDir-$horizontalDir';
    } else if (verticalDir.isNotEmpty) {
      direction = verticalDir;
    } else if (horizontalDir.isNotEmpty) {
      direction = horizontalDir;
    }

    return '$direction (Roll: ${currentRoll.toStringAsFixed(1)}°, Pitch: ${currentPitch.toStringAsFixed(1)}°)';
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // --- Step 6: UPDATE the build() method to use the new widgets ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('4-Direction Tilt Detector'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Use the new widget
              StatusIndicators(
                isConnected: isConnected,
                isReading: _isReading,
              ),
              SizedBox(height: 20),

              // Use the new widget
              ControlButtons(
                isConnected: isConnected,
                isReading: _isReading,
                onStart: _startReading, // Pass the method reference
                onStop: _stopReading,   // Pass the method reference
              ),
              SizedBox(height: 20),

              if (_isRecording && _isReading) ...[
                // Use the new widget
                StabilityScoreDisplay(currentScore: _currentScore),
                SizedBox(height: 20),
              ],

              if (_isReading)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _getMovementColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getMovementText(), // Call state method
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getMovementColor(), // Call state method
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Position: X: ${(circleX * 100).toStringAsFixed(1)}%, Y: ${(circleY * 100).toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 25),

              // Use the new widget
              CircleVisualization(
                circleX: circleX,
                circleY: circleY,
                outerCircleRadius: outerCircleRadius,
                innerCircleRadius: innerCircleRadius,
                smallCircleRadius: smallCircleRadius,
                movementColor: _getMovementColor(), // Pass result of state method
              ),

              SizedBox(height: 20),

              if (_isReading) ...[
                // Use the new widget
                SensorDataDisplay(
                  angle: angle,
                  ax: ax,
                  ay: ay,
                  az: az,
                  gx: gx,
                  gy: gy,
                  gz: gz,
                ),
                SizedBox(height: 15),
              ],

              if (!_isReading) ...[
                SizedBox(height: 30),
                Text(
                  'Press START to begin tilt detection',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Tilt the device in any direction and the circle will move accordingly.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

