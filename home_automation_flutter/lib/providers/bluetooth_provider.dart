import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'dart:async';

class BluetoothProvider with ChangeNotifier {
  BluetoothConnection? connection;
  bool isConnected = false;
  Timer? _reconnectTimer;

  BluetoothProvider() {
    // inițializare și test de conexiune periodic
    connectToDevice();
    _startConnectionCheck();
  }
  bool checkConnection() {
    return connection != null && connection!.isConnected;
  }

  Future<void> connectToDevice() async {
    try {
      if (connection != null && connection!.isConnected) {
        print("Existing connection found.");
        return;
      }

      var devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      print("Paired devices:");
      for (var device in devices) {
        print("${device.name} - ${device.address}");
      }

      // cauta dispozitivul dupa nume
      BluetoothDevice? targetDevice;

      for (var device in devices) {
        if (device.name == "Home Automation") {
          targetDevice = device;
          break;
        }
      }

      if (targetDevice != null) {
        print("Trying to connect to ${targetDevice.address}...");
        connection = await BluetoothConnection.toAddress(targetDevice.address);
      } else {
        print("Device not found by name. Trying direct MAC address...");
        connection = await BluetoothConnection.toAddress("cc:db:a7:68:69:bc");
      }

      if (connection != null && connection!.isConnected) {
        isConnected = true;
        print('Connected to Home Automation');

        connection!.input!.listen(null).onDone(() {
          print('Disconnected by remote or local');
          isConnected = false;
          notifyListeners();
        });
      } else {
        print('Connection failed. Device not reachable.');
      }
    } catch (e) {
      print('Cannot connect, exception occurred');
      print(e);
    }
    notifyListeners();
  }

  void _startConnectionCheck() {
    _reconnectTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      if (connection == null || !connection!.isConnected) {
        print("Connection lost, attempting to reconnect...");
        await connectToDevice();
      } else {
        print("Connection is still active.");
      }
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    super.dispose();
  }

  void sendMessage(String message) {
    if (connection != null && connection!.isConnected) {
      print('Sending message: $message');
      connection!.output.add(Uint8List.fromList('$message\n'.codeUnits));
      connection!.output.allSent;
    } else {
      print('Device not connected');
    }
  }
}
