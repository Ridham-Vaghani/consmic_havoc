import 'package:cosmic_havoc/database/database_helper.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HighScoreDisplay extends TextComponent with HasGameReference<MyGame> {
  int _highScore = 0;

  HighScoreDisplay()
      : super(
          text: 'Highscore: 0',
          anchor: Anchor.topLeft,
          position: Vector2(20, 20),
          priority: 10,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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

  @override
  Future<void> onLoad() async {
    await _loadHighScore();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Check if current score is higher than high score
    if (game.score > _highScore) {
      _highScore = game.score;
      text = 'Highscore: $_highScore';
    }
  }

  Future<void> _loadHighScore() async {
    final scores = await DatabaseHelper.instance.getHighScores();
    if (scores.isNotEmpty) {
      _highScore = scores.first['score'];
      text = 'Highscore: $_highScore';
    }
  }
}
