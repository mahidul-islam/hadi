import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hadi/app/data/models/question_model.dart';

import '../controllers/game_controller.dart';
import '../game/hadi_game.dart';
import '../widgets/question_overlay.dart';
import '../widgets/rotate_device_overlay.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    // Set preferred orientations to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Set up question callback
    controller.game.onShowQuestion = (question) {
      controller.currentQuestion.value = question;
      controller.game.overlays.add('question');
    };

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Check if screen is in portrait mode (height > width)
          final isPortrait = constraints.maxHeight > constraints.maxWidth;

          // Update controller's portrait state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.isPortraitMode.value = isPortrait;
            if (isPortrait) {
              controller.game.pauseEngine();
              controller.game.overlays.add('rotate');
            }
          });

          return GameWidget<HadiGame>(
            game: controller.game,
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFe94560)),
              ),
            ),
            errorBuilder: (context, error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            overlayBuilderMap: {
              'rotate': (context, game) => RotateDeviceOverlay(
                onCheckAgain: () {
                  // Check if now in landscape
                  final size = MediaQuery.of(context).size;
                  if (size.width > size.height) {
                    game.overlays.remove('rotate');
                    game.resumeEngine();
                    controller.isPortraitMode.value = false;
                  }
                },
              ),
              'question': (context, game) => Obx(() {
                final question = controller.currentQuestion.value;
                if (question == null) return const SizedBox.shrink();
                return QuestionOverlay(
                  question: question,
                  onAnswerSelected: (int index, OptionEffect effect) {
                    // Apply the effect to game stats
                    game.applyEffect(effect);
                    // Close overlay and resume
                    game.overlays.remove('question');
                    game.resumeGame();
                    controller.currentQuestion.value = null;
                  },
                );
              }),
              'pause': (context, game) => Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PAUSED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          game.resumeEngine();
                          game.overlays.remove('pause');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFe94560),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          'RESUME',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            },
          );
        },
      ),
    );
  }
}
