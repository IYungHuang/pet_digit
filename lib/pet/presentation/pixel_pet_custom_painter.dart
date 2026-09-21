// 8-Bit Custom Pixel Pet Painter Module for Flutter pet_digit
// Placed in lib/pet/presentation/pixel_pet_custom_painter.dart

import 'package:flutter/material.dart';

class CustomPixelPetData {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color eyeColor;
  final Color noseColor;

  const CustomPixelPetData({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.eyeColor,
    required this.noseColor,
  });

  static const defaultCorgi = CustomPixelPetData(
    name: '自訂柯基',
    primaryColor: Color(0xffe08339),
    secondaryColor: Color(0xffffffff),
    accentColor: Color(0xfffca5a5),
    eyeColor: Color(0xff191b2b),
    noseColor: Color(0xff11121d),
  );
}

class PixelPetPainter8Bit extends CustomPainter {
  final double yaw;         // -1.0 to 1.0 (Head parallax)
  final double pitch;       // -1.0 to 1.0 (Tilt)
  final double buttShift;   // Butt wag (-2 to 2)
  final int breathOffset;   // 0 or 1 pixel
  final bool isBlinking;
  final CustomPixelPetData data;

  PixelPetPainter8Bit({
    this.yaw = 0.0,
    this.pitch = 0.0,
    this.buttShift = 0.0,
    this.breathOffset = 0,
    this.isBlinking = false,
    this.data = CustomPixelPetData.defaultCorgi,
  });

  static const Color outline = Color(0xff191b2b);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64.0; // Pixel grid scale
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    final primaryPaint = Paint()..color = data.primaryColor;
    final secondaryPaint = Paint()..color = data.secondaryColor;
    final outlinePaint = Paint()..color = outline;
    final eyePaint = Paint()..color = data.eyeColor;
    final nosePaint = Paint()..color = data.noseColor;
    final pinkPaint = Paint()..color = data.accentColor;

    // 1. Pixel Body (8-Bit chunky rects)
    final bodyX = cx - 12 * s - (yaw * 1).round() * s;
    final bodyY = cy + 4 * s + breathOffset * s;
    canvas.drawRect(Rect.fromLTWH(bodyX - s, bodyY - s, 26 * s, 18 * s), outlinePaint);
    canvas.drawRect(Rect.fromLTWH(bodyX, bodyY, 24 * s, 16 * s), primaryPaint);
    canvas.drawRect(Rect.fromLTWH(bodyX + 8 * s, bodyY + 4 * s, 14 * s, 12 * s), secondaryPaint);

    // 2. Butt & Bobtail
    final buttX = cx - 18 * s + buttShift.round() * s;
    final buttY = cy + 6 * s;
    canvas.drawRect(Rect.fromLTWH(buttX - s, buttY - 2 * s, 10 * s, 10 * s), outlinePaint);
    canvas.drawRect(Rect.fromLTWH(buttX, buttY - s, 8 * s, 8 * s), primaryPaint);
    canvas.drawRect(Rect.fromLTWH(buttX + s, buttY + s, 6 * s, 5 * s), secondaryPaint);

    // 3. Paws (Front feet)
    canvas.drawRect(Rect.fromLTWH(cx - 3 * s, cy + 18 * s, 6 * s, 6 * s), outlinePaint);
    canvas.drawRect(Rect.fromLTWH(cx - 2 * s, cy + 19 * s, 4 * s, 4 * s), secondaryPaint);
    canvas.drawRect(Rect.fromLTWH(cx + 7 * s, cy + 18 * s, 6 * s, 6 * s), outlinePaint);
    canvas.drawRect(Rect.fromLTWH(cx + 8 * s, cy + 19 * s, 4 * s, 4 * s), secondaryPaint);

    // 4. Head with 2.5D Pixel Parallax
    final headX = cx - 2 * s + (yaw * 4).round() * s;
    final headY = cy - 22 * s + (pitch * 3).round() * s + breathOffset * s;

    // Head Outline & Fur
    canvas.drawRect(Rect.fromLTWH(headX - 15 * s, headY - s, 30 * s, 26 * s), outlinePaint);
    canvas.drawRect(Rect.fromLTWH(headX - 14 * s, headY, 28 * s, 24 * s), primaryPaint);

    // White Cheeks & Blaze
    canvas.drawRect(Rect.fromLTWH(headX - 10 * s, headY + 10 * s, 20 * s, 12 * s), secondaryPaint);
    canvas.drawRect(Rect.fromLTWH(headX - 2 * s, headY, 4 * s, 14 * s), secondaryPaint);

    // Ears
    canvas.drawRect(Rect.fromLTWH(headX - 14 * s, headY - 14 * s, 10 * s, 14 * s), outlinePaint);
    canvas.drawRect(Rect.fromLTWH(headX - 13 * s, headY - 13 * s, 8 * s, 12 * s), primaryPaint);
    canvas.drawRect(Rect.fromLTWH(headX - 11 * s, headY - 11 * s, 4 * s, 8 * s), pinkPaint);

    canvas.drawRect(Rect.fromLTWH(headX + 5 * s, headY - 14 * s, 10 * s, 14 * s), outlinePaint);
    canvas.drawRect(Rect.fromLTWH(headX + 6 * s, headY - 13 * s, 8 * s, 12 * s), primaryPaint);
    canvas.drawRect(Rect.fromLTWH(headX + 8 * s, headY - 11 * s, 4 * s, 8 * s), pinkPaint);

    // Eyes with 2.5D shift
    final eyeY = headY + 7 * s;
    final eyeX = headX + (yaw * 2).round() * s;
    if (!isBlinking) {
      canvas.drawRect(Rect.fromLTWH(eyeX - 8 * s, eyeY - s, 5 * s, 6 * s), outlinePaint);
      canvas.drawRect(Rect.fromLTWH(eyeX - 7 * s, eyeY, 3 * s, 4 * s), eyePaint);
      canvas.drawRect(Rect.fromLTWH(eyeX - 7 * s, eyeY, s, s), Paint()..color = Colors.white);

      canvas.drawRect(Rect.fromLTWH(eyeX + 4 * s, eyeY - s, 5 * s, 6 * s), outlinePaint);
      canvas.drawRect(Rect.fromLTWH(eyeX + 5 * s, eyeY, 3 * s, 4 * s), eyePaint);
      canvas.drawRect(Rect.fromLTWH(eyeX + 5 * s, eyeY, s, s), Paint()..color = Colors.white);
    } else {
      canvas.drawRect(Rect.fromLTWH(eyeX - 8 * s, eyeY + 2 * s, 4 * s, s), outlinePaint);
      canvas.drawRect(Rect.fromLTWH(eyeX + 4 * s, eyeY + 2 * s, 4 * s, s), outlinePaint);
    }

    // Nose & Mouth
    canvas.drawRect(Rect.fromLTWH(eyeX - s, headY + 13 * s, 3 * s, 2 * s), nosePaint);
    canvas.drawRect(Rect.fromLTWH(eyeX - s, headY + 16 * s, 3 * s, 2 * s), pinkPaint);
  }

  @override
  bool shouldRepaint(covariant PixelPetPainter8Bit oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.buttShift != buttShift ||
        oldDelegate.breathOffset != breathOffset ||
        oldDelegate.isBlinking != isBlinking ||
        oldDelegate.data != data;
  }
}
