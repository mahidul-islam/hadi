import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadi/app/data/models/question_model.dart';

class HadiGame extends FlameGame with TapCallbacks, KeyboardEvents {
  late HadiCharacter character;

  // Status bars
  late StatusBarsComponent statusBars;
  int resolve = 70;
  int publicPower = 70;
  int systemPressure = 70;

  bool isGameStarted = false;
  bool isRunning = false;
  bool isPaused = false;
  double gameSpeed = 300.0;

  // Game states
  static const int stateIdle = 0;
  static const int stateWalkingToPosition = 1;
  static const int stateRunning = 2;
  static const int statePausedForQuestion = 3;
  int gameState = stateIdle;

  // Character target position (where it stops walking)
  double characterTargetX = 0;

  // Questions
  List<QuestionModel> questions = [];
  int currentQuestionIndex = 0;
  double nextQuestionDistance = 500; // Distance until next question point
  double distanceTraveled = 0;

  // Callback for showing question overlay
  void Function(QuestionModel question)? onShowQuestion;

  // Parallax layers
  late ParallaxBackground parallaxBg;

  @override
  Color backgroundColor() => const Color(0xFF938E9D); // Fallback color

  late GoButton goButton;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load questions from JSON
    await _loadQuestions();

    characterTargetX = size.x * 0.2;

    // Add radial gradient background
    add(GradientBackground());

    // Add parallax layers (cloud, mountain, road) - ordered by depth
    parallaxBg = ParallaxBackground();
    add(parallaxBg);

    // Add character
    character = HadiCharacter();
    add(character);

    // Add status bars (on top of everything except Go button)
    statusBars = StatusBarsComponent();
    add(statusBars);

    // Add Go button (bottom right corner, on top of everything)
    // Initially shows "START", then becomes "GO" after game starts
    goButton = GoButton();
    add(goButton);
  }

  Future<void> _loadQuestions() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/questions.json',
      );
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final questionsData = QuestionsData.fromJson(jsonData);
      questions = questionsData.questions;
    } catch (e) {
      debugPrint('Error loading questions: $e');
    }
  }

  void applyEffect(OptionEffect effect) {
    resolve = (resolve + effect.resolve).clamp(0, 100);
    publicPower = (publicPower + effect.publicPower).clamp(0, 100);
    systemPressure = (systemPressure + effect.systemPressure).clamp(0, 100);
    statusBars.updateBars();
  }

  void pauseForQuestion() {
    if (questions.isEmpty || currentQuestionIndex >= questions.length) return;

    isPaused = true;
    isRunning = false;
    character.isWalking = false;
    gameState = statePausedForQuestion;

    // Show question overlay
    final question = questions[currentQuestionIndex];
    onShowQuestion?.call(question);
  }

  void resumeGame() {
    isPaused = false;
    gameState = stateRunning;
    currentQuestionIndex++;
    // Set next question distance (random between 300-600)
    nextQuestionDistance = 300 + (currentQuestionIndex * 100);
    distanceTraveled = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState == stateWalkingToPosition) {
      // Character walks to target position
      if (character.position.x < characterTargetX) {
        character.position.x += 100 * dt;
        character.isWalking = true;
      } else {
        character.position.x = characterTargetX;
        gameState = stateRunning;
      }
    } else if (gameState == stateRunning) {
      if (isRunning) {
        // Track distance for question triggers
        distanceTraveled += gameSpeed * dt;

        // Check if reached question point
        if (distanceTraveled >= nextQuestionDistance &&
            currentQuestionIndex < questions.length) {
          pauseForQuestion();
        }

        // Gradually increase speed
        gameSpeed = 300.0 + (distanceTraveled / 100);
      }
    }
  }

  void startGame() {
    if (gameState == stateIdle) {
      gameState = stateWalkingToPosition;
      isGameStarted = true;
      // GoButton will update its text from "START" to showing go_btn.png
      goButton.onGameStarted();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Game start is now handled by Go button
  }

  @override
  void onTapUp(TapUpEvent event) {
    // Running is now controlled by Go button
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    // Running is now controlled by Go button
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (gameState == stateIdle) {
          startGame();
        } else if (gameState == stateRunning) {
          isRunning = true;
          character.isWalking = true;
        }
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (gameState == stateRunning) {
          isRunning = false;
          character.isWalking = false;
        }
      }
    }
    return KeyEventResult.handled;
  }
}

