import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/player.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Laser extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  final bool isEnemy;
  double speed = 300.0;
  final double angle;

  Laser({
    required Vector2 position,
    this.isEnemy = false,
    this.angle = 0.0,
  }) : super(position: position) {
    // Set higher speed for enemy lasers
    if (isEnemy) {
      speed = 600.0; // Double the normal speed
    }
  }

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(
      'laser.png',
    );
    size = Vector2(4, 20);
    anchor = Anchor.center;
    this.angle = angle;

    // Add hitbox
    add(RectangleHitbox.relative(
      Vector2(0.8, 0.8),
      parentSize: size,
      anchor: Anchor.center,
    ));

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isEnemy) {
      // Enemy lasers only move downward at double speed
      position.y += speed * dt;
    } else {
      // Player lasers move based on angle
      position += Vector2(sin(angle), -cos(angle)) * speed * dt;
    }

    // Remove if off screen
    if ((isEnemy && position.y > game.size.y + size.y) ||
        (!isEnemy && position.y < -size.y)) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Player && isEnemy) {
      other.takeDamage();
      removeFromParent();
    }
  }
}
