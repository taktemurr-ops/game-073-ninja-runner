import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:studio_core/app/arcade_stage.dart';
import 'package:studio_core/app/play_kit.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/core/arcade.dart';
import 'runner_engine.dart';

Paint _p(int c) => Paint()..color = Color(c);

void paintRun(Canvas c, ArcadeSim sim, ArcadePalette p, double t) {
  final s = sim as RunSim;
  final themes = [
    [0xFF14213D, 0xFFFCA311, 0xFF2D6A4F],
    [0xFF03045E, 0xFF90E0EF, 0xFF1B4332],
    [0xFF370617, 0xFFF48C06, 0xFF432818],
    [0xFF10002B, 0xFFE0AAFF, 0xFF240046],
  ];
  final th = themes[s.level.theme % 4];
  c.drawRect(
    const Rect.fromLTWH(0, 0, kWorldW, kWorldH),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(th[0]), Color(th[1])],
      ).createShader(const Rect.fromLTWH(0, 0, kWorldW, kRunGround)),
  );
  c.drawCircle(const Offset(760, 330), 110, _p(0xCCFFF3B0));
  // parallax mountains & bamboo
  for (var layer = 0; layer < 2; layer++) {
    final k = layer == 0 ? 0.15 : 0.4;
    final col = layer == 0 ? 0x55000000 : 0x88000000;
    final off = (s.dist * k) % 600;
    final path = Path()..moveTo(-off - 600, kRunGround);
    for (var x = -off - 600; x < kWorldW + 600; x += 300) {
      path.lineTo(x + 150, kRunGround - (layer == 0 ? 520 : 300) - (x.round() * 7 % 120));
      path.lineTo(x + 300, kRunGround);
    }
    path.close();
    c.drawPath(path, _p(col));
  }
  final boff = (s.dist * 0.7) % 220;
  for (var x = -boff; x < kWorldW; x += 220) {
    c.drawRect(Rect.fromLTWH(x, kRunGround - 520, 16, 520), _p(0x6640916C));
  }
  // ground with pits
  final groundPaint = _p(th[2]);
  var gx = 0.0;
  final pits = s.obs.where((o) => o.type == obPit).toList()..sort((a, b) => a.pos.compareTo(b.pos));
  double sx(double pos) => pos - s.dist + kRunnerX;
  for (final o in pits) {
    final a = sx(o.pos), b = sx(o.pos + o.w);
    if (b < 0 || a > kWorldW) continue;
    if (a > gx) c.drawRect(Rect.fromLTRB(gx, kRunGround, a, kWorldH), groundPaint);
    gx = math.max(gx, b);
  }
  if (gx < kWorldW) c.drawRect(Rect.fromLTRB(gx, kRunGround, kWorldW, kWorldH), groundPaint);
  c.drawLine(
    const Offset(0, kRunGround),
    const Offset(kWorldW, kRunGround),
    Paint()
      ..color = Colors.white24
      ..strokeWidth = 4,
  );
  // finish flag
  if (s.level.length > 0) {
    final fx = sx(s.level.length);
    if (fx < kWorldW + 50) {
      c.drawLine(
        Offset(fx, kRunGround),
        Offset(fx, kRunGround - 300),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 8,
      );
      c.drawRect(Rect.fromLTWH(fx, kRunGround - 300, 120, 70), _p(0xFFE63946));
    }
  }
  // obstacles
  for (final o in s.obs) {
    if (o.dead && o.type != obPit) continue;
    final x = sx(o.pos);
    if (x > kWorldW + 100 || x + o.w < -100) continue;
    switch (o.type) {
      case obSpike:
        final n = (o.w / 35).round();
        for (var i = 0; i < n; i++) {
          c.drawPath(
            Path()
              ..moveTo(x + i * 35, kRunGround)
              ..lineTo(x + i * 35 + 17.5, kRunGround - 60)
              ..lineTo(x + i * 35 + 35, kRunGround)
              ..close(),
            _p(0xFFADB5BD),
          );
        }
      case obBar:
        c.drawRect(Rect.fromLTWH(x - 10, kRunGround - 330, 14, 330), _p(0xFF6F4518));
        c.drawRect(Rect.fromLTWH(x + o.w - 4, kRunGround - 330, 14, 330), _p(0xFF6F4518));
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - 10, kRunGround - 260, o.w + 20, 170), const Radius.circular(10)),
          _p(0xFF99582A),
        );
      case obWall:
        c.drawRect(Rect.fromLTWH(x, kRunGround - 160, o.w, 160), _p(0xFF6C757D));
        for (var yy = 0.0; yy < 160; yy += 40) {
          c.drawLine(
            Offset(x, kRunGround - yy),
            Offset(x + o.w, kRunGround - yy),
            Paint()
              ..color = const Color(0xFF495057)
              ..strokeWidth = 4,
          );
        }
      case obNinja:
        final hx = x + o.w / 2;
        final st = Paint()
          ..color = const Color(0xFF7B2CBF)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round;
        final sw = math.sin(t * 16) * 20;
        c.drawLine(Offset(hx, kRunGround - 70), Offset(hx + sw, kRunGround), st);
        c.drawLine(Offset(hx, kRunGround - 70), Offset(hx - sw, kRunGround), st);
        c.drawLine(Offset(hx, kRunGround - 70), Offset(hx, kRunGround - 140), st);
        c.drawCircle(Offset(hx, kRunGround - 160), 22, _p(0xFF7B2CBF));
        c.drawLine(
          Offset(hx, kRunGround - 120),
          Offset(hx - 60, kRunGround - 150),
          Paint()
            ..color = const Color(0xFFE0E1DD)
            ..strokeWidth = 6,
        );
      case obStar:
        final cx = x + o.w / 2, cy = kRunGround - 120;
        final path = Path();
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4 + t * 20;
          final r = i.isEven ? 30.0 : 10.0;
          final pt = Offset(cx + math.cos(a) * r, cy + math.sin(a) * r);
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        c.drawPath(path..close(), _p(0xFFCED4DA));
      default:
        break;
    }
  }
  for (var i = 0; i < s.coins.length; i++) {
    final x = sx(s.coins[i]);
    if (x < -40 || x > kWorldW + 40) continue;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x, kRunGround - s.coinY[i] - 40),
        width: 34 * (0.6 + 0.4 * math.cos(t * 6 + i).abs()),
        height: 34,
      ),
      _p(0xFFFFD60A),
    );
  }
  // runner (ninja)
  final blink = s.shield > 0 && (s.ticks ~/ 5).isOdd;
  if (!blink) {
    final col = p.piece(0);
    final pt = Paint()
      ..color = col
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final base = Offset(kRunnerX, kRunGround - s.y);
    if (s.sliding) {
      c.drawLine(base.translate(-50, -16), base.translate(40, -24), pt);
      c.drawLine(base.translate(40, -24), base.translate(70, -10), pt);
      c.drawCircle(base.translate(-60, -40), 24, Paint()..color = col);
    } else {
      final run = s.y > 0.5 ? 0.0 : math.sin(s.ticks * 0.5) * 34;
      final hip = base.translate(0, -70);
      c.drawLine(hip, base.translate(run, 0), pt);
      c.drawLine(hip, base.translate(-run, 0), pt);
      final neck = hip.translate(14, -70);
      c.drawLine(hip, neck, pt);
      c.drawLine(neck.translate(0, 10), neck.translate(-run * 0.8 - 10, 60), pt);
      c.drawCircle(neck.translate(6, -26), 26, Paint()..color = col);
      c.drawRect(Rect.fromCenter(center: neck.translate(10, -28), width: 50, height: 12), _p(0xFFE63946));
      c.drawLine(
        neck.translate(-18, -28),
        neck.translate(-60 - math.sin(t * 15) * 10, -18),
        Paint()
          ..color = const Color(0xFFE63946)
          ..strokeWidth = 8,
      );
      if (s.slash > 0) {
        c.drawArc(
          Rect.fromCircle(center: neck.translate(30, 0), radius: 150),
          -1.2,
          2.0 * (1 - s.slash / 14) + 0.4,
          false,
          Paint()
            ..color = const Color(0xCCFFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14,
        );
      } else {
        c.drawLine(
          neck.translate(0, 10),
          neck.translate(70, 30),
          Paint()
            ..color = const Color(0xFFE0E1DD)
            ..strokeWidth = 6,
        );
      }
    }
  }
  paintText(c, '🪙 ${s.coinCount}', const Offset(120, 130), 40, Colors.white);
  // touch hints
  paintText(c, '⤴', const Offset(500, 1420), 70, Colors.white24);
  paintText(c, '↓ ⇢', const Offset(500, 1520), 46, Colors.white24);
}

Sfx? runSound(ArcadeSim sim) => switch ((sim as RunSim).lastEvent) {
  1 => Sfx.coin,
  2 => Sfx.clear,
  3 => Sfx.tap,
  _ => null,
};
