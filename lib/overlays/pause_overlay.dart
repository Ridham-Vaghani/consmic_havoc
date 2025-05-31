import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

class PauseOverlay extends StatelessWidget {
  final MyGame game;

  const PauseOverlay({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          elevation: 8,
          color: Colors.black.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          child: Container(
            width: size.width * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paused',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildButton(
                  'Continue',
                  Colors.green,
                  () {
                    game.resumeEngine();
                    game.overlays.remove('Pause');
                  },
                ),
                const SizedBox(height: 15),
                _buildButton(
                  'Restart',
                  Colors.orange,
                  () {
                    game.overlays.remove('Pause');
                    game.restartGame();
                  },
                ),
                const SizedBox(height: 15),
                _buildButton(
                  'Settings',
                  Colors.blue,
                  () {
                    game.overlays.remove('Pause');
                    game.overlays.add('Settings');
                  },
                ),
                const SizedBox(height: 15),
                _buildButton(
                  'Exit',
                  Colors.red,
                  () {
                    game.overlays.remove('Pause');
                    game.quitGame();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