/// Radial gradient background component
class GradientBackground extends PositionComponent
    with HasGameReference<HadiGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
    priority = -100; // Render behind everything
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x > size.y ? size.x : size.y;

    final gradient = ui.Gradient.radial(
      center,
      radius,
      [
        const Color(0xFFC9BCC0), // Center color
        const Color(0xFF938E9D), // Outer color
      ],
      [0.0, 1.0],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

/// Parallax background with cloud, mountain, and road layers
/// All layers are same-size images with transparent backgrounds that stack perfectly
class ParallaxBackground extends Component with HasGameReference<HadiGame> {
  late ParallaxLayer cloudLayer;
  late ParallaxLayer mountainLayer;
  late ParallaxLayer roadLayer;

  // Road height from bottom (for character positioning)
  static const double roadHeight = 80;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Cloud layer - slowest (furthest back)
    cloudLayer = ParallaxLayer(
      imagePath: 'cloud.png',
      speedMultiplier: 0.1,
      priority: -30,
    );
    game.add(cloudLayer);

    // Mountain layer - medium speed
    mountainLayer = ParallaxLayer(
      imagePath: 'mountain.png',
      speedMultiplier: 0.3,
      priority: -20,
    );
    game.add(mountainLayer);

    // Road layer - fastest (closest)
    roadLayer = ParallaxLayer(
      imagePath: 'road.png',
      speedMultiplier: 1.0,
      priority: -10,
    );
    game.add(roadLayer);
  }
}

/// Individual parallax layer that scrolls horizontally
/// All layers occupy the full screen height and stack on top of each other
class ParallaxLayer extends PositionComponent with HasGameReference<HadiGame> {
  final String imagePath;
  final double speedMultiplier;
  final int layerPriority;

  Sprite? layerSprite;
  double scrollOffset = 0;

  ParallaxLayer({
    required this.imagePath,
    required this.speedMultiplier,
    required int priority,
  }) : layerPriority = priority,
       super(priority: priority);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    layerSprite = await Sprite.load(imagePath);
    // Position at top-left, covering full screen
    position = Vector2(0, 0);
    size = Vector2(game.size.x, game.size.y);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    // Update size to match new screen size
    size = newSize;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isRunning) {
      scrollOffset += game.gameSpeed * speedMultiplier * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    if (layerSprite == null) return;

    final spriteWidth = layerSprite!.srcSize.x;
    final spriteHeight = layerSprite!.srcSize.y;

    // Scale to fit full screen height
    final scale = game.size.y / spriteHeight;
    final scaledWidth = spriteWidth * scale;
    final scaledHeight = game.size.y;

    // Calculate how many tiles we need to cover width + extra for scrolling
    final numTiles = (game.size.x / scaledWidth).ceil() + 2;

    // Calculate offset for seamless scrolling
    final offset = scrollOffset % scaledWidth;

    for (int i = 0; i < numTiles; i++) {
      final xPos = i * scaledWidth - offset;
      layerSprite!.render(
        canvas,
        position: Vector2(xPos, 0),
        size: Vector2(scaledWidth, scaledHeight),
      );
    }
  }
}

