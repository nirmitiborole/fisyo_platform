import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:just_audio/just_audio.dart';

// --- Step 1: Import your new separated files ---
import './left_right/report_service.dart';
import './left_right/circular_heatmap_painter.dart';
import './left_right/left_right_widgets.dart';

// --- SensorDataPoint class ---
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
  final Map<String, dynamic>? patientData;

  LeftRight({
    required this.device,
    this.patientData,
  });

  @override
  _LeftRightState createState() => _LeftRightState();
}

class _LeftRightState extends State<LeftRight> with TickerProviderStateMixin {
  // --- Step 2: Instantiate your service ---
  final ReportService _reportService = ReportService();

  // --- Audio Player ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioEnabled = false;
  Timer? _beepTimer;

  // --- Patient Data ---
  Map<String, dynamic>? _patientData;

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
    _patientData = widget.patientData;
    _animationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _positionAnimation = Tween<Offset>(begin: Offset(0.0, 0.0), end: Offset(0.0, 0.0)).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initAudio();
    _connectToDevice();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/beep.mp3');
      await _audioPlayer.setVolume(1.0);
      print('Audio initialized successfully');
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  @override
  void dispose() {
    _stopReading();
    _beepTimer?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    widget.device.disconnect();
    super.dispose();
  }

  // --- Audio Control Methods ---
  void _toggleAudio() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });

    print('🔊 Audio toggled: $_isAudioEnabled');

    if (_isAudioEnabled && _isReading) {
      // Start beeping immediately if reading is active
      _updateBeepRate();
    } else {
      // Stop beeping
      _beepTimer?.cancel();
      _beepTimer = null;
      _audioPlayer.stop();
    }
  }

  void _updateBeepRate() {
    if (!_isAudioEnabled || !_isReading) {
      _beepTimer?.cancel();
      _beepTimer = null;
      return;
    }

    // Cancel existing timer
    _beepTimer?.cancel();

    // Use current score to determine beep frequency
    // Score ranges from 0-100
    // High score (stable) = slow/no beeps
    // Low score (unstable) = fast beeps

    if (_currentScore >= 90) {
      // Very stable - very slow beeps (1500ms)
      _beepTimer = null;
      print('⚪ Very stable (Score: ${_currentScore.toStringAsFixed(1)}) - no beep');
      return;
    }

    int beepInterval;

    if (_currentScore >= 80) {
      // Slightly unstable - slow beeps (1200ms)
      beepInterval = 1200;
    } else if (_currentScore >= 70) {
      // Moderately unstable - medium-slow beeps (900ms)
      beepInterval = 900;
    } else if (_currentScore >= 60) {
      // Quite unstable - medium beeps (700ms)
      beepInterval = 700;
    } else if (_currentScore >= 50) {
      // Unstable - medium-fast beeps (500ms)
      beepInterval = 500;
    } else if (_currentScore >= 40) {
      // Very unstable - fast beeps (350ms)
      beepInterval = 350;
    } else {
      // Extremely unstable - very fast beeps (200ms)
      beepInterval = 200;
    }

    print('🔊 BEEP - Score: ${_currentScore.toStringAsFixed(1)}, Interval: $beepInterval ms');

    _beepTimer = Timer.periodic(Duration(milliseconds: beepInterval), (timer) async {
      if (_isAudioEnabled && _isReading && mounted) {
        try {
          await _audioPlayer.seek(Duration.zero);
          await _audioPlayer.play();
        } catch (e) {
          print('❌ Error playing beep: $e');
        }
      } else {
        timer.cancel();
      }
    });
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

    // Start beeping if audio is enabled
    if (_isAudioEnabled) {
      _updateBeepRate();
    }

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
    _beepTimer?.cancel();
    _beepTimer = null;
    _audioPlayer.stop();

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
    double positionX = -rollAngle / 20.0;
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

          // Update beep rate every 5th reading to reduce overhead
          if (_recordedData.length % 5 == 0) {
            _updateBeepRate();
          }
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
    if (!mounted) return;

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
      'patient_name': _patientData?['name'] ?? 'Unknown',
      'patient_id': _patientData?['id'] ?? 'N/A',
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

  void _generateReport() async {
    if (_recordedData.isEmpty || _recordingStartTime == null) {
      _showErrorDialog('No data recorded');
      return;
    }

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

    String? savedFilePath = await _reportService.saveJsonToFile(jsonReport);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance Measurement', style: TextStyle(fontSize: 18)),
            if (_patientData != null)
              Text(
                _patientData!['name'],
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
          ],
        ),
        backgroundColor: Color(0xFF6A1B9A),
        actions: [
          // TEST BEEP BUTTON
          IconButton(
            icon: Icon(Icons.music_note),
            onPressed: () async {
              try {
                await _audioPlayer.seek(Duration.zero);
                await _audioPlayer.play();
                print('TEST beep played');
              } catch (e) {
                print('TEST beep error: $e');
              }
            },
          ),
          // AUDIO TOGGLE BUTTON
          IconButton(
            icon: Icon(
              _isAudioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              size: 28,
            ),
            onPressed: _toggleAudio,
            tooltip: _isAudioEnabled ? 'Mute Audio' : 'Enable Audio',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusIndicators(
                isConnected: isConnected,
                isReading: _isReading,
              ),
              SizedBox(height: 20),

              ControlButtons(
                isConnected: isConnected,
                isReading: _isReading,
                onStart: _startReading,
                onStop: _stopReading,
              ),
              SizedBox(height: 20),

              if (_isRecording && _isReading) ...[
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
                        _getMovementText(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getMovementColor(),
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

              CircleVisualization(
                circleX: circleX,
                circleY: circleY,
                outerCircleRadius: outerCircleRadius,
                innerCircleRadius: innerCircleRadius,
                smallCircleRadius: smallCircleRadius,
                movementColor: _getMovementColor(),
              ),

              SizedBox(height: 20),

              if (_isReading) ...[
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
