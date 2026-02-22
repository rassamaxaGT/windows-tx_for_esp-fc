import 'dart:math';
import 'package:flutter/material.dart';

class CurvePainter extends CustomPainter {
  final double expo, deadzone, scale, currentValue;
  final Color color;

  static final Paint _pGrid = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 1;
  static final Paint _pAxis = Paint()..color = Colors.white.withValues(alpha: 0.2)..strokeWidth = 1;
  static final Paint _pDZ = Paint()..color = Colors.red.withValues(alpha: 0.15);
  static final Paint _pDotInner = Paint()..color = Colors.white;

  CurvePainter({
    required this.expo,
    required this.deadzone,
    required this.scale,
    required this.currentValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midH = h / 2;
    final midW = w / 2;

    _drawGrid(canvas, w, h);

    canvas.drawLine(Offset(0, midH), Offset(w, midH), _pAxis);
    canvas.drawLine(Offset(midW, 0), Offset(midW, h), _pAxis);

    if (scale < 1.0) {
       final pLimit = Paint()..color = Colors.white.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 1;
       double limitYTop = (1 - (scale + 1) / 2) * h;
       double limitYBot = (1 - (-scale + 1) / 2) * h;
       canvas.drawLine(Offset(0, limitYTop), Offset(w, limitYTop), pLimit);
       canvas.drawLine(Offset(0, limitYBot), Offset(w, limitYBot), pLimit);
    }

    if (deadzone > 0) {
      double dzW = deadzone * midW;
      canvas.drawRect(Rect.fromLTRB(midW - dzW, 0, midW + dzW, h), _pDZ);
    }

    final pCurve = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
      
    final path = Path();
    bool first = true;
    
    for (double x = -1.0; x <= 1.0; x += 0.02) {
      double absX = x.abs();
      double y = 0;
      if (absX >= deadzone) {
        double val = (absX - deadzone) / (1.0 - deadzone);
        y = x.sign * pow(val, expo) * scale;
      }
      
      double sx = (x + 1) / 2 * w;
      double sy = (1 - (y + 1) / 2) * h;

      if (first) {
        path.moveTo(sx, sy);
        first = false;
      } else {
        path.lineTo(sx, sy);
      }
    }
    canvas.drawPath(path, pCurve);

    double absV = currentValue.abs();
    double outY = 0;
    if (absV >= deadzone) {
       double val = (absV - deadzone) / (1.0 - deadzone);
       outY = currentValue.sign * pow(val, expo) * scale;
    }
    
    final dotCenter = Offset((currentValue + 1) / 2 * w, (1 - (outY + 1) / 2) * h);
    
    // ИСПРАВЛЕНО: Оборачиваем цвет в Paint
    final glowPaint = Paint()
      ..color = (color == Colors.white ? Colors.blue : color.withValues(alpha: 0.5));
    
    canvas.drawCircle(dotCenter, 5, glowPaint); 
    canvas.drawCircle(dotCenter, 3, _pDotInner);
  }

  void _drawGrid(Canvas canvas, double w, double h) {
    for (double i = 0.2; i < 1.0; i+=0.2) {
      canvas.drawLine(Offset(w*i, 0), Offset(w*i, h), _pGrid);
    }
    for (double i = 0.2; i < 1.0; i+=0.2) {
      canvas.drawLine(Offset(0, h*i), Offset(w, h*i), _pGrid);
    }
  }

  @override
  bool shouldRepaint(covariant CurvePainter old) => true;
}