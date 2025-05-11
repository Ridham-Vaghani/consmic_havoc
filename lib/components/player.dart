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
import 'package:flutter/services.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks, KeyboardHandler {
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
    size = Vector2.all(50);
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
        await game.loadSprite('player_${_color}_on0.png'),
        await game.loadSprite('player_${_color}_on1.png'),
      ],
      stepTime: 0.1,
      loop: true,
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

    // Handle joystick movement
    final joystickDelta = game.joystick.relativeDelta;
    if (joystickDelta.length > 0) {
      position += joystickDelta.normalized() * speed * dt;
    }

    // Handle keyboard movement
    if (_isLeftPressed) {
      position.x -= _moveSpeed * dt;
    }
    if (_isRightPressed) {
      position.x += _moveSpeed * dt;
    }
    if (_isUpPressed) {
      position.y -= _moveSpeed * dt;
    }
    if (_isDownPressed) {
      position.y += _moveSpeed * dt;
    }

    // Keep player within screen bounds
    position.x = position.x.clamp(size.x / 2, game.size.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, game.size.y - size.y / 2);

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
        await game.loadSprite('player_${_color}_off.png'),
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

    if (other is EnemyPlane) {
      if (activeShield == null) {
        takeDamage();
      } else {
        other.handleDestruction();
        game.incrementScore(1);
      }
    } else if (other is Laser && other.isEnemy) {
      if (activeShield == null) {
        takeDamage();
      }
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
          if (activeShield != null) {
            remove(activeShield!);
          }
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
}
