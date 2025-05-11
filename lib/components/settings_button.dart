import 'dart:math';

import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class SettingsButton extends PositionComponent
    with TapCallbacks, HasGameReference<MyGame> {
  SettingsButton() : super(anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    size = Vector2.all(50);
    position = Vector2(20, 20);
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Draw gear icon
    final center = size / 2;
    final radius = size.x * 0.4;

    // Draw outer circle
    canvas.drawCircle(center.toOffset(), radius, paint);

    // Draw inner circle
    canvas.drawCircle(
      center.toOffset(),
      radius * 0.6,
      Paint()
        ..color = Colors.black.withOpacity(0.8)
        ..style = PaintingStyle.fill,
    );

    // Draw gear teeth
    final teethPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 8; i++) {
      final angle = (i * pi / 4);
      final start = center +
          Vector2(
            cos(angle) * radius * 0.8,
            sin(angle) * radius * 0.8,
          );
      final end = center +
          Vector2(
            cos(angle) * radius * 1.2,
            sin(angle) * radius * 1.2,
          );

      canvas.drawRect(
        Rect.fromPoints(
          start.toOffset(),
          end.toOffset(),
        ),
        teethPaint,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.showSettings();
  }
}
