import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class DeviceConnectPage extends StatefulWidget {
  BluetoothDevice? device;

  DeviceConnectPage({super.key, required this.device});

  @override
  _DeviceConnectPageState createState() => _DeviceConnectPageState();
}

class _DeviceConnectPageState extends State<DeviceConnectPage> {
  BluetoothDevice? device;
  late List<BluetoothService> services;
  String lastSentText = '';
  String lastReceivedText = '';
  final TextEditingController textController = TextEditingController();
  String name = "";
  String connectionStatus = 'Disconnected';
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  Future<void> connectToDevice() async {
    try {
      setState(() {
        connectionStatus = 'Connecting...';
      });
      var subscription = widget.device?.connectionState
          .listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.connected) {
          print('Connected to the device!');
        }
      });
      device?.cancelWhenDisconnected(subscription!, delayed: true, next: true);
      await widget.device?.connect();
      name = widget.device!.advName;
      setState(() {
        isConnected = true;
        connectionStatus = 'Connected';
      });
      refreshDevices(name, widget.device!.remoteId.toString());
      services = (await widget.device?.discoverServices())!;
      subscription?.cancel();
    } catch (e) {
      setState(() {
        connectionStatus = 'Connection Failed';
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Error'),
          content:
              Text('Failed to connect to ${widget.device?.advName}. Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> disConnectDevice() async {
    await widget.device?.disconnect();
    disConnect();
  }

  void disConnect() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Disconnected from the device!"),
          actions: [
            TextButton(
              child: const Text("Ok"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> saveDevice(String deviceName, String deviceID) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedDevices = prefs.getStringList('savedDevices') ?? [];

    bool isDeviceSaved =
        savedDevices.any((device) => device.contains(deviceID));

    if (!isDeviceSaved) {
      savedDevices.add('$deviceName:$deviceID');
      await prefs.setStringList('savedDevices', savedDevices);
    } else {
      print('The device is already registered');
    }
  }

  void refreshDevices(String deviceName, String deviceID) {
    setState(() {
      saveDevice(deviceName, deviceID);
    });
  }

  void sendData(String data) async {
    try {
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write(data.codeUnits);
            setState(() {
              lastSentText = data;
            });
          }
        }
      }
      receiveData(widget.device);
    } catch (e) {
      print('Error sending data: $e');
    }
  }

  void receiveData(BluetoothDevice? device) async {
    try {
      var services = await device?.discoverServices();
      for (var service in services!) {
        for (var characteristic in service.characteristics) {
          print('Characteristic UUID: ${characteristic.uuid}');
          if (characteristic.properties.read) {
            print('Characteristic supports read');
            characteristic.lastValueStream.listen((value) {
              setState(() {
                lastReceivedText = String.fromCharCodes(value);
                print('Received data: $lastReceivedText');
              });
            });
            await characteristic.setNotifyValue(true);
          } else {
            print('Characteristic does not support read');
          }
        }
      }
    } catch (e) {
      print('Error receiving data: $e');
    }
  }

  @override
  void dispose() {
    if (isConnected && device != null) {
      device!.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled_outlined),
            color: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
              disConnectDevice();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              connectionStatus,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (isConnected) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              hintText: 'Enter text to send',
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.red, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.red, width: 2),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15)),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 10),
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
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          child: IconButton(
                            onPressed: () {
                              if (textController.text.isNotEmpty) {
                                sendData(textController.text);
                                textController.clear();
                              }
                            },
                            icon: const Icon(Icons.send_outlined),
                            color: Colors.white,
                            iconSize: 25,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Last sent text: $lastSentText',
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Response: $lastReceivedText',
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
