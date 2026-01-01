// =============================================================================
// HADI GAME - A Flame-based side-scrolling game
// =============================================================================
//
// FLAME BASICS FOR FLUTTER DEVELOPERS:
// ------------------------------------
// - FlameGame: The main game class (like MaterialApp in Flutter)
// - Component: Base class for game objects (like Widget in Flutter)
// - PositionComponent: Component with position, size, angle properties
// - SpriteComponent: Displays a single image
// - SpriteAnimationComponent: Displays animated sprites (sprite sheets)
//
// LIFECYCLE METHODS:
// - onLoad(): Called once when component is added (like initState)
// - update(dt): Called every frame with delta time in seconds (for game logic)
// - render(canvas): Called every frame to draw (like CustomPainter.paint)
// - onGameResize(): Called when screen size changes (like didChangeMetrics)
//
// KEY DIFFERENCES FROM FLUTTER:
// - No setState() - components auto-repaint every frame
// - Position/size are Vector2, not Offset/Size
// - Priority (int) controls render order (higher = on top, like Stack's z-index)
// - Mixins add capabilities (TapCallbacks, HasGameReference, etc.)
// =============================================================================

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadi/app/data/models/question_model.dart';

// =============================================================================
// MAIN GAME CLASS
// =============================================================================
// FlameGame is the root of your game - similar to MaterialApp in Flutter.
//
// MIXINS EXPLAINED:
// - TapCallbacks: Adds onTapDown, onTapUp, onTapCancel for touch handling
// - KeyboardEvents: Adds onKeyEvent for keyboard input (desktop/web)
//
// The game runs at ~60 FPS. Each frame:
// 1. update(dt) is called on all components (game logic)
// 2. render(canvas) is called on all components (drawing)
// =============================================================================
class HadiGame extends FlameGame with TapCallbacks, KeyboardEvents {
  // 'late' means initialized later in onLoad() - like late final in Dart
  late HadiCharacter character;

  // Status bars for game stats
  late StatusBarsComponent statusBars;
  int resolve = 70;
  int publicPower = 70;
  int systemPressure = 70;

  // Game state flags
  bool isGameStarted = false;
  bool isRunning = false; // True when player is holding GO button
  bool isPaused = false; // True during question overlay
  double gameSpeed = 300.0; // Pixels per second

  // Game states - using constants instead of enum for simplicity
  // This is a simple state machine pattern
  static const int stateIdle = 0; // Waiting to start
  static const int stateWalkingToPosition = 1; // Character walking into view
  static const int stateRunning = 2; // Main gameplay
  static const int statePausedForQuestion = 3; // Question overlay shown
  int gameState = stateIdle;

  // Character target position (where it stops walking)
  double characterTargetX = 0;

  // Questions system
  List<QuestionModel> questions = [];
  int currentQuestionIndex = 0;
  double nextQuestionDistance = 500; // Distance until next question
  double distanceTraveled = 0; // Track how far player has run

  // Callback to show question overlay in Flutter UI
  // This bridges Flame game to Flutter widgets
  void Function(QuestionModel question)? onShowQuestion;

  // Parallax background handler
  late ParallaxBackground parallaxBg;

  // backgroundColor() is a FlameGame override - sets the canvas clear color
  @override
  Color backgroundColor() => const Color(0xFF938E9D);

  late GoButton goButton;

  // ---------------------------------------------------------------------------
  // onLoad() - Called once when game starts (like initState)
  // This is async so you can load assets, read files, etc.
  // ---------------------------------------------------------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad(); // Always call super first

    // Load questions from JSON asset
    await _loadQuestions();

    // Set character's target X position (20% from left edge)
    characterTargetX = size.x * 0.2;

    // Add components to the game using add()
    // Components are added in order, but 'priority' controls render order

    // Add radial gradient background (priority -100, renders first/behind)
    add(GradientBackground());

