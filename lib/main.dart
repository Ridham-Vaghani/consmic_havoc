import 'package:cosmic_havoc/my_game.dart';
import 'package:cosmic_havoc/overlays/game_over_overlay.dart';
import 'package:cosmic_havoc/overlays/high_score_overlay.dart';
import 'package:cosmic_havoc/overlays/pause_overlay.dart';
import 'package:cosmic_havoc/overlays/settings_overlay.dart';
import 'package:cosmic_havoc/overlays/title_overlay.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

void main() {
  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final MyGame game = MyGame();

  runApp(GameWidget(
    game: game,
    overlayBuilderMap: {
      'GameOver': (context, MyGame game) => GameOverOverlay(game: game),
      'Title': (context, MyGame game) => TitleOverlay(game: game),
      'HighScore': (context, MyGame game) => HighScoreOverlay(
            game: game,
            currentScore: game.score,
          ),
      'Settings': (context, MyGame game) => SettingsOverlay(
            onSpeedChanged: game.updateGameSpeed,
            game: game,
          ),
      'Pause': (context, MyGame game) => PauseOverlay(game: game),
    },
    initialActiveOverlays: const ['Title'],
  ));
}
