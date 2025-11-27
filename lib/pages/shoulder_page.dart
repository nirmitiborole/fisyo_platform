import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';

class ShoulderPage extends StatefulWidget {
  final BluetoothDevice device;

  ShoulderPage({required this.device});

  @override
  _ShoulderPageState createState() => _ShoulderPageState();
}

class _ShoulderPageState extends State<ShoulderPage> {
  BluetoothCharacteristic? _shoulderCharacteristic;
  List<double> _receivedValues = List.filled(7, 0.0);
  bool _isReading = false;
  bool _isConnected = false;
  List<List<FlSpot>> _graphData = List.generate(7, (_) => []);
  Timer? _readTimer;
  StreamSubscription? _connectionStateSubscription;

  double _minY = 0.0;
  double _maxY = 50.0;

  @override
  void initState() {
    super.initState();
    _monitorConnectionState();
    _discoverCharacteristics();
  }

  @override
  void dispose() {
    stopReading();
    _connectionStateSubscription?.cancel();
    // Don't disconnect here - let user navigate back naturally
    super.dispose();
  }

  // Monitor connection state continuously
  void _monitorConnectionState() {
    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          _isConnected = (state == BluetoothConnectionState.connected);
        });

        if (!_isConnected) {
          print('Device disconnected!');
          stopReading();
          _showErrorDialog('Device disconnected. Please reconnect.');
        } else {
          print('Device connected!');
        }
      }
    });
  }

  // Discover characteristics without reconnecting
  Future<void> _discoverCharacteristics() async {
    try {
      // Check if already connected
      var connectionState = await widget.device.connectionState.first;

      if (connectionState != BluetoothConnectionState.connected) {
        print('Device not connected. Attempting to connect...');
        await widget.device.connect(timeout: Duration(seconds: 15));
        await Future.delayed(Duration(seconds: 2)); // Wait for stable connection
      }

      print('Discovering services...');
      List<BluetoothService> services = await widget.device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == 'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
            setState(() {
              _shoulderCharacteristic = characteristic;
            });
            print('✓ Found shoulder characteristic: ${characteristic.uuid}');
            return;
          }
        }
      }

      throw Exception('Required characteristic not found');
    } catch (e) {
      print('Discovery error: $e');
      if (mounted) {
        _showErrorDialog('Failed to discover sensor: $e');
      }
    }
  }

  Future<void> startReading() async {
    if (_shoulderCharacteristic == null) {
      _showErrorDialog('Characteristic not found. Please reconnect.');
      return;
    }

    if (!_isConnected) {
      _showErrorDialog('Device not connected. Please reconnect.');
      return;
    }

    if (_isReading) return;

    setState(() => _isReading = true);

    _readTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      if (!mounted || !_isConnected) {
        stopReading();
        return;
      }

      try {
        // Check connection before reading
        var state = await widget.device.connectionState.first.timeout(
          Duration(seconds: 1),
          onTimeout: () => BluetoothConnectionState.disconnected,
        );

        if (state != BluetoothConnectionState.connected) {
          print('Device disconnected during read');
          stopReading();
          return;
        }

        final data = await _shoulderCharacteristic!.read().timeout(
          Duration(seconds: 2),
          onTimeout: () {
            print('Read timeout');
            return [];
          },
        );

        if (data.isNotEmpty && mounted) {
          final values = _convertBytesToValues(data);
          setState(() {
            _receivedValues = values;

            for (int i = 0; i < 7; i++) {
              _graphData[i].add(FlSpot(
                _graphData[i].length.toDouble(),
                values[i],
              ));
              if (_graphData[i].length > 5000) _graphData[i].removeAt(0);
            }
            _updateGraphBounds();
          });

          print('Received Shoulder Data: ${values.join(', ')}');
        }
      } catch (e) {
        print('Error reading data: $e');
        if (e.toString().contains('disconnected') ||
            e.toString().contains('requestMtu')) {
          if (mounted) {
            stopReading();
            _showErrorDialog('Connection lost. Please reconnect the device.');
          }
        }
      }
    });

    print('Started reading shoulder data every 500ms.');
  }

  void stopReading() {
    _readTimer?.cancel();
    _readTimer = null;

    if (mounted) {
      setState(() => _isReading = false);
    }
    print('Stopped reading shoulder data.');
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

  void _updateGraphBounds() {
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var data in _graphData) {
      for (var spot in data) {
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
      }
    }

    setState(() {
      _minY = minY - 5;
      _maxY = maxY + 5;
    });

    print('Updated Shoulder Graph Bounds: MinY = $_minY, MaxY = $_maxY');
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
        title: Text('Shoulder: ${widget.device.name}'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connection warning banner
            if (!_isConnected)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
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
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Shoulder Value',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '${_receivedValues[0].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 50,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: (_isReading || !_isConnected) ? null : startReading,
                  child: Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _isReading ? stopReading : null,
                  child: Text('Stop'),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildLegend(),
            SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: _minY,
                  maxY: _maxY,
                  lineBarsData: List.generate(7, (i) {
                    return LineChartBarData(
                      spots: _graphData[i],
                      isCurved: true,
                      color: _getColor(i),
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    const labels = [
      'Shoulder Angle',
      'Ax',
      'Ay',
      'Az',
      'Gyro X',
      'Gyro Y',
      'Gyro Z',
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: List.generate(7, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              color: _getColor(i),
            ),
            SizedBox(width: 4),
            Text(
              labels[i],
              style: TextStyle(fontSize: 14),
            ),
          ],
        );
      }),
    );
  }

  Color _getColor(int index) {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.brown,
    ];
    return colors[index % colors.length];
  }
}
