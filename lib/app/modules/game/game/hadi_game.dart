import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class HadiGame extends FlameGame with TapCallbacks, HasCollisionDetection {
  late TextComponent scoreText;
  int score = 0;

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add background gradient effect
    add(BackgroundComponent());

    // Add score display
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);

    // Add some initial game elements
    _spawnShapes();
  }

  void _spawnShapes() {
    final random = Random();

    // Spawn several shapes at random positions
    for (int i = 0; i < 5; i++) {
      final shape = GameShape(
        position: Vector2(
          random.nextDouble() * (size.x - 100) + 50,
          random.nextDouble() * (size.y - 100) + 50,
        ),
        shapeType: ShapeType.values[random.nextInt(ShapeType.values.length)],
      );
      add(shape);
    }
  }

  void incrementScore() {
    score += 10;
    scoreText.text = 'Score: $score';

    // Spawn a new shape when one is tapped
    final random = Random();
    final shape = GameShape(
      position: Vector2(
        random.nextDouble() * (size.x - 100) + 50,
        random.nextDouble() * (size.y - 100) + 50,
      ),
      shapeType: ShapeType.values[random.nextInt(ShapeType.values.length)],
    );
    add(shape);
  }
}

class BackgroundComponent extends Component with HasGameReference<HadiGame> {
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }
}

enum ShapeType { circle, square, triangle }

class GameShape extends PositionComponent
    with TapCallbacks, HasGameReference<HadiGame> {
  final ShapeType shapeType;
  late Color color;
  double rotationSpeed = 0;
  double pulseTime = 0;

  GameShape({required super.position, required this.shapeType})
    : super(size: Vector2.all(60), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final random = Random();

    // Random vibrant color
    final colors = [
      const Color(0xFFe94560),
      const Color(0xFF00d4aa),
      const Color(0xFFffa500),
      const Color(0xFF00bfff),
      const Color(0xFFff6b6b),
      const Color(0xFF9b59b6),
    ];
    color = colors[random.nextInt(colors.length)];

    // Random rotation speed
    rotationSpeed = (random.nextDouble() - 0.5) * 2;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Rotate the shape
    angle += rotationSpeed * dt;

    // Pulse effect
    pulseTime += dt * 2;
    final scale = 1.0 + sin(pulseTime) * 0.1;
    this.scale = Vector2.all(scale);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    switch (shapeType) {
      case ShapeType.circle:
        // Shadow
        canvas.drawCircle(
          Offset(size.x / 2 + 4, size.y / 2 + 4),
          size.x / 2,
          shadowPaint,
        );
        // Shape
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
        break;

      case ShapeType.square:
        final rect = Rect.fromLTWH(0, 0, size.x, size.y);
        // Shadow
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.translate(4, 4),
            const Radius.circular(8),
          ),
          shadowPaint,
        );
        // Shape
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          paint,
        );
        break;

      case ShapeType.triangle:
        final path = Path()
          ..moveTo(size.x / 2, 0)
          ..lineTo(size.x, size.y)
          ..lineTo(0, size.y)
          ..close();

        // Shadow
        canvas.save();
        canvas.translate(4, 4);
        canvas.drawPath(path, shadowPaint);
        canvas.restore();

        // Shape
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Simple circular hit detection
    final center = size / 2;
    return (point - center).length <= size.x / 2;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Increment score and remove this shape
    game.incrementScore();
    removeFromParent();
  }
}
