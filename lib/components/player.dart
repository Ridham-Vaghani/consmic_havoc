import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/bomb.dart';
import 'package:cosmic_havoc/components/enemy_plane.dart';
import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/components/laser.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/components/shield.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

class Player extends SpriteAnimationComponent
    with
        HasGameReference<MyGame>,
        CollisionCallbacks,
        KeyboardHandler,
        TapCallbacks,
        DragCallbacks {
  static const double _moveSpeed = 300.0;
  static const double _fireCooldown = 0.2;
  double _elapsedFireTime = 0.0;
  int _health = 3;
  bool _isInvulnerable = false;
  double _invulnerabilityTime = 1.0;
  double _elapsedInvulnerabilityTime = 0.0;
  bool _isShooting = false;
  final Vector2 _keyboardMovement = Vector2.zero();
  bool _isDestroyed = false;
  final Random _random = Random();
  late Timer _explosionTimer;
  late Timer _laserPowerupTimer;
  Shield? activeShield;
  late String _color;
  double speed = 300.0; // Base speed
  bool _isLeftPressed = false;
  bool _isRightPressed = false;
  bool _isUpPressed = false;
  bool _isDownPressed = false;
  Vector2? _targetPosition;
  static const double _playerSpeed = 300.0;
  static const double _joystickSensitivity = 1.0;
  static const double _maxSpeed = 500.0;
  static const double _acceleration = 1000.0;
  static const double _deceleration = 800.0;
  static const double _rotationSpeed = 3.0;
  static const double _maxRotationSpeed = 5.0;
  static const double _rotationDeceleration = 8.0;
  static const double _maxTiltAngle = 0.5;
  static const double _tiltSpeed = 2.0;
  static const double _tiltDeceleration = 4.0;
  static const double _shootCooldown = 0.2;
  static const double _invincibilityDuration = 2.0;
  static const int _maxLives = 3;
  static const double _blinkInterval = 0.2;
  Vector2 _velocity = Vector2.zero();
  double _currentSpeed = 0.0;
  double _targetSpeed = 0.0;
  double _rotationVelocity = 0.0;
  double _currentTilt = 0.0;
  double _targetTilt = 0.0;
  double _lastShootTime = 0.0;
  bool _isInvincible = false;
  double _invincibilityTimer = 0.0;
  bool _isVisible = true;
  double _blinkTimer = 0.0;
  int _lives = _maxLives;
  bool _isJoystickEnabled = true;
  Vector2? _lastTouchPosition;

  Player({required Vector2 position}) : super(position: position) {
    _explosionTimer = Timer(
      0.1,
      onTick: _createRandomExplosion,
      repeat: true,
      autoStart: false,
    );

    _laserPowerupTimer = Timer(
      10.0,
      autoStart: false,
    );
  }

  @override
  Future<void> onLoad() async {
    _color = game.playerColors[game.playerColorIndex];
    animation = await _loadAnimation();
    size = Vector2.all(80);
    anchor = Anchor.center;

    // Add hitbox
    add(RectangleHitbox.relative(
      Vector2(0.8, 0.8),
      parentSize: size,
      anchor: Anchor.center,
    ));

    return super.onLoad();
  }

  Future<SpriteAnimation> _loadAnimation() async {
    return SpriteAnimation.spriteList(
      [
        await game.loadSprite('player_basic.png'),
      ],
      stepTime: double.infinity,
      loop: false,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDestroyed) {
      _explosionTimer.update(dt);
      return;
    }

    if (_laserPowerupTimer.isRunning()) {
      _laserPowerupTimer.update(dt);
    }

    if (_isInvulnerable) {
      _elapsedInvulnerabilityTime += dt;
      if (_elapsedInvulnerabilityTime >= _invulnerabilityTime) {
        _isInvulnerable = false;
        opacity = 1.0;
      } else {
        opacity =
            (_elapsedInvulnerabilityTime * 10).floor() % 2 == 0 ? 0.5 : 1.0;
      }
    }

    if (!game.isJoystickEnabled) {
      // Handle touch movement - directly set position to touch position
      if (_lastTouchPosition != null) {
        // Move plane directly to touch position
        position = _lastTouchPosition!;

        // Keep player within screen bounds
        position.clamp(
          Vector2.zero() + size / 2,
          game.size - size / 2,
        );
      }
    } else {
      // Handle joystick movement
      final joystick = game.joystick;
      if (joystick.direction != JoystickDirection.idle) {
        position += joystick.relativeDelta * speed * dt;

        // Keep player within screen bounds
        position.clamp(
          Vector2.zero() + size / 2,
          game.size - size / 2,
        );
      }
    }

    // Update shooting
    _elapsedFireTime += dt;
    if (_isShooting && _elapsedFireTime >= _fireCooldown) {
      _fireLaser();
      _elapsedFireTime = 0.0;
    }
  }

  void startShooting() {
    _isShooting = true;
  }

  void stopShooting() {
    _isShooting = false;
  }

  void _fireLaser() {
    game.audioManager.playSound('laser');

    game.add(
      Laser(position: position.clone() + Vector2(0, -size.y / 2)),
    );

    if (_laserPowerupTimer.isRunning()) {
      game.add(
        Laser(
          position: position.clone() + Vector2(0, -size.y / 2),
          angle: 15 * degrees2Radians,
        ),
      );
      game.add(
        Laser(
          position: position.clone() + Vector2(0, -size.y / 2),
          angle: -15 * degrees2Radians,
        ),
      );
    }
  }

  void takeDamage() {
    if (_isInvulnerable) return;

    _health--;
    if (_health <= 0) {
      _handleDestruction();
    } else {
      _isInvulnerable = true;
      _elapsedInvulnerabilityTime = 0.0;
    }
  }

  void _handleDestruction() async {
    animation = SpriteAnimation.spriteList(
      [
        await game.loadSprite('player_basic.png'),
      ],
      stepTime: double.infinity,
    );

    add(ColorEffect(
      const Color.fromRGBO(255, 255, 255, 1.0),
      EffectController(duration: 0.0),
    ));

    add(OpacityEffect.fadeOut(
      EffectController(duration: 3.0),
      onComplete: () => _explosionTimer.stop(),
    ));

    add(MoveEffect.by(
      Vector2(0, 200),
      EffectController(duration: 3.0),
    ));

    add(RemoveEffect(
      delay: 4.0,
      onComplete: game.playerDied,
    ));

    _isDestroyed = true;

    _explosionTimer.start();
  }

  void _createRandomExplosion() {
    final Vector2 explosionPosition = Vector2(
      position.x - size.x / 2 + _random.nextDouble() * size.x,
      position.y - size.y / 2 + _random.nextDouble() * size.y,
    );

    final ExplosionType explosionType =
        _random.nextBool() ? ExplosionType.smoke : ExplosionType.fire;

    final Explosion explosion = Explosion(
      position: explosionPosition,
      explosionSize: size.x * 0.7,
      explosionType: explosionType,
    );

    game.add(explosion);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (_isDestroyed) return;

    // If shield is active, handle enemy collisions without taking damage
    if (activeShield != null) {
      if (other is EnemyPlane) {
        other.handleDestruction();
        game.incrementScore(1);
      } else if (other is Laser && other.isEnemy) {
        game.audioManager.playSound('hit');
        game.incrementScore(1);
        other.removeFromParent();
      } else if (other is Pickup) {
        game.audioManager.playSound('collect');
        other.removeFromParent();
        game.incrementScore(1);

        switch (other.pickupType) {
          case PickupType.laser:
            _laserPowerupTimer.start();
            break;
          case PickupType.bomb:
            game.add(Bomb(position: position.clone()));
            break;
          case PickupType.shield:
            remove(activeShield!);
            activeShield = Shield();
            add(activeShield!);
            break;
        }
      }
      return;
    }

    // If no shield, handle collisions normally
    if (other is EnemyPlane) {
      takeDamage();
    } else if (other is Laser && other.isEnemy) {
      takeDamage();
      other.removeFromParent();
    } else if (other is Pickup) {
      game.audioManager.playSound('collect');
      other.removeFromParent();
      game.incrementScore(1);

      switch (other.pickupType) {
        case PickupType.laser:
          _laserPowerupTimer.start();
          break;
        case PickupType.bomb:
          game.add(Bomb(position: position.clone()));
          break;
        case PickupType.shield:
          activeShield = Shield();
          add(activeShield!);
          break;
      }
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _isLeftPressed = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);
    _isRightPressed = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);
    _isUpPressed = keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW);
    _isDownPressed = keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS);

    if (keysPressed.contains(LogicalKeyboardKey.space) &&
        _elapsedFireTime >= _fireCooldown) {
      _fireLaser();
      _elapsedFireTime = 0.0;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!game.isJoystickEnabled) {
      _targetPosition = event.canvasPosition;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!game.isJoystickEnabled) {
      _targetPosition = null;
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (!game.isJoystickEnabled) {
      _targetPosition = null;
    }
  }

  void setControlType(bool isJoystickEnabled) {
    _isJoystickEnabled = isJoystickEnabled;
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (!game.isJoystickEnabled) {
      _lastTouchPosition = event.canvasPosition;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!game.isJoystickEnabled) {
      _lastTouchPosition = event.canvasPosition;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!game.isJoystickEnabled) {
      _lastTouchPosition = null;
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    if (!game.isJoystickEnabled) {
      _lastTouchPosition = null;
    }
  }
}
