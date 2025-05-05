import 'package:flutter/material.dart';
import 'setup_screen.dart';
import 'light_control_screen.dart';
import 'ac_control_screen.dart';
import 'blinds_control_screen.dart';

class MainScreen extends StatefulWidget {
  final void Function(bool) onThemeChanged;
  final bool isDarkMode;

  const MainScreen({super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _screens = [
        SetupScreen(
          onThemeChanged: widget.onThemeChanged,
          isDarkMode: widget.isDarkMode,
        ),
        const LightControlScreen(),
        const ACControlScreen(),
        const BlindsControlScreen(),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _screens = [
      SetupScreen(
        onThemeChanged: widget.onThemeChanged,
        isDarkMode: widget.isDarkMode,
      ),
      const LightControlScreen(),
      const ACControlScreen(),
      const BlindsControlScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Lights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.ac_unit),
            label: 'AC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.window),
            label: 'Blinds',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
