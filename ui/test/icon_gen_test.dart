// App-icon generator. Renders the icon natively via dart:ui (no external rasterizer) and writes the
// 1024×1024 PNG masters that flutter_launcher_icons consumes. Run with:
//   flutter test test/icon_gen_test.dart
//
// Design (app-icon spec): a dark warm background, a thin inset gold frame, a silver Classic X in the
// upper-left and a gold Futuristic medallion in the lower-right.
//
// Outputs:
//   assets/icon/icon_ios.png  — opaque, background filled to all corners (iOS rounds it itself).
//   assets/icon/icon_fg.png   — transparent; X + medallion only, in the central ~66% (Android fg).
//   store/app_icon_store_1024.png — full squircle + frame (store consoles; not bundled).

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _bg = [Color(0xFF241813), Color(0xFF120C08), Color(0xFF070504)];
const _ringStops = [0.0, 0.12, 0.28, 0.42, 0.60, 0.78, 1.0];
const _ring = [
  Color(0xFF6B4F12),
  Color(0xFFF6E6A8),
  Color(0xFFC79A3A),
  Color(0xFFFFF3C8),
  Color(0xFF8A6A1D),
  Color(0xFFF6E6A8),
  Color(0xFF6B4F12),
];
const _disc = [Color(0xFFE9C659), Color(0xFFD4AF37), Color(0xFF7A5D16)];
const _silver = [Color(0xFFFFFFFF), Color(0xFFC8CDD8), Color(0xFF878D9C)];
const _frameGold = [Color(0xFF8A6A1D), Color(0xFFF6E6A8), Color(0xFFC79A3A), Color(0xFFF6E6A8), Color(0xFF8A6A1D)];

void _drawBackground(Canvas canvas, double s) {
  final rect = Rect.fromLTWH(0, 0, s, s);
  final paint = Paint()
    ..shader = const RadialGradient(
      center: Alignment(-0.15, -0.35),
      radius: 1.25,
      colors: _bg,
      stops: [0.0, 0.55, 1.0],
    ).createShader(rect);
  canvas.drawRect(rect, paint);
}

void _drawFrame(Canvas canvas, double s, double margin) {
  final rect = Rect.fromLTWH(margin, margin, s - 2 * margin, s - 2 * margin);
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.16));
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.012
    ..shader = const LinearGradient(colors: _frameGold).createShader(rect);
  canvas.drawRRect(rrect, paint);
}

void _drawX(Canvas canvas, Offset c, double arm, double strokeW) {
  final rect = Rect.fromCircle(center: c, radius: arm);
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeW
    ..strokeCap = StrokeCap.round
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _silver,
      stops: [0.0, 0.45, 1.0],
    ).createShader(rect);
  // soft glow under the strokes
  final glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeW
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFEEF1F6).withValues(alpha: 0.35)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeW * 0.5);
  for (final p in [glow, paint]) {
    canvas.drawLine(c + Offset(-arm, -arm), c + Offset(arm, arm), p);
    canvas.drawLine(c + Offset(arm, -arm), c + Offset(-arm, arm), p);
  }
}

void _drawMedallion(Canvas canvas, Offset c, double d) {
  final r = d / 2;
  // drop shadow
  canvas.drawCircle(
    c + Offset(0, d * 0.04),
    r,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, d * 0.06),
  );
  // metallic ring
  final ringRect = Rect.fromCircle(center: c, radius: r);
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = const SweepGradient(
        startAngle: 220 * math.pi / 180,
        endAngle: 220 * math.pi / 180 + 2 * math.pi,
        colors: _ring,
        stops: _ringStops,
      ).createShader(ringRect),
  );
  // inner disc (ring thickness ≈ 7% of the diameter)
  final discR = r * 0.86;
  final discRect = Rect.fromCircle(center: c, radius: discR);
  canvas.drawCircle(
    c,
    discR,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.45),
        radius: 0.95,
        colors: _disc,
        stops: [0.0, 0.46, 1.0],
      ).createShader(discRect),
  );
  // glossy highlight
  canvas.drawCircle(
    c + Offset(-discR * 0.3, -discR * 0.38),
    discR * 0.5,
    Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: c + Offset(-discR * 0.3, -discR * 0.38), radius: discR * 0.5)),
  );
}

/// Paint the full icon. [safe] = fraction of the canvas the X+medallion occupy.
void _paintIcon(
  Canvas canvas,
  double s, {
  required bool background,
  required bool frame,
  required bool clipSquircle,
  required double safe,
}) {
  if (clipSquircle) {
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(s * 0.2237));
    canvas.clipRRect(rrect);
  }
  if (background) _drawBackground(canvas, s);
  if (frame) _drawFrame(canvas, s, s * 0.06);

  final side = s * safe;
  final o = Offset((s - side) / 2, (s - side) / 2);
  _drawX(canvas, o + Offset(side * 0.30, side * 0.30), side * 0.17, side * 0.055);
  _drawMedallion(canvas, o + Offset(side * 0.68, side * 0.68), side * 0.50);
}

Future<void> _write(String path, void Function(Canvas, double) paint) async {
  const s = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, s, s));
  paint(canvas, s);
  final img = await recorder.endRecording().toImage(s.toInt(), s.toInt());
  final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  final file = File(path);
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);
}

void main() {
  test('generate app icon masters', () async {
    // iOS / legacy Android master: opaque, filled to all corners, inset frame, content ~80%.
    await _write('assets/icon/icon_ios.png',
        (c, s) => _paintIcon(c, s, background: true, frame: true, clipSquircle: false, safe: 0.80));

    // Android adaptive foreground: transparent, content within the ~66% safe zone, no frame/bg.
    await _write('assets/icon/icon_fg.png',
        (c, s) => _paintIcon(c, s, background: false, frame: false, clipSquircle: false, safe: 0.66));

    // Store-listing icon: full squircle + frame.
    await _write('store/app_icon_store_1024.png',
        (c, s) => _paintIcon(c, s, background: true, frame: true, clipSquircle: true, safe: 0.78));

    expect(File('assets/icon/icon_ios.png').existsSync(), isTrue);
    expect(File('assets/icon/icon_fg.png').existsSync(), isTrue);
    expect(File('store/app_icon_store_1024.png').existsSync(), isTrue);
  });
}
