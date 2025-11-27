import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'buttons_page.dart';

class BLEPage extends StatefulWidget {
  @override
  _BLEPageState createState() => _BLEPageState();
}

class _BLEPageState extends State<BLEPage> {
  List<BluetoothDevice> devicesList = [];
  StreamSubscription? scanSubscription;
  bool isScanning = false;
  bool isConnecting = false;
  String scanMessage = '';
  final String targetUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (statuses.values.any((status) => !status.isGranted)) {
      setState(() {
        scanMessage = 'Please grant all permissions to scan for devices.';
      });
    } else {
      _initializeBluetooth();
    }
  }

  Future<void> _initializeBluetooth() async {
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      } else {
        setState(() {
          scanMessage = 'Bluetooth is ${state.name}. Please enable it.';
        });
      }
    });

    if (await FlutterBluePlus.isAvailable == false) {
      setState(() {
        scanMessage = 'Bluetooth is not available on this device.';
      });
    }
  }

  void _startScan() {
    setState(() {
      isScanning = true;
      devicesList.clear();
      scanMessage = 'Scanning for devices...';
    });

    FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
    scanSubscription = FlutterBluePlus.scanResults.listen(
          (results) {
        setState(() {
          for (ScanResult result in results) {
            if (!devicesList.any((device) => device.id == result.device.id)) {
              devicesList.add(result.device);
            }
          }
          scanMessage = devicesList.isEmpty ? 'No devices found.' : '';
        });
      },
      onError: (e) {
        setState(() {
          scanMessage = 'Error during scanning: $e';
          isScanning = false;
        });
      },
      onDone: () {
        setState(() {
          isScanning = false;
        });
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (isConnecting) return; // Prevent multiple connection attempts

    setState(() {
      isConnecting = true;
      scanMessage = 'Connecting to ${device.name.isEmpty ? 'device' : device.name}...';
    });

    try {
      // Check if already connected
      var currentState = await device.connectionState.first;

      if (currentState == BluetoothConnectionState.connected) {
        print('Already connected to ${device.name}');
      } else {
        // Connect with timeout
        print('Attempting to connect...');
        await device.connect(
          timeout: Duration(seconds: 15),
          autoConnect: false,
        );
        print('Connection established');
      }

      // Wait for connection to stabilize
      await Future.delayed(Duration(seconds: 2));

      // Verify connection is stable
      currentState = await device.connectionState.first;
      if (currentState != BluetoothConnectionState.connected) {
        throw Exception('Connection not stable');
      }

      // Discover services
      print('Discovering services...');
      List<BluetoothService> services = await device.discoverServices();
      print('Found ${services.length} services');

      // Find target characteristic
      BluetoothCharacteristic? targetCharacteristic;

      for (BluetoothService service in services) {
        print('Service UUID: ${service.uuid}');
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          print('  Characteristic UUID: ${characteristic.uuid}');
          if (characteristic.uuid.toString() == targetUUID) {
            targetCharacteristic = characteristic;
            print('✓ Found target characteristic!');
            break;
          }
        }
        if (targetCharacteristic != null) break;
      }

      if (targetCharacteristic == null) {
        throw Exception('Target UUID not found on ${device.name.isEmpty ? 'device' : device.name}');
      }

      // Success - Navigate to next page
      setState(() {
        scanMessage = 'Connected successfully to ${device.name.isEmpty ? 'device' : device.name}';
        isConnecting = false;
      });

      // Wait a moment to show success message
      await Future.delayed(Duration(milliseconds: 500));

      // Navigate WITHOUT disconnecting
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ButtonsPage(
              device: device,
              characteristic: targetCharacteristic!,
            ),
          ),
        );
      }

    } catch (e) {
      print('Connection error: $e');

      // Disconnect only on error
      try {
        await device.disconnect();
      } catch (disconnectError) {
        print('Disconnect error: $disconnectError');
      }

      if (mounted) {
        setState(() {
          isConnecting = false;
          scanMessage = 'Failed to connect: ${e.toString()}';
        });

        // Show error dialog
        _showErrorDialog(
          'Connection Failed',
          'Could not connect to ${device.name.isEmpty ? 'device' : device.name}.\n\nError: ${e.toString()}\n\nPlease try again.',
        );
      }
    }
  }

  void _stopScan() {
    scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    setState(() {
      isScanning = false;
      scanMessage = 'Scan stopped.';
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
  void dispose() {
    _stopScan();
    super.dispose();
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
              // Professional Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
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
                                'Device Connection',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0C4A5E),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Select a BLE sensor to connect',
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
                    SizedBox(height: 20),

                    // Professional Scan Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: (isScanning || isConnecting)
                            ? Color(0xFFE8F5F8)
                            : Color(0xFF0C7C9E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isScanning || isConnecting)
                              ? Color(0xFFD5E3E8)
                              : Color(0xFF0C7C9E),
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (!isScanning && !isConnecting)
                            BoxShadow(
                              color: Color(0xFF0C7C9E).withOpacity(0.2),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (isScanning || isConnecting) ? null : _startScan,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: (isScanning || isConnecting)
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      Color(0xFF0C7C9E),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  isConnecting
                                      ? 'Connecting...'
                                      : 'Scanning for Devices...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0C7C9E),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bluetooth_searching_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Scan for Devices',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Message
              if (scanMessage.isNotEmpty)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scanMessage.contains('Error') ||
                        scanMessage.contains('Please grant') ||
                        scanMessage.contains('not found') ||
                        scanMessage.contains('Failed')
                        ? Color(0xFFFFF4F4)
                        : scanMessage.contains('Connected') ||
                        scanMessage.contains('successfully')
                        ? Color(0xFFF0F9F4)
                        : Color(0xFFF8FBFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scanMessage.contains('Error') ||
                          scanMessage.contains('Please grant') ||
                          scanMessage.contains('not found') ||
                          scanMessage.contains('Failed')
                          ? Color(0xFFFFD6D6)
                          : scanMessage.contains('Connected') ||
                          scanMessage.contains('successfully')
                          ? Color(0xFFD4EFE0)
                          : Color(0xFFD5E3E8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        scanMessage.contains('Error') ||
                            scanMessage.contains('Please grant') ||
                            scanMessage.contains('not found') ||
                            scanMessage.contains('Failed')
                            ? Icons.error_outline_rounded
                            : scanMessage.contains('Connected') ||
                            scanMessage.contains('successfully')
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        color: scanMessage.contains('Error') ||
                            scanMessage.contains('Please grant') ||
                            scanMessage.contains('not found') ||
                            scanMessage.contains('Failed')
                            ? Color(0xFFD32F2F)
                            : scanMessage.contains('Connected') ||
                            scanMessage.contains('successfully')
                            ? Color(0xFF2E7D32)
                            : Color(0xFF0C7C9E),
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          scanMessage,
                          style: TextStyle(
                            color: scanMessage.contains('Error') ||
                                scanMessage.contains('Please grant') ||
                                scanMessage.contains('not found') ||
                                scanMessage.contains('Failed')
                                ? Color(0xFFD32F2F)
                                : scanMessage.contains('Connected') ||
                                scanMessage.contains('successfully')
                                ? Color(0xFF2E7D32)
                                : Color(0xFF0C4A5E),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Devices List Header
              if (devicesList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sensors_rounded,
                        color: Color(0xFF0C7C9E),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Available Sensors (${devicesList.length})',
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

              // Devices List Container
              Expanded(
                child: devicesList.isEmpty
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
                          Icons.bluetooth_disabled_rounded,
                          size: 64,
                          color: Color(0xFFB0C4CE),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No Devices Found',
                        style: TextStyle(
                          color: Color(0xFF0C4A5E),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the button above to scan for BLE sensors',
                        style: TextStyle(
                          color: Color(0xFF7A9AAA),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFE0E8EB),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF0C7C9E).withOpacity(0.08),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      itemCount: devicesList.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Color(0xFFE0E8EB),
                        height: 1,
                        thickness: 1,
                        indent: 68,
                      ),
                      itemBuilder: (context, index) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isConnecting
                                ? null
                                : () async {
                              _stopScan();
                              await _connectToDevice(
                                  devicesList[index]);
                            },
                            borderRadius: index == 0
                                ? BorderRadius.vertical(
                                top: Radius.circular(16))
                                : index == devicesList.length - 1
                                ? BorderRadius.vertical(
                                bottom: Radius.circular(16))
                                : BorderRadius.zero,
                            splashColor:
                            Color(0xFF0C7C9E).withOpacity(0.05),
                            highlightColor: Color(0xFFF8FBFC),
                            child: Opacity(
                              opacity: isConnecting ? 0.5 : 1.0,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 14.0,
                                ),
                                child: Row(
                                  children: [
                                    // Device Icon
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF0C7C9E),
                                            Color(0xFF1A9DBF),
                                          ],
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.bluetooth_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    SizedBox(width: 14),

                                    // Device Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            devicesList[index]
                                                .name
                                                .isEmpty
                                                ? 'Unnamed Device'
                                                : devicesList[index].name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0C4A5E),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            devicesList[index]
                                                .id
                                                .toString(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF7A9AAA),
                                              letterSpacing: 0.1,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Arrow Icon
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFFB0C4CE),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