    // Add parallax layers (cloud, mountain, road)
    parallaxBg = ParallaxBackground();
    add(parallaxBg);

    // Add character (default priority 0)
    character = HadiCharacter();
    add(character);

    // Add status bars (priority 50, renders on top)
    statusBars = StatusBarsComponent();
    add(statusBars);

    // Add Go button (priority 100, topmost)
    goButton = GoButton();
    add(goButton);
  }

  // Load questions from JSON asset file
  // rootBundle is Flutter's asset loader (same as in regular Flutter)
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

  // Apply stat effects when player answers a question
  void applyEffect(OptionEffect effect) {
    resolve = (resolve + effect.resolve).clamp(0, 100);
    publicPower = (publicPower + effect.publicPower).clamp(0, 100);
    systemPressure = (systemPressure + effect.systemPressure).clamp(0, 100);
    statusBars.updateBars(); // Trigger visual update
  }

  // Pause game and show question overlay
  void pauseForQuestion() {
    if (questions.isEmpty || currentQuestionIndex >= questions.length) return;

    isPaused = true;
    isRunning = false;
    character.isWalking = false;
    gameState = statePausedForQuestion;

    // Call the Flutter UI callback to show question dialog
    final question = questions[currentQuestionIndex];
    onShowQuestion?.call(question);
  }

  // Resume game after question is answered
  void resumeGame() {
    isPaused = false;
    gameState = stateRunning;
    currentQuestionIndex++;
    // Set next question distance (increases with each question)
    nextQuestionDistance = 300 + (currentQuestionIndex * 100);
    distanceTraveled = 0; // Reset distance counter
  }

  // ---------------------------------------------------------------------------
  // update(dt) - Called every frame (60 times per second)
  // dt = "delta time" = seconds since last frame (usually ~0.016 for 60 FPS)
  //
  // IMPORTANT: Always multiply movement by dt for consistent speed!
  // Example: position.x += 100 * dt means "move 100 pixels per second"
  // Without dt, movement would vary with frame rate.
  // ---------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt); // Calls update on all child components

    if (gameState == stateWalkingToPosition) {
      // Character walks from off-screen to target position
      if (character.position.x < characterTargetX) {
        character.position.x += 100 * dt; // 100 pixels per second
        character.isWalking = true;
      } else {
        // Reached target - switch to running state
        character.position.x = characterTargetX;
        gameState = stateRunning;
      }
    } else if (gameState == stateRunning) {
      if (isRunning) {
        // Track distance for triggering questions
        distanceTraveled += gameSpeed * dt;

        // Check if reached question trigger point
        if (distanceTraveled >= nextQuestionDistance &&
            currentQuestionIndex < questions.length) {
          pauseForQuestion();
        }

        // Gradually increase speed as player progresses
        gameSpeed = 300.0 + (distanceTraveled / 100);
      }
    }
  }

  // Start the game - called when START button is tapped
  void startGame() {
    if (gameState == stateIdle) {
      gameState = stateWalkingToPosition;
      isGameStarted = true;
      goButton.onGameStarted(); // Update button appearance
    }
  }

  // ---------------------------------------------------------------------------
  // TAP CALLBACKS
  // These are from TapCallbacks mixin. They handle touch on the entire game.
  // Note: Individual components (like GoButton) can also have their own tap handlers.
  // ---------------------------------------------------------------------------
  @override
  void onTapDown(TapDownEvent event) {
    // Game start is now handled by Go button component
  }

  @override
  void onTapUp(TapUpEvent event) {
    // Running is now controlled by Go button component
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    // Running is now controlled by Go button component
  }

  // ---------------------------------------------------------------------------
  // KEYBOARD EVENTS (for desktop/web)
  // From KeyboardEvents mixin
  // ---------------------------------------------------------------------------
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
    return KeyEventResult.handled; // Consume the event
  }
}

