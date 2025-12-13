import 'dart:math';
import 'package:flutter/material.dart';

class SnowWidget extends StatefulWidget {
  const SnowWidget({super.key});

  @override
  State<SnowWidget> createState() => _SnowWidgetState();
}

class _SnowWidgetState extends State<SnowWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Snowflake> _snowflakes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    for (int i = 0; i < 50; i++) {
      _snowflakes.add(Snowflake(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: SnowPainter(_snowflakes, _random),
          size: Size.infinite,
        );
      },
    );
  }
}

class Snowflake {
  static const List<String> symbols = ['❄', '❅', '❆', '•', '·', '*'];
  
  double x = 0;
  double y = 0;
  double speed = 0;
  double size = 0;
  double opacity = 0;
  double rotation = 0;
  double rotationSpeed = 0;
  String symbol = '';

  Snowflake(Random random) {
    reset(random, true);
  }

  void reset(Random random, bool initial) {
    x = random.nextDouble();
    y = initial ? random.nextDouble() : -0.1;
    speed = random.nextDouble() * 0.002 + 0.001;
    size = random.nextDouble() * 20 + 10;
    opacity = random.nextDouble() * 0.5 + 0.3;
    rotation = random.nextDouble() * 2 * pi;
    rotationSpeed = (random.nextDouble() - 0.5) * 0.05;
    symbol = symbols[random.nextInt(symbols.length)];
  }
}

class SnowPainter extends CustomPainter {
  final List<Snowflake> flakes;
  final Random random;

  SnowPainter(this.flakes, this.random);

  @override
  void paint(Canvas canvas, Size size) {
    for (var flake in flakes) {
      flake.y += flake.speed;
      flake.rotation += flake.rotationSpeed;

      if (flake.y > 1.0) {
        flake.reset(random, false);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: flake.symbol,
          style: TextStyle(
            color: Colors.white.withOpacity(flake.opacity),
            fontSize: flake.size,
            fontFamily: 'Arial',
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final double actualX = flake.x * size.width;
      final double actualY = flake.y * size.height;

      canvas.save();
      canvas.translate(actualX, actualY);
      canvas.rotate(flake.rotation);
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
      
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}