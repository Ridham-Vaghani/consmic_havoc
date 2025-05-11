import 'package:cosmic_havoc/database/database_helper.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

class SettingsOverlay extends StatefulWidget {
  final Function(double) onSpeedChanged;
  final MyGame game;

  const SettingsOverlay({
    super.key,
    required this.onSpeedChanged,
    required this.game,
  });

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSpeed();
  }

  Future<void> _loadSpeed() async {
    final speed = await DatabaseHelper.instance.getGameSpeed();
    setState(() {
      _currentSpeed = speed;
    });
  }

  void _closeSettings() {
    widget.game.overlays.remove('Settings');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Card(
          elevation: 8,
          color: Colors.black.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Game Speed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.blue,
                          inactiveTrackColor: Colors.blue.withOpacity(0.3),
                          thumbColor: Colors.white,
                          overlayColor: Colors.blue.withOpacity(0.2),
                          valueIndicatorColor: Colors.blue,
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        child: Slider(
                          value: _currentSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 30,
                          label: _currentSpeed.toStringAsFixed(1),
                          onChanged: (value) async {
                            setState(() {
                              _currentSpeed = value;
                            });
                            await DatabaseHelper.instance
                                .updateGameSpeed(value);
                            widget.onSpeedChanged(value);
                          },
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentSpeed.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _closeSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
