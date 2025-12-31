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
  late TextComponent scoreText;
  late TextComponent instructionText;

  bool isGameStarted = false;
  bool isRunning = false;
  bool isPaused = false;
  double score = 0;
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

    // Add score display
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);

    // Add instruction text
    instructionText = TextComponent(
      text: 'TAP TO START',
      position: Vector2(size.x / 2, size.y / 2 - 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(instructionText);

    // Add Go button (bottom right corner, on top of everything)
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
        instructionText.text = 'HOLD GO TO RUN';
      }
    } else if (gameState == stateRunning) {
      if (isRunning) {
        // Update score while running
        score += dt * 10;
        scoreText.text = 'Score: ${score.toInt()}';

        // Track distance for question triggers
        distanceTraveled += gameSpeed * dt;

        // Check if reached question point
        if (distanceTraveled >= nextQuestionDistance &&
            currentQuestionIndex < questions.length) {
          pauseForQuestion();
        }

        // Gradually increase speed
        gameSpeed = 300.0 + (score / 10);
      }
    }
  }

  void startGame() {
    if (gameState == stateIdle) {
      gameState = stateWalkingToPosition;
      isGameStarted = true;
      instructionText.text = '';
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == stateIdle) {
      startGame();
    }
    // Running is now controlled by Go button
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

  HadiCharacter() : super(size: Vector2(80, 104), anchor: Anchor.bottomCenter);

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

    // Position character at left side, on the road
    position = Vector2(
      -size.x, // Start off screen
      game.size.y - ParallaxBackground.roadHeight,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Control animation based on walking state
    animationTicker?.paused = !isWalking;
  }
}

class GoButton extends SpriteComponent
    with HasGameReference<HadiGame>, TapCallbacks {
  GoButton()
    : super(size: Vector2(150, 100), anchor: Anchor.bottomRight, priority: 100);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the go button sprite
    sprite = await Sprite.load('go_btn.png');

    // Position at bottom right corner with some padding
    position = Vector2(game.size.x - 20, game.size.y - 20);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    // Don't allow running when game is paused for question
    if (game.isPaused) return true;

    if (game.gameState == HadiGame.stateRunning) {
      game.isRunning = true;
      game.character.isWalking = true;
    }
    return true;
  }

  @override
  bool onTapUp(TapUpEvent event) {
    if (game.isPaused) return true;
    game.isRunning = false;
    game.character.isWalking = false;
    return true;
  }

  @override
  bool onTapCancel(TapCancelEvent event) {
    if (game.isPaused) return true;
    game.isRunning = false;
    game.character.isWalking = false;
    return true;
  }
}
