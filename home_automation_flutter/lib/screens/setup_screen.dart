import 'package:flutter/material.dart';

class SetupScreen extends StatefulWidget {
  final void Function(bool) onThemeChanged;
  final bool isDarkMode;

  const SetupScreen({super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late bool _localDarkMode;

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
            const Center(child: Text('Other setup options here...')),
          ],
        ),
      ),
    );
  }
}
