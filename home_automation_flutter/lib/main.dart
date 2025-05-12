import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/bluetooth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  // inițializează conexiunea bluetooth
  final bluetoothProvider = BluetoothProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: bluetoothProvider),
      ],
      child: MyApp(initialDarkMode: isDarkMode),
    ),
  );
}
