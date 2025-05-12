import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import 'dart:typed_data';


class LightControlScreen extends StatefulWidget {
  const LightControlScreen({super.key});

  @override
  State<LightControlScreen> createState() => _LightControlScreenState();
}

class _LightControlScreenState extends State<LightControlScreen> {
  bool _isLedOn = false;

  Future<void> _toggleLed() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

    if (bluetoothProvider.connection != null && bluetoothProvider.connection!.isConnected) {
      final command = _isLedOn ? 'LED_OFF' : 'LED_ON';
      bluetoothProvider.connection!.output.add(Uint8List.fromList('$command\n'.codeUnits));
      await bluetoothProvider.connection!.output.allSent;
      setState(() {
        _isLedOn = !_isLedOn;
      });
    } else {
      print('Device not connected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lights Control')),
      body: Center(
        child: ElevatedButton(
          onPressed: _toggleLed,
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
