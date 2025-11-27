import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MotionDetectorScreen extends StatefulWidget {
  final BluetoothDevice device;

  MotionDetectorScreen({required this.device});

  @override
  _MotionDetectorScreenState createState() => _MotionDetectorScreenState();
}

class _MotionDetectorScreenState extends State<MotionDetectorScreen> {
  static const platform = MethodChannel('motion_detector');

  BluetoothCharacteristic? _motionCharacteristic;
  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription? _connectionStateSubscription;
  Timer? _predictionTimer;

  List<double> _accelerometerData = [0.0, 0.0, 0.0];
  List<double> _gyroscopeData = [0.0, 0.0, 0.0];
  bool _isMoving = false;
  String _statusText = 'Initializing...';
  bool _isReading = false;
  bool _isConnected = false;

  List<List<double>> _dataBuffer = [];
  final int _bufferSize = 5;

  List<Map<String, double>> _collectedData = [];

  @override
  void initState() {
    super.initState();
    _monitorConnectionState();
    _discoverCharacteristics();
    _initializeModel();
  }

  void _monitorConnectionState() {
    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          _isConnected = (state == BluetoothConnectionState.connected);
        });

        if (!_isConnected) {
          print('Device disconnected!');
          stopSensing();
          setState(() {
            _statusText = 'Device disconnected';
          });
        } else {
          print('Device connected!');
        }
      }
    });
  }

  Future<void> _discoverCharacteristics() async {
    try {
      var connectionState = await widget.device.connectionState.first;

      if (connectionState != BluetoothConnectionState.connected) {
        print('Device not connected. Attempting to connect...');
        await widget.device.connect(timeout: Duration(seconds: 15));
        await Future.delayed(Duration(seconds: 2));
      }

      print('Discovering services...');
      List<BluetoothService> services = await widget.device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == 'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
            _motionCharacteristic = characteristic;
            print('✓ Found motion characteristic: ${characteristic.uuid}');

            print('--- Checking Characteristic Properties ---');
            if (characteristic.properties.notify) {
              print('✅ SUCCESS: This characteristic supports NOTIFICATIONS.');
            } else {
              print('❌ INFO: This characteristic does NOT support notifications.');
            }
            if (characteristic.properties.read) {
              print('ℹ️ INFO: This characteristic supports READ.');
            }
            print('-----------------------------------------');

            setState(() {
              _statusText = 'Ready to Start';
            });
            return;
          }
        }
      }

      throw Exception('Required characteristic not found');
    } catch (e) {
      print('Discovery error: $e');
      if (mounted) {
        setState(() {
          _statusText = 'Connection failed';
        });
      }
    }
  }

  Future<void> _initializeModel() async {
    try {
      await platform.invokeMethod('initializeModel');
      print('Model loaded successfully');
    } on PlatformException catch (e) {
      setState(() {
        _statusText = 'Failed to load model: ${e.message}';
      });
      print('Error initializing model: $e');
    }
  }

  void startSensing() async {
    if (_motionCharacteristic == null) {
      _showSnackBar('Characteristic not found. Please reconnect.');
      return;
    }

    if (!_isConnected) {
      _showSnackBar('Device not connected. Please reconnect.');
      return;
    }

    if (_isReading) return;

    setState(() {
      _isReading = true;
      _statusText = 'STILL';
    });

    try {
      await _motionCharacteristic!.setNotifyValue(true);

      _valueSubscription = _motionCharacteristic!.onValueReceived.listen((data) {
        if (!mounted || !_isConnected) return;

        if (data.isNotEmpty) {
          final values = _convertBytesToValues(data);
          if (values.length >= 7) {
            setState(() {
              _accelerometerData = [values[1], values[2], values[3]];
              _gyroscopeData = [values[4], values[5], values[6]];

              final Map<String, double> currentReading = {
                'ax': _accelerometerData[0],
                'ay': _accelerometerData[1],
                'az': _accelerometerData[2],
                'gx': _gyroscopeData[0],
                'gy': _gyroscopeData[1],
                'gz': _gyroscopeData[2],
              };
              _collectedData.add(currentReading);
            });
          }
        }
      }, onError: (e) {
        print("Error listening to sensor data: $e");
        stopSensing();
      });

      _predictionTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
        if (!_isReading || !_isConnected) {
          timer.cancel();
          return;
        }
        _updateDataBuffer();
        _predictMotion();
      });
    } catch (e) {
      print('Error starting notifications: $e');
      if (mounted) {
        setState(() {
          _isReading = false;
          _statusText = 'Failed to start';
        });
      }
    }
  }

  void stopSensing() async {
    print('Stopping sensing...');

    // Cancel prediction timer first
    _predictionTimer?.cancel();
    _predictionTimer = null;

    // Cancel value subscription
    await _valueSubscription?.cancel();
    _valueSubscription = null;

    // Try to disable notifications (only if still connected)
    if (_isConnected && _motionCharacteristic != null) {
      try {
        await _motionCharacteristic!.setNotifyValue(false);
        print('Notifications disabled successfully');
      } catch (e) {
        print("Could not unsubscribe from notifications: $e");
      }
    }

    if (mounted) {
      setState(() {
        _isReading = false;
        _statusText = 'Stopped';
      });
    }

    print('Sensing stopped cleanly');
  }

  Future<void> saveAndShareJsonFile() async {
    if (_collectedData.isEmpty) {
      _showSnackBar('No data collected yet! Start sensing first.');
      return;
    }

    final jsonEncoder = JsonEncoder.withIndent('  ');
    final jsonString = jsonEncoder.convert(_collectedData);

    try {
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName = 'motion_data_${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}.json';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsString(jsonString);
      print('File saved to: $filePath');

      await Share.shareXFiles([XFile(filePath)], text: 'Here is my collected sensor data!');

    } catch (e) {
      print('Error saving or sharing file: $e');
      _showSnackBar('Error: Could not save or share the file.');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  List<double> _convertBytesToValues(List<int> data) {
    try {
      String dataString = utf8.decode(data).trim();
      List<String> stringValues = dataString.split(',');
      return stringValues.map((str) => double.tryParse(str) ?? 0.0).toList();
    } catch (e) {
      print('Error converting bytes to values: $e');
      return List.filled(7, 0.0);
    }
  }

  void _updateDataBuffer() {
    List<double> currentData = [..._accelerometerData, ..._gyroscopeData];
    _dataBuffer.add(currentData);
    if (_dataBuffer.length > _bufferSize) {
      _dataBuffer.removeAt(0);
    }
  }

  Future<void> _predictMotion() async {
    if (_dataBuffer.length < _bufferSize) return;

    List<double> avgData = List.filled(6, 0.0);
    for (var data in _dataBuffer) {
      for (int i = 0; i < 6; i++) {
        avgData[i] += data[i];
      }
    }
    for (int i = 0; i < 6; i++) {
      avgData[i] /= _dataBuffer.length;
    }

    try {
      final result =
      await platform.invokeMethod('predictMotion', {'sensorData': avgData});
      bool isMoving = result['isMoving'];
      if (mounted) {
        setState(() {
          _isMoving = isMoving;
          if (_isReading) {
            _statusText = isMoving ? 'MOVING' : 'STILL';
          }
        });
      }
    } on PlatformException catch (e) {
      print('Error predicting motion: $e');
      if (mounted) {
        setState(() {
          _statusText = 'Prediction error';
        });
      }
    }
  }

  @override
  void dispose() {
    print('MotionDetector dispose called');
    stopSensing();
    _connectionStateSubscription?.cancel();
    // Don't disconnect - let other pages use the connection
    super.dispose();
  }

  Widget _buildMotionIndicator() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isMoving ? Colors.red : Colors.green,
        boxShadow: [
          BoxShadow(
            color: (_isMoving ? Colors.red : Colors.green).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _isMoving ? Icons.directions_run : Icons.accessibility_new,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildSensorValues() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Sensor Values',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ax: ${_accelerometerData[0].toStringAsFixed(2)}'),
                  Text('Ay: ${_accelerometerData[1].toStringAsFixed(2)}'),
                  Text('Az: ${_accelerometerData[2].toStringAsFixed(2)}'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gx: ${_gyroscopeData[0].toStringAsFixed(2)}'),
                  Text('Gy: ${_gyroscopeData[1].toStringAsFixed(2)}'),
                  Text('Gz: ${_gyroscopeData[2].toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Motion Detector: ${widget.device.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isConnected)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Device disconnected. Please go back and reconnect.',
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),
              _buildMotionIndicator(),
              SizedBox(height: 20),
              Text(
                'Collected Data Points: ${_collectedData.length}',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              SizedBox(height: 20),
              _buildSensorValues(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: (_isReading || !_isConnected) ? null : startSensing,
                    child: Text('Start'),
                    style: ElevatedButton.styleFrom(
                        padding:
                        EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                  ),
                  ElevatedButton(
                    onPressed: _isReading ? stopSensing : null,
                    child: Text('Stop'),
                    style: ElevatedButton.styleFrom(
                        padding:
                        EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                  ),
                ],
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isReading ? null : saveAndShareJsonFile,
                child: Text('Save & Export JSON'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
