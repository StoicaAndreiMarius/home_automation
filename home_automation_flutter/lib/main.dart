import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'app.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothConnection? connection;
  bool isConnected = false;

  BluetoothProvider() {
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    try {
      // verifică dacă există deja o conexiune activă și o închide
      if (connection != null && connection!.isConnected) {
        print("Existing connection found. Closing it...");
        await connection!.close();
        connection = null;
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

        // ascultă evenimente deconectare
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  // inițializează conexiunea bluetooth
  final bluetoothProvider = BluetoothProvider();

  // încearcă să se conecteze până reușește
  while (!bluetoothProvider.isConnected) {
    print("Încercare de conectare la ESP32...");
    await bluetoothProvider._connectToDevice();
    await Future.delayed(Duration(seconds: 2)); // așteaptă 2 secunde înainte de a încerca din nou
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => bluetoothProvider,
      child: MyApp(initialDarkMode: isDarkMode),
    ),
  );
}