// =============================================================================
// GRADIENT BACKGROUND COMPONENT
// =============================================================================
// PositionComponent is a Component with position, size, and angle.
//
// HasGameReference<HadiGame> mixin gives access to 'game' property,
// which is the parent HadiGame instance. This is how components
// communicate with the main game (similar to context in Flutter).
// =============================================================================
class GradientBackground extends PositionComponent
    with HasGameReference<HadiGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size; // game.size is the screen size (Vector2)
    priority = -100; // Negative priority = render behind other components
  }

  // Called when screen size changes (rotation, resize)
  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }

  // ---------------------------------------------------------------------------
  // render(canvas) - Draw the component
  // This is called every frame. You get a raw Canvas (same as CustomPainter).
  // The canvas is already translated to this component's position.
  // ---------------------------------------------------------------------------
  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x > size.y ? size.x : size.y;

    // Create radial gradient (center is lighter, edges are darker)
    final gradient = ui.Gradient.radial(
      center,
      radius,
      [
        const Color(0xFFC9BCC0), // Center color (light)
        const Color(0xFF938E9D), // Outer color (dark)
      ],
      [0.0, 1.0], // Gradient stops
    );

    final paint = Paint()..shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

// =============================================================================
// PARALLAX BACKGROUND
// =============================================================================
// Parallax effect: layers move at different speeds to create depth illusion.
// Distant objects (clouds) move slower than close objects (road).
//
// This is a "controller" component that doesn't render itself,
// but creates and manages other components (the layers).
// =============================================================================
class ParallaxBackground extends Component with HasGameReference<HadiGame> {
  late ParallaxLayer cloudLayer;
  late ParallaxLayer mountainLayer;
  late ParallaxLayer roadLayer;

  // Used for character positioning calculations
  static const double roadHeight = 80;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Each layer has a different speedMultiplier:
    // - Lower value = moves slower = appears further away
    // - Higher value = moves faster = appears closer

    // Cloud layer - slowest (furthest back), priority -30
    cloudLayer = ParallaxLayer(
      imagePath: 'cloud.png',
      speedMultiplier: 0.1, // 10% of game speed
      priority: -30,
    );
    game.add(cloudLayer);

    // Mountain layer - medium speed, priority -20 (renders on top of clouds)
    mountainLayer = ParallaxLayer(
      imagePath: 'mountain.png',
      speedMultiplier: 0.3, // 30% of game speed
      priority: -20,
    );
    game.add(mountainLayer);

    // Road layer - fastest (closest), priority -10 (renders on top of mountains)
    roadLayer = ParallaxLayer(
      imagePath: 'road.png',
      speedMultiplier: 1.0, // 100% of game speed (same as character)
      priority: -10,
    );
    game.add(roadLayer);
  }
}

// =============================================================================
// PARALLAX LAYER
// =============================================================================
// A single scrolling layer that tiles horizontally for infinite scrolling.
//
// HOW INFINITE SCROLLING WORKS:
// 1. Load one image and calculate how many copies needed to fill screen + buffer
// 2. Track scrollOffset (total distance scrolled)
// 3. In render(), draw multiple copies side by side
// 4. Use modulo (%) to wrap the offset, creating seamless loop
// =============================================================================
class ParallaxLayer extends PositionComponent with HasGameReference<HadiGame> {
  final String imagePath; // Asset path for the layer image
  final double speedMultiplier; // How fast this layer moves (0.0 - 1.0)
  final int layerPriority; // Render order

  Sprite? layerSprite; // The loaded image (Sprite wraps a dart:ui Image)
  double scrollOffset = 0; // Total pixels scrolled (accumulates over time)

  ParallaxLayer({
    required this.imagePath,
    required this.speedMultiplier,
    required int priority,
  }) : layerPriority = priority,
       super(priority: priority); // Pass priority to parent constructor

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Sprite.load() loads from assets/images/ folder by default
    // Flame has its own image cache, so images are loaded once
    layerSprite = await Sprite.load(imagePath);