class HadiCharacter extends SpriteAnimationComponent
    with HasGameReference<HadiGame> {
  bool isWalking = false;

  // Base reference: at 500px screen height, character height is 80px
  // and bottom position is 180px from bottom (top-left corner of character)
  static const double baseScreenHeight = 500.0;
  static const double baseCharacterHeight = 80.0;
  static const double baseBottomOffset = 180.0; // from bottom of screen

  // Store the relative X position (0.0 to 1.0) for resize handling
  double relativeX = 0.0;
  bool hasStarted = false;

  HadiCharacter() : super(anchor: Anchor.bottomLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the sprite sheet with 3 frames
    final spriteSheet = await game.images.load('c.png');

    // Create animation from sprite sheet (5 frames, skipping duplicate last frame)
    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 5,
        stepTime: 0.15,
        textureSize: Vector2(
          spriteSheet.width / 6,
          spriteSheet.height.toDouble(),
        ),
      ),
    );

    // Start paused
    animationTicker?.paused = true;

    // Initial size and position
    _updateSizeAndPosition();
  }

  void _updateSizeAndPosition() {
    // Calculate proportional size based on screen height
    final ratio = game.size.y / baseScreenHeight;
    final characterHeight = baseCharacterHeight * ratio;
    final characterWidth =
        characterHeight * (80 / 104); // maintain aspect ratio
    size = Vector2(characterWidth, characterHeight);

    // Calculate position from bottom
    final bottomOffset = baseBottomOffset * ratio;

    // Position character based on game state
    if (!hasStarted) {
      // Start off screen
      position = Vector2(-size.x, game.size.y - bottomOffset + characterHeight);
    } else {
      // Maintain relative X position, update Y
      position = Vector2(
        relativeX * game.size.x,
        game.size.y - bottomOffset + characterHeight,
      );
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (game.isLoaded) {
      // Store relative X position before resize
      if (position.x > 0) {
        relativeX = position.x / game.size.x;
      }
      _updateSizeAndPosition();
      // Update target X as well
      game.characterTargetX = game.size.x * 0.2;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Track if character has started moving
    if (position.x > 0 && !hasStarted) {
      hasStarted = true;
    }

    // Update relative X for resize handling
    if (hasStarted && game.size.x > 0) {
      relativeX = position.x / game.size.x;
    }

    // Control animation based on walking state
    animationTicker?.paused = !isWalking;
  }
}

class GoButton extends PositionComponent
    with HasGameReference<HadiGame>, TapCallbacks {
  // Base reference: at 500px screen height, button height is 52px
  // and bottom position is 130px from bottom (top-left corner)
  static const double baseScreenHeight = 500.0;
  static const double baseButtonHeight = 52.0;
  static const double baseBottomOffset = 130.0;

  bool showStartText = true;
  Sprite? goSprite;

  GoButton() : super(anchor: Anchor.bottomRight, priority: 100);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the go button sprite
    goSprite = await Sprite.load('go_btn.png');

    // Initial size and position
    _updateSizeAndPosition();
  }

  void _updateSizeAndPosition() {
    // Calculate proportional size based on screen height
    final ratio = game.size.y / baseScreenHeight;
    final buttonHeight = baseButtonHeight * ratio;
    final buttonWidth =
        buttonHeight * (150 / 52); // maintain aspect ratio from original
    size = Vector2(buttonWidth, buttonHeight);

    // Calculate position from bottom
    final bottomOffset = baseBottomOffset * ratio;

    // Position at bottom right corner
    position = Vector2(
      game.size.x - 20,
      game.size.y - bottomOffset + buttonHeight, // bottom-right anchor
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (game.isLoaded) {
      _updateSizeAndPosition();
    }
  }

  void onGameStarted() {
    showStartText = false;
  }

  @override
  void render(Canvas canvas) {
    if (showStartText) {
      // Draw START button background
      final bgPaint = Paint()..color = const Color(0xFFE94560);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(12),
      );
      canvas.drawRRect(rect, bgPaint);

      // Draw START text - scale font size proportionally
      final ratio = game.size.y / baseScreenHeight;
      final fontSize = 18.0 * ratio;
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'START',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.x - textPainter.width) / 2,
          (size.y - textPainter.height) / 2,
        ),
      );
    } else if (goSprite != null) {
      // Draw go button sprite
      goSprite!.render(canvas, size: size);
    }
  }

  @override
  bool onTapDown(TapDownEvent event) {
    // Don't allow interaction when game is paused for question
    if (game.isPaused) return true;

    if (game.gameState == HadiGame.stateIdle) {
      // Start the game
      game.startGame();
    } else if (game.gameState == HadiGame.stateRunning) {
      game.isRunning = true;
      game.character.isWalking = true;
    }
    return true;
  }

  @override
  bool onTapUp(TapUpEvent event) {
    if (game.isPaused) return true;
    if (game.gameState == HadiGame.stateRunning) {
      game.isRunning = false;
      game.character.isWalking = false;
    }
    return true;
  }

  @override
  bool onTapCancel(TapCancelEvent event) {
    if (game.isPaused) return true;
    if (game.gameState == HadiGame.stateRunning) {
      game.isRunning = false;
      game.character.isWalking = false;
    }
    return true;
  }
}

