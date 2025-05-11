import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ScoreText extends TextComponent with HasGameReference<MyGame> {
  int _score = 0;

  ScoreText()
      : super(
          text: '0',
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    position = Vector2(20, 20);
    anchor = Anchor.topLeft;
    return super.onLoad();
  }

  void addPoints(int points) {
    _score += points;
    text = _score.toString();
  }

  void reset() {
    _score = 0;
    text = '0';
  }
}