    // Cover full screen
    position = Vector2(0, 0);
    size = Vector2(game.size.x, game.size.y);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Only scroll when player is running
    if (game.isRunning) {
      // Accumulate scroll distance
      // speedMultiplier creates parallax effect (slower = further away)
      scrollOffset += game.gameSpeed * speedMultiplier * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    if (layerSprite == null) return;

    // Get original image dimensions
    final spriteWidth = layerSprite!.srcSize.x;
    final spriteHeight = layerSprite!.srcSize.y;

    // Scale image to fit full screen height while maintaining aspect ratio
    final scale = game.size.y / spriteHeight;
    final scaledWidth = spriteWidth * scale;
    final scaledHeight = game.size.y;

    // Calculate how many copies needed to fill screen + 2 extra for scrolling buffer
    final numTiles = (game.size.x / scaledWidth).ceil() + 2;

    // Use modulo to create seamless loop
    // When scrollOffset reaches scaledWidth, it wraps back to 0
    final offset = scrollOffset % scaledWidth;

    // Draw multiple copies side by side
    for (int i = 0; i < numTiles; i++) {
      final xPos =
          i * scaledWidth -
          offset; // Each tile offset by its index minus scroll
      layerSprite!.render(
        canvas,
        position: Vector2(xPos, 0),
        size: Vector2(scaledWidth, scaledHeight),
      );
    }
  }
}

// =============================================================================
// HADI CHARACTER (ANIMATED SPRITE)
// =============================================================================
// SpriteAnimationComponent displays animated sprites from a sprite sheet.
//
// SPRITE SHEET: A single image containing multiple animation frames.
// Example: 6 walking poses side by side in one image.
//
// ANCHOR: The reference point for position/rotation.
// - Anchor.bottomLeft: position refers to bottom-left corner
// - Anchor.center: position refers to center of sprite
// This is important for placing character "on the ground"
// =============================================================================
class HadiCharacter extends SpriteAnimationComponent
    with HasGameReference<HadiGame> {
  bool isWalking = false; // Controls animation play/pause

  // Responsive sizing: define a base reference and scale proportionally
  // This ensures character looks correct on different screen sizes
  static const double baseScreenHeight = 500.0; // Design reference height
  static const double baseCharacterHeight =
      80.0; // Character height at 500px screen
  static const double baseBottomOffset =
      180.0; // Distance from bottom at 500px screen

  // For handling screen resize - store relative position
  double relativeX = 0.0;
  bool hasStarted = false;

  HadiCharacter() : super(anchor: Anchor.bottomLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load sprite sheet image
    // game.images.load() uses Flame's image cache
    final spriteSheet = await game.images.load('c.png');

    // Create animation from sprite sheet
    // SpriteAnimationData.sequenced() = frames are arranged in a row
    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 5, // Number of frames to use
        stepTime: 0.15, // Seconds per frame (0.15 = ~6.6 FPS animation)
        textureSize: Vector2(
          spriteSheet.width / 6, // Each frame width (6 frames in sheet, use 5)
          spriteSheet.height.toDouble(), // Full height
        ),
      ),
    );

    // animationTicker controls playback
    // Start paused - we'll unpause when character walks
    animationTicker?.paused = true;

    _updateSizeAndPosition();
  }

  // Calculate size and position based on screen size
  void _updateSizeAndPosition() {
    // Scale factor: current screen height / design reference height
    final ratio = game.size.y / baseScreenHeight;

    // Scale character proportionally
    final characterHeight = baseCharacterHeight * ratio;
    final characterWidth =
        characterHeight * (80 / 104); // Maintain aspect ratio
    size = Vector2(characterWidth, characterHeight);

    // Scale position from bottom
    final bottomOffset = baseBottomOffset * ratio;

    if (!hasStarted) {
      // Start off-screen to the left
      position = Vector2(-size.x, game.size.y - bottomOffset + characterHeight);
    } else {
      // Maintain relative X position (percentage of screen width)
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
      // Save relative position before resize
      if (position.x > 0) {
        relativeX = position.x / game.size.x;
      }
      _updateSizeAndPosition();
      game.characterTargetX = game.size.x * 0.2;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Track when character enters screen
    if (position.x > 0 && !hasStarted) {
      hasStarted = true;
    }

    // Update relative position for resize handling
    if (hasStarted && game.size.x > 0) {
      relativeX = position.x / game.size.x;
    }

    // Play/pause animation based on walking state
    // When paused, animation freezes on current frame
    animationTicker?.paused = !isWalking;
  }
}

