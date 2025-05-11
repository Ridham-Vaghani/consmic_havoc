import 'dart:math';

import 'package:cosmic_havoc/components/bomb.dart';
import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/components/laser.dart';
import 'package:cosmic_havoc/components/player.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class EnemyPlane extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  final Random _random = Random();
  double _fireCooldown = 2.0; // Time between shots
  double _elapsedFireTime = 0.0;
  double speed = 100.0;
  late Timer _fireTimer;

  EnemyPlane({required Vector2 position}) : super(position: position) {
    _fireTimer = Timer(
      _fireCooldown,
      onTick: _fire,
      repeat: true,
    );
  }

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('player_blue_on0.png');
    size = Vector2.all(50);
    anchor = Anchor.center;
    angle = pi; // Rotate 180 degrees

    // Add hitbox
    add(RectangleHitbox.relative(
      Vector2(0.8, 0.8),
      parentSize: size,
      anchor: Anchor.center,
    ));

    // Start firing timer
    _fireTimer.start();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move downward
    position.y += speed * dt;

    // Update fire timer
    _fireTimer.update(dt);

    // Remove if off screen
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  void _fire() {
    if (!isMounted) return;

    // Create enemy laser
    final laser = Laser(
      position: position.clone() +
          Vector2(0, size.y / 2), // Fire from bottom of plane
      isEnemy: true,
    );
    game.add(laser);
  }

  void handleDestruction() {
    // Create explosion
    final explosion = Explosion(
      position: position.clone(),
      explosionSize: size.x * 0.7,
      explosionType: ExplosionType.fire,
    );
    game.add(explosion);

    // Remove the enemy plane
    removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Laser && !other.isEnemy) {
      handleDestruction();
      other.removeFromParent();
      game.incrementScore(1);
    } else if (other is Player) {
      handleDestruction();
    } else if (other is Bomb) {
      handleDestruction();
      other.removeFromParent();
      game.incrementScore(1);
    }
  }
}
