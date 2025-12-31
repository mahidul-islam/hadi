import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToGame();
  }

  Future<void> _navigateToGame() async {
    // Wait for 3 seconds on splash screen
    await Future.delayed(const Duration(seconds: 3));

    // Navigate to the game screen
    Get.offAllNamed(Routes.GAME);
  }
}
