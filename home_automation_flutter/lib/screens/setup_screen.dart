import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';

class SetupScreen extends StatefulWidget {
  final void Function(bool) onThemeChanged;
  final bool isDarkMode;

  const SetupScreen({super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late bool _localDarkMode;
  String _connectionStatus = "Not Connected";
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _localDarkMode = widget.isDarkMode;
  }

  void _onSwitchChanged(bool value) {
    setState(() {
      _localDarkMode = value;
    });
    widget.onThemeChanged(value);
  }

  Future<void> _connectToDevice() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

    setState(() {
      _isConnecting = true;
      _connectionStatus = "Connecting...";
    });

    await bluetoothProvider.connectToDevice();

    setState(() {
      _isConnecting = false;
      _connectionStatus = bluetoothProvider.isConnected
          ? "Connected to Home Automation"
          : "Connection Failed";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Mode', style: TextStyle(fontSize: 18)),
                Switch(value: _localDarkMode, onChanged: _onSwitchChanged),
              ],
            ),
            const SizedBox(height: 20),
            const Text('🔹 How to connect to Home Automation:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('1. Open Bluetooth settings on your device.'),
            const Text('2. Look for "Home Automation" in the list of devices.'),
            const Text('3. Tap to pair. Default PIN is 1234 if prompted.'),
            const Text('4. Once connected, you can control it from the app.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isConnecting ? null : _connectToDevice,
              child: _isConnecting ? const CircularProgressIndicator() : const Text("Connect to Home Automation"),
            ),
            const SizedBox(height: 20),
            Text(
              _connectionStatus,
              style: TextStyle(
                color: _connectionStatus == "Connected to Home Automation" ? Colors.green : Colors.red,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
