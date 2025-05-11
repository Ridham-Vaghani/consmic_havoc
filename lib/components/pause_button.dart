import 'dart:math';

import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class PauseButton extends PositionComponent
    with TapCallbacks, HasGameReference<MyGame> {
  PauseButton() : super(anchor: Anchor.topRight);

  @override
  Future<void> onLoad() async {
    size = Vector2.all(50);
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Draw pause icon (two vertical bars)
    final barWidth = size.x * 0.2;
    final barHeight = size.y * 0.6;
    final spacing = size.x * 0.1;
    final startX = (size.x - (barWidth * 2 + spacing)) / 2;
    final startY = (size.y - barHeight) / 2;

    // First bar
    canvas.drawRect(
      Rect.fromLTWH(startX, startY, barWidth, barHeight),
      paint,
    );

    // Second bar
    canvas.drawRect(
      Rect.fromLTWH(startX + barWidth + spacing, startY, barWidth, barHeight),
      paint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.pauseEngine();
    game.overlays.add('Pause');
  }
}