/// Status bars component showing 3 bars at the top
class StatusBarsComponent extends PositionComponent
    with HasGameReference<HadiGame> {
  // Base reference: at 500px screen height
  static const double baseScreenHeight = 500.0;
  static const double baseBarHeight = 16.0;
  static const double baseBarWidth = 100.0;
  static const double basePadding = 12.0;
  static const double baseFontSize = 10.0;
  static const double baseSpacing = 8.0;

  // Bar names in Bangla
  static const String resolveLabel = 'সংকল্প';
  static const String publicPowerLabel = 'জনশক্তি';
  static const String systemPressureLabel = 'সিস্টেম চাপ';

  // Bar colors from game theme
  static const Color resolveColor = Color(0xFFE94560); // Accent red
  static const Color publicPowerColor = Color(0xFFC9BCC0); // Light theme
  static const Color systemPressureColor = Color(0xFF938E9D); // Dark theme
  static const Color barBackground = Color(0x44000000);

  StatusBarsComponent() : super(priority: 50);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(game.size.x, 60);
    position = Vector2(0, 0);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = Vector2(newSize.x, 60);
  }

  void updateBars() {
    // Trigger a repaint by marking dirty (no-op needed, render is called each frame)
  }

  @override
  void render(Canvas canvas) {
    final ratio = game.size.y / baseScreenHeight;
    final barHeight = baseBarHeight * ratio;
    final barWidth = baseBarWidth * ratio;
    final padding = basePadding * ratio;
    final fontSize = baseFontSize * ratio;
    final spacing = baseSpacing * ratio;
    final labelSpacing = 4.0 * ratio;

    // Calculate total width of all 3 bars with spacing
    final totalWidth = (barWidth * 3) + (spacing * 2);
    final startX = (game.size.x - totalWidth) / 2;

    // Draw the 3 bars
    _drawBar(
      canvas: canvas,
      label: resolveLabel,
      value: game.resolve,
      color: resolveColor,
      x: startX,
      y: padding,
      width: barWidth,
      height: barHeight,
      fontSize: fontSize,
      labelSpacing: labelSpacing,
    );

    _drawBar(
      canvas: canvas,
      label: publicPowerLabel,
      value: game.publicPower,
      color: publicPowerColor,
      x: startX + barWidth + spacing,
      y: padding,
      width: barWidth,
      height: barHeight,
      fontSize: fontSize,
      labelSpacing: labelSpacing,
    );

    _drawBar(
      canvas: canvas,
      label: systemPressureLabel,
      value: game.systemPressure,
      color: systemPressureColor,
      x: startX + (barWidth + spacing) * 2,
      y: padding,
      width: barWidth,
      height: barHeight,
      fontSize: fontSize,
      labelSpacing: labelSpacing,
    );
  }

  void _drawBar({
    required Canvas canvas,
    required String label,
    required int value,
    required Color color,
    required double x,
    required double y,
    required double width,
    required double height,
    required double fontSize,
    required double labelSpacing,
  }) {
    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + (width - textPainter.width) / 2, y));

    final barY = y + textPainter.height + labelSpacing;

    // Draw background bar
    final bgPaint = Paint()..color = barBackground;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, barY, width, height),
      Radius.circular(height / 2),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Draw filled bar
    final fillWidth = (value / 100) * width;
    final fillPaint = Paint()..color = color;
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, barY, fillWidth, height),
      Radius.circular(height / 2),
    );
    canvas.drawRRect(fillRect, fillPaint);

    // Draw value text
    final valuePainter = TextPainter(
      text: TextSpan(
        text: '$value',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize * 0.9,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              color: Colors.black87,
              blurRadius: 1,
              offset: Offset(0.5, 0.5),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    valuePainter.layout();
    valuePainter.paint(
      canvas,
      Offset(
        x + (width - valuePainter.width) / 2,
        barY + (height - valuePainter.height) / 2,
      ),
    );
  }
}
