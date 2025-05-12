import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BlindSchedule {
  final TimeOfDay time;
  final double targetHeight;
  final bool applyToBlind1;
  final bool applyToBlind2;

  BlindSchedule({
    required this.time,
    required this.targetHeight,
    required this.applyToBlind1,
    required this.applyToBlind2,
  });

  Map<String, dynamic> toJson() => {
    'hour': time.hour,
    'minute': time.minute,
    'height': targetHeight,
    'b1': applyToBlind1,
    'b2': applyToBlind2,
  };

  static BlindSchedule fromJson(Map<String, dynamic> json) => BlindSchedule(
    time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    targetHeight: json['height'],
    applyToBlind1: json['b1'],
    applyToBlind2: json['b2'],
  );
}

class BlindsControlScreen extends StatefulWidget {
  const BlindsControlScreen({super.key});

  @override
  State<BlindsControlScreen> createState() => _BlindsControlScreenState();
}

class _BlindsControlScreenState extends State<BlindsControlScreen> with TickerProviderStateMixin {
  double blind1Height = 0;
  double blind2Height = 0;
  bool syncMode = false;
  Timer? _pressTimer;
  Timer? _scheduleTimer;
  List<BlindSchedule> schedules = [];

  late AnimationController _blind1Controller;
  late AnimationController _blind2Controller;
  late Animation<double> _blind1Animation;
  late Animation<double> _blind2Animation;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScheduleWatcher());
  }

  void _initAnimations() {
    _blind1Controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _blind2Controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _blind1Animation = Tween<double>(begin: blind1Height, end: blind1Height).animate(_blind1Controller);
    _blind2Animation = Tween<double>(begin: blind2Height, end: blind2Height).animate(_blind2Controller);
  }

  void _animateBlind(String blind, double target) {
    if (blind == 'Blind 1') {
      _blind1Animation = Tween<double>(begin: blind1Height, end: target).animate(_blind1Controller)
        ..addListener(() {
          setState(() => blind1Height = _blind1Animation.value);
        });
      _blind1Controller.forward(from: 0);
    } else {
      _blind2Animation = Tween<double>(begin: blind2Height, end: target).animate(_blind2Controller)
        ..addListener(() {
          setState(() => blind2Height = _blind2Animation.value);
        });
      _blind2Controller.forward(from: 0);
    }
  }

  void _startScheduleWatcher() {
    _scheduleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = TimeOfDay.now();
      for (final s in schedules) {
        if (now.hour == s.time.hour && now.minute == s.time.minute) {
          if (s.applyToBlind1 && blind1Height != s.targetHeight) {
            _animateBlind('Blind 1', s.targetHeight);
          }
          if (s.applyToBlind2 && blind2Height != s.targetHeight) {
            _animateBlind('Blind 2', s.targetHeight);
          }
          debugPrint("Executed schedule at ${s.time.format(context)}");
        }
      }
    });
  }

  double getBlindHeight(String blindName) {
    return blindName == 'Blind 1' ? blind1Height : blind2Height;
  }

  void setBlindHeight(String blindName, double height) {
    setState(() {
      if (blindName == 'Blind 1') {
        blind1Height = height;
      } else {
        blind2Height = height;
      }
    });
  }

  @override
  void dispose() {
    _pressTimer?.cancel();
    _scheduleTimer?.cancel();
    _blind1Controller.dispose();
    _blind2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('schedules') ?? [];
    setState(() {
      schedules = data.map((s) => BlindSchedule.fromJson(jsonDecode(s))).toList();
    });
  }

  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final data = schedules.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('schedules', data);
  }

  void _startContinuousAdjust(String blindName, String direction) {
    _pressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _adjustHeight(blindName, direction == 'up' ? -2 : 2);
    });
  }

  void _stopContinuousAdjust() {
    _pressTimer?.cancel();
    _pressTimer = null;
  }

  void _adjustHeight(String blindName, double delta) {
    setState(() {
      if (syncMode) {
        double newHeight = (blind1Height + delta).clamp(0, 100);
        blind1Height = newHeight;
        blind2Height = newHeight;
      } else {
        if (blindName == 'Blind 1') {
          blind1Height = (blind1Height + delta).clamp(0, 100);
        } else {
          blind2Height = (blind2Height + delta).clamp(0, 100);
        }
      }
    });
  }

  void _equalizeBlinds() {
    setState(() {
      final avg = (blind1Height + blind2Height) / 2;
      blind1Height = avg;
      blind2Height = avg;
    });
  }

  Widget _buildBlindControl(String blindName, double height) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Card(
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                blindName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('☀️', style: TextStyle(fontSize: 24)),
                          Text('🌚', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationZ(3.1416),
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Slider(
                            value: height,
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: '${height.toInt()}%',
                            onChanged: (val) {
                              setState(() {
                                if (syncMode) {
                                  blind1Height = val;
                                  blind2Height = val;
                                } else {
                                  if (blindName == 'Blind 1') blind1Height = val;
                                  else blind2Height = val;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!syncMode) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onLongPressStart: (_) => _startContinuousAdjust(blindName, 'up'),
                      onLongPressEnd: (_) => _stopContinuousAdjust(),
                      child: ElevatedButton.icon(
                        onPressed: () => _adjustHeight(blindName, -5),
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('Up'),
                      ),
                    ),
                    GestureDetector(
                      onLongPressStart: (_) => _startContinuousAdjust(blindName, 'down'),
                      onLongPressEnd: (_) => _stopContinuousAdjust(),
                      child: ElevatedButton.icon(
                        onPressed: () => _adjustHeight(blindName, 5),
                        icon: const Icon(Icons.arrow_downward),
                        label: const Text('Down'),
                      ),
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncControls() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: syncMode
          ? Padding(
        key: const ValueKey('sync_buttons'),
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ElevatedButton.icon(
                onPressed: () => _adjustHeight('Blind 1', -5),
                icon: const Icon(Icons.arrow_upward),
                label: const Text('All Up'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ElevatedButton.icon(
                onPressed: () => _adjustHeight('Blind 1', 5),
                icon: const Icon(Icons.arrow_downward),
                label: const Text('All Down'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _showAddScheduleDialog() async {
    TimeOfDay selectedTime = TimeOfDay.now();
    double selectedHeight = 50;
    bool blind1 = true;
    bool blind2 = true;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Blind Schedule'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() => selectedTime = time);
                      }
                    },
                    child: Text('Select Time: ${selectedTime.format(context)}'),
                  ),
                  const SizedBox(height: 12),
                  Text('Level: ${selectedHeight.toInt()}%'),
                  Slider(
                    value: selectedHeight,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (val) => setState(() => selectedHeight = val),
                  ),
                  CheckboxListTile(
                    value: blind1,
                    onChanged: (v) => setState(() => blind1 = v ?? false),
                    title: const Text('Blind 1'),
                  ),
                  CheckboxListTile(
                    value: blind2,
                    onChanged: (v) => setState(() => blind2 = v ?? false),
                    title: const Text('Blind 2'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!blind1 && !blind2) return;
                setState(() {
                  schedules.add(BlindSchedule(
                    time: selectedTime,
                    targetHeight: selectedHeight,
                    applyToBlind1: blind1,
                    applyToBlind2: blind2,
                  ));
                });
                _saveSchedules();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blinds Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: _showAddScheduleDialog,
            tooltip: 'Add Schedule',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Synchronized Mode', style: TextStyle(fontSize: 16)),
                Switch(
                  value: syncMode,
                  onChanged: (v) {
                    if (v) _equalizeBlinds();
                    setState(() => syncMode = v);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildBlindControl('Blind 1', blind1Height),
                  _buildBlindControl('Blind 2', blind2Height),
                ],
              ),
            ),
          ),
          _buildSyncControls(),
        ],
      ),
      bottomNavigationBar: !syncMode
          ? Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        child: ElevatedButton.icon(
          onPressed: _equalizeBlinds,
          icon: const Icon(Icons.equalizer),
          label: const Text('Equalize Heights'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            fixedSize: const Size.fromWidth(320),
          ),
        ),
      )
          : null,
    );
  }
}
