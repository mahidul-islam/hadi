import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HadiGame extends FlameGame with TapCallbacks, KeyboardEvents {
  late HadiCharacter character;
  late Ground ground;
  late TextComponent scoreText;
  late TextComponent instructionText;

  bool isGameStarted = false;
  bool isRunning = false;
  double score = 0;
  double gameSpeed = 300.0;

  // Game states
  static const int stateIdle = 0;
  static const int stateWalkingToPosition = 1;
  static const int stateRunning = 2;
  int gameState = stateIdle;

  // Character target position (where it stops walking)
  double characterTargetX = 0;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB); // Sky blue

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    characterTargetX = size.x * 0.2;

    // Add clouds
    for (int i = 0; i < 5; i++) {
      add(Cloud(position: Vector2(size.x * (i / 5) + 50, 50 + (i % 3) * 40.0)));
    }

    // Add ground
    ground = Ground();
    add(ground);

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
        instructionText.text = 'HOLD TO RUN';
      }
    } else if (gameState == stateRunning) {
      if (isRunning) {
        // Update score while running
        score += dt * 10;
        scoreText.text = 'Score: ${score.toInt()}';

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
    } else if (gameState == stateRunning) {
      isRunning = true;
      character.isWalking = true;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (gameState == stateRunning) {
      isRunning = false;
      character.isWalking = false;
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (gameState == stateRunning) {
      isRunning = false;
      character.isWalking = false;
    }
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

class Cloud extends PositionComponent with HasGameReference<HadiGame> {
  Cloud({required super.position}) : super(size: Vector2(80, 40));

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isRunning) {
      // Move cloud backwards (slower than ground for parallax effect)
      position.x -= game.gameSpeed * 0.3 * dt;

      // Wrap around when off screen
      if (position.x < -size.x) {
        position.x = game.size.x + 50;
        position.y = 30 + (position.y.toInt() % 80);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    // Draw cloud shape (multiple overlapping circles)
    canvas.drawCircle(const Offset(20, 25), 20, paint);
    canvas.drawCircle(const Offset(40, 20), 25, paint);
    canvas.drawCircle(const Offset(60, 25), 20, paint);
    canvas.drawCircle(const Offset(40, 30), 20, paint);
  }
}

class Ground extends Component with HasGameReference<HadiGame> {
  final List<GroundTile> tiles = [];
  static const double groundHeight = 100;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create ground tiles that span the screen
    const tileWidth = 100.0;
    final numTiles = (game.size.x / tileWidth).ceil() + 2;

    for (int i = 0; i < numTiles; i++) {
      final tile = GroundTile(
        position: Vector2(i * tileWidth, game.size.y - groundHeight),
        tileWidth: tileWidth,
      );
      tiles.add(tile);
      game.add(tile);
    }
  }
}

class GroundTile extends PositionComponent with HasGameReference<HadiGame> {
  final double tileWidth;

  GroundTile({required super.position, required this.tileWidth})
    : super(size: Vector2(tileWidth, Ground.groundHeight));

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isRunning) {
      // Move ground backwards
      position.x -= game.gameSpeed * dt;

      // Wrap around when off screen
      if (position.x < -tileWidth) {
        position.x += tileWidth * ((game.size.x / tileWidth).ceil() + 2);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Ground base
    final groundPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawRect(Rect.fromLTWH(0, 0, tileWidth + 1, size.y), groundPaint);

    // Grass on top
    final grassPaint = Paint()..color = const Color(0xFF228B22);
    canvas.drawRect(Rect.fromLTWH(0, 0, tileWidth + 1, 20), grassPaint);

    // Add some grass detail
    final detailPaint = Paint()
      ..color = const Color(0xFF32CD32)
      ..strokeWidth = 2;

    for (int i = 0; i < tileWidth.toInt(); i += 10) {
      canvas.drawLine(
        Offset(i.toDouble(), 20),
        Offset(i.toDouble() + 3, 10),
        detailPaint,
      );
    }
  }
}

class HadiCharacter extends SpriteComponent with HasGameReference<HadiGame> {
  bool isWalking = false;
  double walkCycle = 0;
  double bobAmount = 0;

  HadiCharacter() : super(size: Vector2(80, 80), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the hadi.png sprite
    sprite = await Sprite.load('hadi.png');

    // Position character at left side, on the ground
    position = Vector2(
      -size.x, // Start off screen
      game.size.y - Ground.groundHeight,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isWalking) {
      // Walking animation (bobbing up and down)
      walkCycle += dt * 15;
      bobAmount = (walkCycle).abs() % 2 < 1 ? -3 : 3;
    } else {
      bobAmount = 0;
      walkCycle = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    // Apply bob offset for walking animation
    canvas.save();
    canvas.translate(0, bobAmount);
    super.render(canvas);
    canvas.restore();
  }
}