// =============================================================================
// GO BUTTON (INTERACTIVE COMPONENT)
// =============================================================================
// TapCallbacks mixin adds touch handling to individual components.
// This is different from game-level tap handlers - each component
// can handle its own touches independently.
//
// The button has two states:
// 1. Before game starts: Shows "START" text (drawn manually)
// 2. After game starts: Shows go_btn.png sprite
// =============================================================================
class GoButton extends PositionComponent
    with HasGameReference<HadiGame>, TapCallbacks {
  // Responsive sizing constants
  static const double baseScreenHeight = 500.0;
  static const double baseButtonHeight = 52.0;
  static const double baseBottomOffset = 130.0;

  bool showStartText = true; // Toggle between text and sprite
  Sprite? goSprite;

  // priority: 100 = render on top of everything
  GoButton() : super(anchor: Anchor.bottomRight, priority: 100);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the GO button sprite
    goSprite = await Sprite.load('go_btn.png');

    _updateSizeAndPosition();
  }

  void _updateSizeAndPosition() {
    final ratio = game.size.y / baseScreenHeight;
    final buttonHeight = baseButtonHeight * ratio;
    final buttonWidth = buttonHeight * (150 / 52); // Aspect ratio
    size = Vector2(buttonWidth, buttonHeight);

    final bottomOffset = baseBottomOffset * ratio;

    // Position at bottom-right with 20px margin
    // Anchor.bottomRight means position refers to bottom-right corner
    position = Vector2(
      game.size.x - 20,
      game.size.y - bottomOffset + buttonHeight,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (game.isLoaded) {
      _updateSizeAndPosition();
    }
  }

  // Called by game when START is tapped
  void onGameStarted() {
    showStartText = false; // Switch to showing sprite
  }

  @override
  void render(Canvas canvas) {
    if (showStartText) {
      // Draw custom START button (no sprite, just shapes and text)

      // Draw rounded rectangle background
      final bgPaint = Paint()..color = const Color(0xFFE94560);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(12),
      );
      canvas.drawRRect(rect, bgPaint);

      // Draw text using TextPainter (same as Flutter CustomPainter)
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
      // Center text in button
      textPainter.paint(
        canvas,
        Offset(
          (size.x - textPainter.width) / 2,
          (size.y - textPainter.height) / 2,
        ),
      );
    } else if (goSprite != null) {
      // Draw the GO button sprite
      goSprite!.render(canvas, size: size);
    }
  }

  // ---------------------------------------------------------------------------
  // TAP CALLBACKS
  // Return true to "consume" the event (stop propagation).
  // Return false to let the event bubble to parent/game.
  // ---------------------------------------------------------------------------
  @override
  bool onTapDown(TapDownEvent event) {
    // Ignore taps when game is paused for question
    if (game.isPaused) return true;

    if (game.gameState == HadiGame.stateIdle) {
      game.startGame();
    } else if (game.gameState == HadiGame.stateRunning) {
      // Start running when button is pressed
      game.isRunning = true;
      game.character.isWalking = true;
    }
    return true; // Consume the event
  }

  @override
  bool onTapUp(TapUpEvent event) {
    if (game.isPaused) return true;
    if (game.gameState == HadiGame.stateRunning) {
      // Stop running when button is released
      game.isRunning = false;
      game.character.isWalking = false;
    }
    return true;
  }

  @override
  bool onTapCancel(TapCancelEvent event) {
    // Called when tap is cancelled (finger moved away, etc.)
    if (game.isPaused) return true;
    if (game.gameState == HadiGame.stateRunning) {
      game.isRunning = false;
      game.character.isWalking = false;
    }
    return true;
  }
}

