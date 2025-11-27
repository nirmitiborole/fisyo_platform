import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceDataPage extends StatefulWidget {
  final BluetoothDevice device;
  final String title;
  final String sendString;

  DeviceDataPage({
    required this.device,
    required this.title,
    required this.sendString,
  });

  @override
  _DeviceDataPageState createState() => _DeviceDataPageState();
}

class _DeviceDataPageState extends State<DeviceDataPage> {
  BluetoothCharacteristic? _characteristic;
  String receivedData = "";

  @override
  void initState() {
    super.initState();
    _connectAndSendData();
  }

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }

  Future<void> _connectAndSendData() async {
    try {
      await widget.device.connect();
      List<BluetoothService> services = await widget.device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            _characteristic = characteristic;
            await _sendData(
                widget.sendString); // Send the string (e.g., "Wrist")
            _startListening(); // Start listening for incoming data
            return;
          }
        }
      }
      _showErrorDialog('Writable characteristic not found');
    } catch (e) {
      _showErrorDialog('Connection failed: $e');
    }
  }

  Future<void> _sendData(String data) async {
    if (_characteristic == null) return;
    try {
      await _characteristic!.write(utf8.encode(data), withoutResponse: true);
      print("Sent: $data");
    } catch (e) {
      print("Error sending data: $e");
    }
  }

  void _startListening() {
    if (_characteristic == null) return;
    _characteristic!.setNotifyValue(true);
    _characteristic!.value.listen((value) {
      String dataString = utf8.decode(value).trim();
      setState(() {
        receivedData = dataString;
      });
      print("Received: $dataString");
    });
  }

  void _showErrorDialog(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sent Command: ${widget.sendString}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "Received Data:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              receivedData.isNotEmpty ? receivedData : "No data received yet.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}