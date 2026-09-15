import 'dart:math' as math;

import 'package:flutter/material.dart';

class AmbientBackgroundPainter extends CustomPainter {
  const AmbientBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x0BFFFFFF)
      ..strokeWidth = 1;
    const spacing = 48.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFC8FF3D).withValues(alpha: 0.09),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.73, size.height * 0.08),
              radius: math.max(size.width, size.height) * 0.55,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaveformPainter extends CustomPainter {
  const WaveformPainter({
    required this.progress,
    required this.gains,
    required this.samples,
    required this.active,
  });

  final double progress;
  final List<double> gains;
  final List<double> samples;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    const gap = 4.0;
    final count = (size.width / gap).floor();
    final average =
        gains.fold<double>(0, (sum, gain) => sum + gain.abs()) /
        math.max(1, gains.length);
    for (var i = 0; i < count; i++) {
      final x = i * gap;
      final normalizedX = i / math.max(1, count - 1);
      final hasLiveSamples = samples.isNotEmpty;
      final wave = hasLiveSamples
          ? samples[(normalizedX * (samples.length - 1)).round()].abs()
          : (math.sin(i * 0.47) * 0.45 +
                    math.sin(i * 0.19 + 1.3) * 0.28 +
                    math.sin(i * 0.08 + 0.6) * 0.17)
                .abs();
      final envelope = 0.4 + 0.6 * math.sin(normalizedX * math.pi).abs();
      final height = hasLiveSamples
          ? math.max(4, wave * size.height * 0.92)
          : (6 + wave * 34 + average * 0.7) * envelope;
      final played = normalizedX <= progress;
      final paint = Paint()
        ..color = played
            ? const Color(0xFFC8FF3D)
            : active
            ? const Color(0xFF4C5865)
            : const Color(0xFF2B333F)
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, center - height / 2),
        Offset(x, center + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.active != active ||
      oldDelegate.samples != samples ||
      oldDelegate.gains != gains;
}

class PresetCurvePainter extends CustomPainter {
  const PresetCurvePainter({required this.gains, required this.color});

  final List<double> gains;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      baseline,
    );

    final points = <Offset>[];
    for (var i = 0; i < gains.length; i++) {
      points.add(
        Offset(
          i * size.width / math.max(1, gains.length - 1),
          size.height / 2 - (gains[i] / 12) * size.height,
        ),
      );
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final midpoint = (current.dx + next.dx) / 2;
      path.cubicTo(midpoint, current.dy, midpoint, next.dy, next.dx, next.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant PresetCurvePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.gains != gains;
}

class SpectrumLogoPainter extends CustomPainter {
  const SpectrumLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const bars = [0.42, 0.72, 1.0, 0.62, 0.84, 0.48];
    final step = size.width / bars.length;
    for (var i = 0; i < bars.length; i++) {
      final height = size.height * bars[i];
      canvas.drawLine(
        Offset(step * i + step / 2, (size.height - height) / 2),
        Offset(step * i + step / 2, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
