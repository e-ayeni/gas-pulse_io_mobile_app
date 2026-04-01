import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated liquid-filled gas cylinder visualization.
/// Shows a realistic cylinder shape with animated wave surface.
class LiquidCylinder extends StatefulWidget {
  final double? fillPercent; // 0-100
  final double width;
  final double height;
  final String? label;
  final String? subtitle;
  final bool animate;

  const LiquidCylinder({
    super.key,
    this.fillPercent,
    this.width = 140,
    this.height = 220,
    this.label,
    this.subtitle,
    this.animate = true,
  });

  @override
  State<LiquidCylinder> createState() => _LiquidCylinderState();
}

class _LiquidCylinderState extends State<LiquidCylinder> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  double _currentFill = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.animate) {
      _waveController.repeat();
    }

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final target = (widget.fillPercent ?? 0).clamp(0, 100).toDouble();
    _fillAnimation = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
    );
    _currentFill = target;
    _fillController.forward();
  }

  @override
  void didUpdateWidget(LiquidCylinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillPercent != widget.fillPercent) {
      final newTarget = (widget.fillPercent ?? 0).clamp(0, 100).toDouble();
      _fillAnimation = Tween<double>(begin: _currentFill, end: newTarget).animate(
        CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
      );
      _currentFill = newTarget;
      _fillController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_waveController, _fillAnimation]),
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.width, widget.height),
              painter: _CylinderPainter(
                fillPercent: _fillAnimation.value,
                wavePhase: _waveController.value * 2 * pi,
                liquidColor: AppColors.liquidColor(widget.fillPercent),
                liquidColorLight: AppColors.liquidColorLight(widget.fillPercent),
              ),
            );
          },
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
        if (widget.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}

class _CylinderPainter extends CustomPainter {
  final double fillPercent;
  final double wavePhase;
  final Color liquidColor;
  final Color liquidColorLight;

  _CylinderPainter({
    required this.fillPercent,
    required this.wavePhase,
    required this.liquidColor,
    required this.liquidColorLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cylinder dimensions
    final capHeight = h * 0.08; // top/bottom ellipse height
    final bodyTop = capHeight;
    final bodyBottom = h - capHeight;
    final bodyHeight = bodyBottom - bodyTop;
    final centerX = w / 2;
    final radiusX = w / 2 - 2;
    final radiusY = capHeight;

    // ── Cylinder body (stroke outline) ──
    final bodyPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Left wall
    canvas.drawLine(Offset(centerX - radiusX, bodyTop), Offset(centerX - radiusX, bodyBottom), bodyPaint);
    // Right wall
    canvas.drawLine(Offset(centerX + radiusX, bodyTop), Offset(centerX + radiusX, bodyBottom), bodyPaint);

    // ── Clipping region for liquid (inside cylinder) ──
    final clipPath = Path();
    // Top ellipse arc (bottom half)
    clipPath.addArc(
      Rect.fromCenter(center: Offset(centerX, bodyTop), width: radiusX * 2, height: radiusY * 2),
      0, pi,
    );
    // Down left side
    clipPath.lineTo(centerX - radiusX, bodyBottom);
    // Bottom ellipse arc (bottom half)
    clipPath.addArc(
      Rect.fromCenter(center: Offset(centerX, bodyBottom), width: radiusX * 2, height: radiusY * 2),
      pi, -pi,
    );
    // Up right side
    clipPath.lineTo(centerX + radiusX, bodyTop);
    clipPath.close();

    canvas.save();
    canvas.clipPath(clipPath);

    // ── Liquid fill with waves ──
    final fillFraction = fillPercent / 100.0;
    final liquidTop = bodyBottom - (bodyHeight * fillFraction);

    if (fillPercent > 0) {
      // Back wave (lighter color)
      _drawWave(canvas, size, liquidTop, wavePhase + pi, liquidColorLight.withAlpha(180),
          radiusX, centerX, bodyBottom, radiusY, amplitude: 4);

      // Front wave (main color)
      _drawWave(canvas, size, liquidTop, wavePhase, liquidColor,
          radiusX, centerX, bodyBottom, radiusY, amplitude: 3);
    }

    canvas.restore();

    // ── Top cap ellipse ──
    final topCapPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, bodyTop), width: radiusX * 2, height: radiusY * 2),
      topCapPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, bodyTop), width: radiusX * 2, height: radiusY * 2),
      bodyPaint,
    );

    // ── Bottom cap ellipse ──
    final bottomCapPaint = Paint()
      ..color = fillPercent > 0 ? liquidColor : Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, bodyBottom), width: radiusX * 2, height: radiusY * 2),
      bottomCapPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, bodyBottom), width: radiusX * 2, height: radiusY * 2),
      bodyPaint,
    );

    // ── Valve / handle on top ──
    final valvePaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;
    final valveW = w * 0.15;
    final valveH = capHeight * 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, bodyTop - valveH / 2 - 1), width: valveW, height: valveH),
        const Radius.circular(3),
      ),
      valvePaint,
    );

    // Handle arc on top of valve
    final handlePaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, bodyTop - valveH - 4),
        width: valveW * 1.2,
        height: valveH * 0.8,
      ),
      pi, pi, false, handlePaint,
    );

    // ── Metallic sheen highlight ──
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withAlpha(0),
          Colors.white.withAlpha(40),
          Colors.white.withAlpha(0),
        ],
        stops: const [0.0, 0.35, 0.7],
      ).createShader(Rect.fromLTWH(0, bodyTop, w, bodyHeight));

    canvas.save();
    canvas.clipPath(clipPath);
    canvas.drawRect(Rect.fromLTWH(0, bodyTop, w, bodyHeight), sheenPaint);
    canvas.restore();
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double liquidTop,
    double phase,
    Color color,
    double radiusX,
    double centerX,
    double bodyBottom,
    double radiusY, {
    double amplitude = 3,
  }) {
    final wavePath = Path();
    final waveWidth = radiusX * 2;

    wavePath.moveTo(centerX - radiusX, liquidTop);

    // Draw sine wave across the top of the liquid
    for (double x = 0; x <= waveWidth; x += 1) {
      final normalX = x / waveWidth;
      // Dampen wave at edges so it meets cylinder wall cleanly
      final edgeDampen = sin(normalX * pi);
      final y = liquidTop + sin(normalX * 4 * pi + phase) * amplitude * edgeDampen;
      wavePath.lineTo(centerX - radiusX + x, y);
    }

    // Close path down to bottom
    wavePath.lineTo(centerX + radiusX, bodyBottom + radiusY);
    wavePath.lineTo(centerX - radiusX, bodyBottom + radiusY);
    wavePath.close();

    canvas.drawPath(wavePath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CylinderPainter oldDelegate) =>
      fillPercent != oldDelegate.fillPercent || wavePhase != oldDelegate.wavePhase;
}
