import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/enemy_plane.dart';
import 'package:cosmic_havoc/components/audio_manager.dart';
import 'package:cosmic_havoc/components/high_score_display.dart';
import 'package:cosmic_havoc/components/laser.dart';
import 'package:cosmic_havoc/components/pause_button.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/components/player.dart';
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
import 'package:flutter/services.dart';
import 'package:cosmic_havoc/components/score_text.dart';

class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, KeyboardEvents {
  late Player player;
  late JoystickComponent joystick;
  late SpawnComponent _asteroidSpawner;
  late SpawnComponent _pickupSpawner;
  final Random _random = Random();
  late ShootButton _shootButton;
  late PauseButton _pauseButton;
  int _score = 0;
  late TextComponent _scoreDisplay;
  final List<String> playerColors = ['blue', 'red', 'green', 'purple'];
  int playerColorIndex = 0;
  late final AudioManager audioManager;
  double _joystickSensitivity = 1.0;
  late ScoreText scoreText;
  double _enemySpawnTimer = 0;
  double _enemySpawnInterval = 2.0; // Time between enemy spawns
  bool _isGameOver = false;
  bool _isPaused = false;
  double _playerSpeed = 300.0; // Default player speed
  bool _isJoystickEnabled = true;

  int get score => _score;
  double get joystickSensitivity => _joystickSensitivity;
  bool get isJoystickEnabled => _isJoystickEnabled;

  @override
  FutureOr<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();

    // Load saved settings
    _joystickSensitivity =
        await DatabaseHelper.instance.getJoystickSensitivity();
    final controlType = await DatabaseHelper.instance.getControlType();
    _isJoystickEnabled = controlType == 'joystick';

    // initialize the audio manager and play the music
    audioManager = AudioManager();
    await add(audioManager);
    audioManager.playMusic();

    _createStars();

    // Load player speed from database
    final db = await DatabaseHelper.instance.database;
    final settings = await db.query('settings');
    if (settings.isNotEmpty) {
      _playerSpeed = (settings.first['player_speed'] as double?) ?? 300.0;
    }

    return super.onLoad();
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

  void updateJoystickSensitivity(double sensitivity) {
    _joystickSensitivity = sensitivity;
    // Update player's joystick sensitivity if player exists
    if (children.any((component) => component is Player)) {
      player.speed = _playerSpeed * _joystickSensitivity;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isGameOver || _isPaused) return;

    // Spawn enemies
    _enemySpawnTimer += dt;
    if (_enemySpawnTimer >= _enemySpawnInterval) {
      _spawnEnemy();
      _enemySpawnTimer = 0;
    }
  }

  void startGame() async {
    // Clean up any existing game elements first
    children.whereType<PositionComponent>().forEach((component) {
      if (component is EnemyPlane ||
          component is Pickup ||
          component is Player ||
          component is Laser) {
        remove(component);
      }
    });

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
    final position = Vector2(size.x / 2, size.y * 0.8);
    player = Player(position: position)..anchor = Anchor.center;
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
    if (_isJoystickEnabled) {
      add(joystick);
    }
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
      factory: (index) => EnemyPlane(position: _generateSpawnPosition()),
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
    // remove any enemies and pickups that are currently in the game
    children.whereType<PositionComponent>().forEach((component) {
      if (component is EnemyPlane ||
          component is Pickup ||
          component is Player ||
          component is Laser) {
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

    // show the title overlay
    overlays.add('Title');

    resumeEngine();
  }

  void _spawnEnemy() {
    final x = _random.nextDouble() * (size.x - 50);
    final enemy = EnemyPlane(
      position: Vector2(x, -50),
    );
    add(enemy);
  }

  void gameOver() {
    _isGameOver = true;
    pauseEngine();
    overlays.add('gameOver');
  }

  void reset() {
    _isGameOver = false;
    _enemySpawnTimer = 0;
    _score = 0;
    _scoreDisplay.text = '0';
    player.position = Vector2(size.x / 2, size.y * 0.8);
    resumeEngine();
  }

  void pause() {
    _isPaused = true;
    pauseEngine();
  }

  void resume() {
    _isPaused = false;
    resumeEngine();
  }

  void setControlType(bool isJoystick) {
    _isJoystickEnabled = isJoystick;
    if (children.any((component) => component is JoystickComponent)) {
      if (isJoystick) {
        add(joystick);
      } else {
        remove(joystick);
      }
    }
  }
}
