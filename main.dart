import 'dart:async';
import 'dart:io';

import 'package:blue/device_connect_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_add_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BleScanner(),
    );
  }
}

class BleScanner extends StatefulWidget {
  const BleScanner({super.key});

  @override
  _BleScannerState createState() => _BleScannerState();
}

class _BleScannerState extends State<BleScanner> {
  void blu_on_off() async {
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }
    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print(state);
      if (state == BluetoothAdapterState.on) {
        scanDevice();
      } else {
        _showBluetoothOff();
      }
    });
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
    subscription.cancel();
  }

  void _showBluetoothOff() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bluetooth Kapalı"),
          content: const Text("Lütfen Bluetooth'u açın."),
          actions: [
            TextButton(
              child: const Text("Tamam"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> getSavedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('savedDevices') ?? [];
  }

  List<String> saveD = [];
  List<BluetoothDevice> fondDevices = [];

  void refreshSavedDevices() {
    getSavedDevices().then((devices) {
      setState(() {
        saveD = devices;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    blu_on_off();
    scanDevice();
    refreshSavedDevices();
  }

  Future<void> deleteDevice(String deviceAddress) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedDevices = prefs.getStringList('savedDevices') ?? [];
    savedDevices.removeWhere((device) => device.contains(deviceAddress));
    await prefs.setStringList('savedDevices', savedDevices);
    refreshSavedDevices();
  }

  void scanDevice() {
    setState(() {
      fondDevices.clear();
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!fondDevices.contains(result.device)) {
          setState(() {
            fondDevices.add(result.device);
          });
        }
      }
    }, onDone: () => FlutterBluePlus.stopScan());
  }

  BluetoothDevice? findDevice(String deviceId) {
    for (BluetoothDevice device in fondDevices) {
      if (device.remoteId.toString() == deviceId) {
        abc(device.remoteId.toString());
        return device;
      }
    }
    return null;
  }

  void abc(devId) {
    ScaffoldMessenger.of(context).showSnackBar(
      new SnackBar(content: new Text(devId)),
    );
  }

  void onDeviceTap(String deviceId) async {
    BluetoothDevice? foundDevice = findDevice(deviceId);

    if (foundDevice == null) {
      print('Device not found.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device not found or connection error.')),
      );
    } else {
      print('Device found, navigating to DeviceConnectPage');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceConnectPage(device: foundDevice),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BLE Scanner',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.red,
              onRefresh: () async {
                refreshSavedDevices();
                scanDevice();
              },
              child: ListView.builder(
                itemCount: saveD.length,
                itemBuilder: (context, index) {
                  var device = saveD[index];
                  var splitDevice = device.split(":");
                  var deviceName = splitDevice[0];
                  var deviceAddress = splitDevice.sublist(1).join(':').trim();
                  return ListTile(
                    title: Text(deviceName),
                    subtitle: Text(deviceAddress),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      onPressed: () {
                        deleteDevice(deviceAddress);
                      },
                    ),
                    onTap: () {
                      onDeviceTap(deviceAddress);
                    },
                  );
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(255, 93, 0, 0),
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                margin: const EdgeInsets.all(16),
                width: 70,
                height: 70,
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DeviceAddPage()),
                    );
                  },
                  icon: const Icon(Icons.add_outlined),
                  color: Colors.white,
                  iconSize: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
