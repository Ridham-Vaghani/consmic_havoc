import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/audio_manager.dart';
import 'package:cosmic_havoc/components/high_score_display.dart';
import 'package:cosmic_havoc/components/pause_button.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/components/player.dart';
import 'package:cosmic_havoc/components/settings_button.dart';
import 'package:cosmic_havoc/components/shoot_button.dart';
import 'package:cosmic_havoc/components/star.dart';
import 'package:cosmic_havoc/database/database_helper.dart';
import 'package:cosmic_havoc/overlays/settings_overlay.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late SpawnComponent _asteroidSpawner;
  late SpawnComponent _pickupSpawner;
  final Random _random = Random();
  late ShootButton _shootButton;
  late SettingsButton _settingsButton;
  late PauseButton _pauseButton;
  int _score = 0;
  late TextComponent _scoreDisplay;
  final List<String> playerColors = ['blue', 'red', 'green', 'purple'];
  int playerColorIndex = 0;
  late final AudioManager audioManager;
  double _gameSpeed = 1.0;

  int get score => _score;

  @override
  FutureOr<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();

    // Load saved game speed
    _gameSpeed = await DatabaseHelper.instance.getGameSpeed();

    // initialize the audio manager and play the music
    audioManager = AudioManager();
    await add(audioManager);
    audioManager.playMusic();

    _createStars();
    _createSettingsButton();

    return super.onLoad();
  }

  void _createSettingsButton() {
    _settingsButton = SettingsButton()
      ..position = Vector2(20, 20)
      ..priority = 10;
    add(_settingsButton);
  }

  void _createPauseButton() {
    _pauseButton = PauseButton()
      ..position = Vector2(size.x - 20, 20)
      ..priority = 10;
    add(_pauseButton);
  }

  void showSettings() {
    overlays.add('Settings');
  }

  void updateGameSpeed(double speed) {
    _gameSpeed = speed;
    // Update player speed
    if (player != null) {
      player.speed = 300 * _gameSpeed; // Base speed * multiplier
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Apply game speed to delta time
    dt *= _gameSpeed;
  }

  void startGame() async {
    // Hide settings button when game starts
    _settingsButton.removeFromParent();

    await _createJoystick();
    await _createPlayer();
    _createShootButton();
    _createAsteroidSpawner();
    _createPickupSpawner();
    _createScoreDisplay();
    _createPauseButton();
    add(HighScoreDisplay());
  }

  Future<void> _createPlayer() async {
    player = Player()
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y * 0.8);
    add(player);
  }

  Future<void> _createJoystick() async {
    joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: await loadSprite('joystick_knob.png'),
        size: Vector2.all(50),
      ),
      background: SpriteComponent(
        sprite: await loadSprite('joystick_background.png'),
        size: Vector2.all(100),
      ),
      anchor: Anchor.bottomLeft,
      position: Vector2(20, size.y - 20),
      priority: 10,
    );
    add(joystick);
  }

  void _createShootButton() {
    _shootButton = ShootButton()
      ..anchor = Anchor.bottomRight
      ..position = Vector2(size.x - 20, size.y - 20)
      ..priority = 10;
    add(_shootButton);
  }

  void _createAsteroidSpawner() {
    _asteroidSpawner = SpawnComponent.periodRange(
      factory: (index) => Asteroid(position: _generateSpawnPosition()),
      minPeriod: 1.5,
      maxPeriod: 2.5,
      selfPositioning: true,
    );
    add(_asteroidSpawner);
  }

  void _createPickupSpawner() {
    _pickupSpawner = SpawnComponent.periodRange(
      factory: (index) => Pickup(
        position: _generateSpawnPosition(),
        pickupType:
            PickupType.values[_random.nextInt(PickupType.values.length)],
      ),
      minPeriod: 5.0,
      maxPeriod: 10.0,
      selfPositioning: true,
    );
    add(_pickupSpawner);
  }

  Vector2 _generateSpawnPosition() {
    return Vector2(
      10 + _random.nextDouble() * (size.x - 10 * 2),
      -100,
    );
  }

  void _createScoreDisplay() {
    _score = 0;

    _scoreDisplay = TextComponent(
      text: '0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 20),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );

    add(_scoreDisplay);
  }

  void incrementScore(int amount) {
    _score += amount;
    _scoreDisplay.text = _score.toString();

    final ScaleEffect popEffect = ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(
        duration: 0.05,
        alternate: true,
        curve: Curves.easeInOut,
      ),
    );

    _scoreDisplay.add(popEffect);
  }

  void _createStars() {
    for (int i = 0; i < 50; i++) {
      add(Star()..priority = -10);
    }
  }

  void playerDied() {
    overlays.add('HighScore');
    pauseEngine();
  }

  void restartGame() {
    // remove any asteroids and pickups that are currently in the game
    children.whereType<PositionComponent>().forEach((component) {
      if (component is Asteroid || component is Pickup) {
        remove(component);
      }
    });

    // reset the asteroid and pickup spawners
    _asteroidSpawner.timer.start();
    _pickupSpawner.timer.start();

    // reset the score to 0
    _score = 0;
    _scoreDisplay.text = '0';

    // create a new player sprite
    _createPlayer();

    resumeEngine();
  }

  void quitGame() {
    // remove everything from the game except the stars
    children.whereType<PositionComponent>().forEach((component) {
      if (component is! Star) {
        remove(component);
      }
    });

    remove(_asteroidSpawner);
    remove(_pickupSpawner);

    // Add back the settings button when returning to title screen
    _createSettingsButton();

    // show the title overlay
    overlays.add('Title');

    resumeEngine();
  }
}
