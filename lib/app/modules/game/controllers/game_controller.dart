import 'package:get/get.dart';
import 'package:hadi/app/data/models/question_model.dart';

import '../game/hadi_game.dart';

class GameController extends GetxController {
  late HadiGame game;

  // Current question being displayed
  final Rxn<QuestionModel> currentQuestion = Rxn<QuestionModel>();

  @override
  void onInit() {
    super.onInit();
    game = HadiGame();
  }

  @override
  void onClose() {
    game.pauseEngine();
    super.onClose();
  }

  void pauseGame() {
    game.pauseEngine();
    game.overlays.add('pause');
  }

  void resumeGame() {
    game.resumeEngine();
    game.overlays.remove('pause');
  }
}
