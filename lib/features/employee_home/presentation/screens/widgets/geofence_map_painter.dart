import 'package:flutter/material.dart';

/// Offline, stylised district map used as the geofence card backdrop.
///
/// Purely decorative: it does not plot real coordinates.
class GeofenceMapPainter extends CustomPainter {
  const GeofenceMapPainter();

  static const Color _land = Color(0xFFE2E8F0);
  static const Color _water = Color(0xFFBFDBFE);
  static const Color _minorRoad = Color(0xFFCBD5E1);
  static const Color _fenceFill = Color(0x333B82F6);
  static const Color _fenceRing = Color(0xFF2563EB);
  static const Color _pulse = Color(0x5516A34A);
  static const Color _pinGlow = Color(0x4016A34A);
  static const Color _pin = Color(0xFF16A34A);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _land,
    );

    final riverPath = Path()
      ..moveTo(0, size.height * 0.25)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.15,
        size.width * 0.65,
        size.height * 0.85,
        size.width,
        size.height * 0.7,
      );
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = _water
        ..strokeWidth = 24
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final minorRoadPaint = Paint()
      ..color = _minorRoad
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.55),
      Offset(size.width, size.height * 0.35),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.55, size.height),
      roadPaint,
    );
    for (double y = 20; y < size.height; y += 35) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoadPaint);
    }
    for (double x = 40; x < size.width; x += 55) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }

    final center = Offset(size.width * 0.5, size.height * 0.45);
    final radius = size.height * 0.42;
    canvas.drawCircle(center, radius, Paint()..color = _fenceFill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _fenceRing
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center,
      radius * 0.5,
      Paint()
        ..color = _pulse
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(center, 14, Paint()..color = _pinGlow);
    canvas.drawCircle(center, 7, Paint()..color = _pin);
    canvas.drawCircle(center, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
