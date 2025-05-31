import 'package:cosmic_havoc/database/database_helper.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

class HighScoreOverlay extends StatefulWidget {
  final MyGame game;
  final int currentScore;

  const HighScoreOverlay({
    super.key,
    required this.game,
    required this.currentScore,
  });

  @override
  State<HighScoreOverlay> createState() => _HighScoreOverlayState();
}

class _HighScoreOverlayState extends State<HighScoreOverlay> {
  bool _isNewHighScore = false;

  @override
  void initState() {
    super.initState();
    _checkAndSaveHighScore();
  }

  Future<void> _checkAndSaveHighScore() async {
    final scores = await DatabaseHelper.instance.getHighScores();
    setState(() {
      _isNewHighScore =
          scores.isEmpty || widget.currentScore > scores.last['score'];
    });

    if (_isNewHighScore) {
      await DatabaseHelper.instance.insertScore(widget.currentScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Container(
      color: Colors.black.withAlpha(150),
      child: Center(
        child: Container(
          width: size.width * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(200),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Score: ${widget.currentScore}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isNewHighScore) ...[
                const SizedBox(height: 10),
                const Text(
                  'NEW HIGH SCORE!',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.game.audioManager.playSound('click');
                      widget.game.overlays.remove('HighScore');
                      widget.game.restartGame();
                    },
                    child: const Text('PLAY AGAIN'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.game.audioManager.playSound('click');
                      widget.game.overlays.remove('HighScore');
                      widget.game.quitGame();
                    },
                    child: const Text('MAIN MENU'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
