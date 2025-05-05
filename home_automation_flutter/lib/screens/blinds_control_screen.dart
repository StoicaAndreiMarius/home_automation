import 'package:flutter/material.dart';
import 'dart:async';

class BlindsControlScreen extends StatefulWidget {
  const BlindsControlScreen({super.key});

  @override
  State<BlindsControlScreen> createState() => _BlindsControlScreenState();
}

class _BlindsControlScreenState extends State<BlindsControlScreen> {
  double blind1Height = 0;
  double blind2Height = 0;
  bool syncMode = false;
  Timer? _pressTimer;

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
                      width: 40, // sau mai puțin dacă vrei să fie mai aproape de slider
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('☀️', style: TextStyle(fontSize: 24)),
                          const Text('🌚', style: TextStyle(fontSize: 24)),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blinds Control')),
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
