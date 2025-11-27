import 'dart:math';
import 'package:flutter/material.dart';

class CircularHeatmapPainter extends CustomPainter {
  final double centerPercent;
  final double northPercent;
  final double northEastPercent;
  final double eastPercent;
  final double southEastPercent;
  final double southPercent;
  final double southWestPercent;
  final double westPercent;
  final double northWestPercent;
  final Color Function(double) getHeatColor;

  CircularHeatmapPainter({
    required this.centerPercent,
    required this.northPercent,
    required this.northEastPercent,
    required this.eastPercent,
    required this.southEastPercent,
    required this.southPercent,
    required this.southWestPercent,
    required this.westPercent,
    required this.northWestPercent,
    required this.getHeatColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final centerRadius = radius * 0.3;

    final borderPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    final linePaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1.5;

    for (int i = 0; i < 8; i++) {
      double angle = (i * 45) * pi / 180;
      canvas.drawLine(
        Offset(center.dx + centerRadius * cos(angle), center.dy + centerRadius * sin(angle)),
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        linePaint,
      );
    }

    _drawSector(canvas, center, centerRadius, radius, 0, pi/4, getHeatColor(eastPercent));
    _drawSector(canvas, center, centerRadius, radius, pi/4, pi/2, getHeatColor(southEastPercent));
    _drawSector(canvas, center, centerRadius, radius, pi/2, 3*pi/4, getHeatColor(southPercent));
    _drawSector(canvas, center, centerRadius, radius, 3*pi/4, pi, getHeatColor(southWestPercent));
    _drawSector(canvas, center, centerRadius, radius, pi, 5*pi/4, getHeatColor(westPercent));
    _drawSector(canvas, center, centerRadius, radius, 5*pi/4, 3*pi/2, getHeatColor(northWestPercent));
    _drawSector(canvas, center, centerRadius, radius, 3*pi/2, 7*pi/4, getHeatColor(northPercent));
    _drawSector(canvas, center, centerRadius, radius, 7*pi/4, 2*pi, getHeatColor(northEastPercent));

    final centerPaint = Paint()
      ..color = getHeatColor(centerPercent)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerRadius, centerPaint);

    final centerBorderPaint = Paint()
      ..color = Colors.green[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, centerRadius, centerBorderPaint);

    _drawSectorLabels(canvas, center, centerRadius, radius);
  }

  void _drawSector(Canvas canvas, Offset center, double innerRadius, double outerRadius,
      double startAngle, double endAngle, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(center.dx + innerRadius * cos(startAngle),
        center.dy + innerRadius * sin(startAngle));
    path.lineTo(center.dx + outerRadius * cos(startAngle),
        center.dy + outerRadius * sin(startAngle));
    path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle, endAngle - startAngle, false
    );
    path.lineTo(center.dx + innerRadius * cos(endAngle),
        center.dy + innerRadius * sin(endAngle));
    path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        endAngle, startAngle - endAngle, false
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawSectorLabels(Canvas canvas, Offset center, double centerRadius, double outerRadius) {
    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 9,
      fontWeight: FontWeight.bold,
    );

    _drawText(canvas, '${centerPercent.toStringAsFixed(1)}%', center, textStyle.copyWith(fontSize: 11));

    final labelRadius = centerRadius + (outerRadius - centerRadius) / 2;

    List<Map<String, dynamic>> sectors = [
      {'angle': pi/8, 'percent': eastPercent},
      {'angle': 3*pi/8, 'percent': southEastPercent},
      {'angle': 5*pi/8, 'percent': southPercent},
      {'angle': 7*pi/8, 'percent': southWestPercent},
      {'angle': 9*pi/8, 'percent': westPercent},
      {'angle': 11*pi/8, 'percent': northWestPercent},
      {'angle': 13*pi/8, 'percent': northPercent},
      {'angle': 15*pi/8, 'percent': northEastPercent},
    ];

    for (var sector in sectors) {
      double angle = sector['angle'];
      double percent = sector['percent'];
      Offset position = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );
      _drawText(canvas, '${percent.toStringAsFixed(1)}%', position, textStyle);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    ));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}