// =============================================================================
// STATUS BARS COMPONENT (HUD - Heads Up Display)
// =============================================================================
// This component displays 3 progress bars at the top of the screen.
// It's a common pattern for game UI - render everything manually in render().
//
// WHY MANUAL RENDERING INSTEAD OF FLUTTER WIDGETS?
// - Performance: No widget tree overhead
// - Integration: Lives in the game's render loop
// - Control: Precise pixel-perfect positioning
//
// You could also use Flutter widgets via GameWidget's overlayBuilderMap
// for more complex UI (menus, dialogs, etc.)
// =============================================================================
class StatusBarsComponent extends PositionComponent
    with HasGameReference<HadiGame> {
  // Responsive sizing constants (design reference: 500px screen height)
  static const double baseScreenHeight = 500.0;
  static const double baseBarHeight = 16.0;
  static const double baseBarWidth = 100.0;
  static const double basePadding = 12.0;
  static const double baseFontSize = 10.0;
  static const double baseSpacing = 8.0;

  // Bar labels in Bangla
  static const String resolveLabel = 'সংকল্প';
  static const String publicPowerLabel = 'জনশক্তি';
  static const String systemPressureLabel = 'সিস্টেম চাপ';

  // Bar colors (using game's theme colors)
  static const Color resolveColor = Color(0xFFE94560); // Red
  static const Color publicPowerColor = Color(0xFFC9BCC0); // Light
  static const Color systemPressureColor = Color(0xFF938E9D); // Purple-gray
  static const Color barBackground = Color(
    0x44000000,
  ); // Semi-transparent black

  // priority: 50 = render above game elements but below UI buttons
  StatusBarsComponent() : super(priority: 50);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(game.size.x, 60); // Full width, 60px tall
    position = Vector2(0, 0); // Top-left corner
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = Vector2(newSize.x, 60);
  }

  // Called to trigger visual update (not strictly needed since render() runs every frame)
  void updateBars() {
    // In Flame, components automatically repaint every frame
    // This method exists for semantic clarity in the calling code
  }

  @override
  void render(Canvas canvas) {
    // Calculate scaled dimensions based on screen size
    final ratio = game.size.y / baseScreenHeight;
    final barHeight = baseBarHeight * ratio;
    final barWidth = baseBarWidth * ratio;
    final padding = basePadding * ratio;
    final fontSize = baseFontSize * ratio;
    final spacing = baseSpacing * ratio;
    final labelSpacing = 4.0 * ratio;

    // Center all 3 bars horizontally
    final totalWidth = (barWidth * 3) + (spacing * 2);
    final startX = (game.size.x - totalWidth) / 2;

    // Draw each bar
    _drawBar(
      canvas: canvas,
      label: resolveLabel,
      value: game.resolve, // Get value from game
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

  // Helper method to draw a single bar with label and value
  void _drawBar({
    required Canvas canvas,
    required String label,
    required int value, // 0-100
    required Color color,
    required double x,
    required double y,
    required double width,
    required double height,
    required double fontSize,
    required double labelSpacing,
  }) {
    // Draw label text above bar
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

    // Draw background bar (the empty part)
    final bgPaint = Paint()..color = barBackground;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, barY, width, height),
      Radius.circular(height / 2), // Pill shape
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Draw filled portion based on value (0-100)
    final fillWidth = (value / 100) * width;
    final fillPaint = Paint()..color = color;
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, barY, fillWidth, height),
      Radius.circular(height / 2),
    );
    canvas.drawRRect(fillRect, fillPaint);

    // Draw value number in center of bar
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
