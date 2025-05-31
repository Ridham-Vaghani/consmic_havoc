import 'package:cosmic_havoc/database/database_helper.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

class SettingsOverlay extends StatefulWidget {
  final Function(double) onSensitivityChanged;
  final MyGame game;

  const SettingsOverlay({
    super.key,
    required this.onSensitivityChanged,
    required this.game,
  });

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  double _currentSensitivity = 1.0;
  bool _isJoystickEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final sensitivity = await DatabaseHelper.instance.getJoystickSensitivity();
    final controlType = await DatabaseHelper.instance.getControlType();
    print("Loaded control type: $controlType"); // Debug print
    setState(() {
      _currentSensitivity = sensitivity;
      _isJoystickEnabled = controlType == 'joystick';
    });
  }

  void _closeSettings() {
    widget.game.overlays.remove('Settings');
    widget.game.resumeEngine();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeSettings,
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
                Center(
                  child: Material(
                    type: MaterialType.card,
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
                          Column(
                            children: [
                              const Text(
                                'Control Type',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        setState(() {
                                          _isJoystickEnabled = true;
                                        });
                                        await DatabaseHelper.instance
                                            .updateControlType('joystick');
                                        widget.game.setControlType(true);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isJoystickEnabled
                                            ? Colors.blue
                                            : Colors.grey,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.games),
                                          SizedBox(width: 8),
                                          Text('Joystick'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        setState(() {
                                          _isJoystickEnabled = false;
                                        });
                                        await DatabaseHelper.instance
                                            .updateControlType('finger');
                                        widget.game.setControlType(false);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: !_isJoystickEnabled
                                            ? Colors.blue
                                            : Colors.grey,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.touch_app),
                                          SizedBox(width: 8),
                                          Text('Finger'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Column(
                            children: [
                              const Text(
                                'Joy Stick Sensitivity',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        activeTrackColor: Colors.blue,
                                        inactiveTrackColor:
                                            Colors.blue.withOpacity(0.3),
                                        thumbColor: Colors.white,
                                        overlayColor:
                                            Colors.blue.withOpacity(0.2),
                                        valueIndicatorColor: Colors.blue,
                                        valueIndicatorTextStyle:
                                            const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      child: Slider(
                                        value: _currentSensitivity,
                                        min: 0.5,
                                        max: 2.0,
                                        divisions: 30,
                                        label: _currentSensitivity
                                            .toStringAsFixed(1),
                                        onChanged: (value) {
                                          setState(() {
                                            _currentSensitivity = value;
                                          });
                                          widget.onSensitivityChanged(value);
                                        },
                                        onChangeEnd: (value) async {
                                          await DatabaseHelper.instance
                                              .updateJoystickSensitivity(value);
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
                                      _currentSensitivity.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    widget.game.audioManager.toggleMusic();
                                  });
                                },
                                icon: Icon(
                                  widget.game.audioManager.musicEnabled
                                      ? Icons.music_note_rounded
                                      : Icons.music_off_rounded,
                                  color: widget.game.audioManager.musicEnabled
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 30,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    widget.game.audioManager.toggleSounds();
                                  });
                                },
                                icon: Icon(
                                  widget.game.audioManager.soundsEnabled
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                  color: widget.game.audioManager.soundsEnabled
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 30,
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
              ],
            ),
          );
        },
      ),
    );
  }
}
