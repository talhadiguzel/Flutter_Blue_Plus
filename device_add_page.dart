import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_connect_page.dart';

class DeviceAddPage extends StatefulWidget {
  const DeviceAddPage({super.key});

  @override
  _DeviceAddPageState createState() => _DeviceAddPageState();
}

class _DeviceAddPageState extends State<DeviceAddPage> {
  List<BluetoothDevice> devices = [];
  List<BluetoothDevice> filteredDevices = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    startScanning();
    filteredDevices = devices;
    _searchController.addListener(() {
      _filterDevices();
    });
  }

  void startScanning() {
    setState(() {
      devices.clear();
      filteredDevices.clear();
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devices.contains(result.device)) {
          setState(() {
            devices.add(result.device);
          });
        }
      }
    }, onDone: () {
      FlutterBluePlus.stopScan();
    });
  }

  void _filterDevices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredDevices = devices
          .where((device) => device.advName.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Find Device',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search Devices',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.red,
              onRefresh: () async {
                setState(() {
                  startScanning();
                });
              },
              child: ListView.builder(
                itemCount: filteredDevices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(filteredDevices[index].advName),
                    subtitle: Text(filteredDevices[index].remoteId.toString()),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceConnectPage(
                              device: filteredDevices[index],
                            ),
                          ));
                    },
                  );
                },
              ),
            ),
          ),
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
              onPressed: startScanning,
              icon: const Icon(Icons.bluetooth_audio_outlined),
              color: Colors.white,
              iconSize: 30,
            ),
          ),
        ]));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
