import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class LightControlScreen extends StatefulWidget {
  const LightControlScreen({super.key});

  @override
  State<LightControlScreen> createState() => _LightControlScreenState();
}

class _LightControlScreenState extends State<LightControlScreen> {
  bool _isLedOn = false;

  Future<void> _toggleLed() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(
        context, listen: false);
    if (bluetoothProvider.isConnected) {
      final command = _isLedOn ? 'LED_OFF' : 'LED_ON';
      bluetoothProvider.sendMessage(command);
      setState(() {
        _isLedOn = !_isLedOn;
      });
    } else {
      print('Device not connected');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lights Control'),
        actions: [
          Icon(
            bluetoothProvider.isConnected ? Icons.bluetooth_connected : Icons
                .bluetooth_disabled,
            color: bluetoothProvider.isConnected ? Colors.green : Colors.red,
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: bluetoothProvider.isConnected ? _toggleLed : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            textStyle: const TextStyle(fontSize: 24),
          ),
          child: Text(_isLedOn ? 'Turn Off Light' : 'Turn On Light'),
        ),
      ),
    );
  }
}