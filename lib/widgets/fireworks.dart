import 'dart:math';

import 'package:flutter/material.dart';

/// A celebratory fireworks animation drawn on top of the screen, used when the
/// player sets a new record in a game category. It loops a handful of colourful
/// bursts and is meant to be layered in a [Stack] with [IgnorePointer] so it
/// never blocks taps.
class Fireworks extends StatefulWidget {
  const Fireworks({super.key, this.burstCount = 6});

  /// How many simultaneous bursts to animate.
  final int burstCount;

  @override
  State<Fireworks> createState() => _FireworksState();
}

class _FireworksState extends State<Fireworks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Burst> _bursts;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _bursts = List.generate(widget.burstCount, (_) => _randomBurst());
    _controller.addListener(_maybeRespawn);
  }

  _Burst _randomBurst() {
    const palette = [
      Color(0xFFFF8A3D),
      Color(0xFF5B6CF0),
      Color(0xFF2BB673),
      Color(0xFFB23CFD),
      Color(0xFF18B0C9),
      Color(0xFFE5484D),
      Color(0xFFFFD23F),
    ];
    return _Burst(
      center: Offset(0.1 + _random.nextDouble() * 0.8,
          0.12 + _random.nextDouble() * 0.6),
      color: palette[_random.nextInt(palette.length)],
      startFraction: _random.nextDouble(),
      sparkCount: 10 + _random.nextInt(8),
      maxRadius: 0.12 + _random.nextDouble() * 0.12,
      seed: _random.nextInt(1 << 20),
    );
  }

  void _maybeRespawn() {
    final t = _controller.value;
    for (var i = 0; i < _bursts.length; i++) {
      if (_bursts[i].progress(t) >= 1.0 &&
          _bursts[i].lastProgress < 1.0) {
        _bursts[i] = _randomBurst();
      }
      _bursts[i].lastProgress = _bursts[i].progress(t);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _FireworksPainter(_bursts, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Burst {
  _Burst({
    required this.center,
    required this.color,
    required this.startFraction,
    required this.sparkCount,
    required this.maxRadius,
    required this.seed,
  });

  /// Relative position (0..1) of the burst centre.
  final Offset center;
  final Color color;
  final double startFraction;
  final int sparkCount;
  final double maxRadius;
  final int seed;

  double lastProgress = 0;

  /// 0..1 progress of this burst given the controller value [t].
  double progress(double t) {
    final p = (t - startFraction) % 1.0;
    return p < 0 ? p + 1.0 : p;
  }
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.bursts, this.t);

  final List<_Burst> bursts;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final burst in bursts) {
      final progress = burst.progress(t);
      final center =
          Offset(burst.center.dx * size.width, burst.center.dy * size.height);
      final radius = burst.maxRadius * size.shortestSide * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = burst.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      final random = Random(burst.seed);
      for (var i = 0; i < burst.sparkCount; i++) {
        final angle = (2 * pi / burst.sparkCount) * i +
            random.nextDouble() * 0.3;
        final distance = radius * (0.7 + random.nextDouble() * 0.3);
        final position = center +
            Offset(cos(angle) * distance, sin(angle) * distance);
        final sparkSize = (3.5 * opacity) + 1.0;
        canvas.drawCircle(position, sparkSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) => true;
}
