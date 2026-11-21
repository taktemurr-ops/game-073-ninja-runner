import 'dart:math' as math;

import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';

/// Side-scrolling ninja runner: jump (double), slide, slash.
const double kRunGround = 1200;
const double kRunnerX = 260;

const obSpike = 0, obPit = 1, obBar = 2, obWall = 3, obNinja = 4, obStar = 5;

class Obstacle {
  final int type;
  double pos; // world distance of the left edge
  final double w;
  bool dead = false;
  bool passed = false;
  Obstacle(this.type, this.pos, this.w);
}

class RunLevel {
  final ArcadeMeta meta;
  final double length; // 0 = endless
  final double speed;
  final double accel;
  final List<int> types;
  final int theme;
  const RunLevel(this.meta, this.length, this.speed, this.accel, this.types, this.theme);
}

RunLevel generateRun(LevelSpec spec) {
  final m = ArcadeMeta.of(spec);
  final d = spec.difficulty;
  final types = [obSpike, obPit, obBar, obWall, obNinja, obStar].take((2 + d ~/ 2).clamp(2, 6)).toList();
  if (spec.has('ninjas') && !types.contains(obNinja)) types.add(obNinja);
  if (spec.has('stars') && !types.contains(obStar)) types.add(obStar);
  return RunLevel(m, m.goal ? 12000 + d * 2400.0 : 0, 10 + d * 0.5, m.goal ? 0.0006 : 0.0015, types, spec.theme % 4);
}

class RunSim extends ArcadeSim {
  final RunLevel level;
  double dist = 0;
  double speed;
  double y = 0, vy = 0;
  bool doubleUsed = false;
  int slide = 0;
  int slash = 0;
  int slashCd = 0;
  int pendingTap = 0;
  final List<Obstacle> obs = [];
  final List<double> coins = []; // pos
  final List<double> coinY = [];
  double nextAt = 900;
  int coinCount = 0, slashed = 0, jumps = 0, obstaclesCleared = 0;
  int lastEvent = 0; // 1 coin, 2 slash kill, 3 jump, 4 hurt

  RunSim(this.level) : speed = level.speed, super(level.meta, lives: 3) {
    _fill();
  }

  void _fill() {
    while (nextAt < dist + 2600) {
      if (level.length > 0 && nextAt > level.length - 300) {
        nextAt = dist + 1e9;
        break;
      }
      final t = level.types[rng.nextInt(level.types.length)];
      final w = switch (t) {
        obPit => 150 + rng.nextDouble() * (60 + meta.difficulty * 14),
        obBar => 120.0,
        obWall => 60.0,
        obNinja => 70.0,
        obStar => 40.0,
        _ => 70.0 + (rng.chance(0.3) ? 70 : 0),
      };
      obs.add(Obstacle(t, nextAt, w));
      // coins
      if (rng.chance(0.5)) {
        for (var i = 0; i < 5; i++) {
          coins.add(nextAt - 260 + i * 60);
          coinY.add(
            t == obBar || t == obStar
                ? 30
                : (t == obPit || t == obSpike || t == obWall ? 60.0 + math.sin(i / 4 * math.pi) * 150 : 30),
          );
        }
      }
      // Reaction gap: at least ~55 ticks of running between obstacles.
      final minGap = speed * (60 - meta.difficulty * 2.5) + w + 120;
      nextAt += minGap + rng.nextDouble() * 500;
    }
  }

  bool get sliding => slide > 0 && y <= 0.5;
  double get height => sliding ? 60 : 140;

  @override
  void update(ArcadeInput input) {
    lastEvent = 0;
    // input: a touch jumps on release unless it turned into a swipe
    // (keyboard / no pointer: immediately).
    var jump = input.swipe == 0;
    if (input.tap && !input.hasPointer) jump = true;
    if (input.tap && input.hasPointer) pendingTap = 1;
    if (pendingTap > 0) {
      if (input.swipe >= 0) {
        pendingTap = 0;
      } else if (!input.down || pendingTap > 9) {
        pendingTap = 0;
        jump = true;
      } else {
        pendingTap++;
      }
    }
    if (jump) {
      if (y <= 0.5) {
        vy = 27;
        jumps++;
        slide = 0;
        doubleUsed = false;
        lastEvent = 3;
      } else if (!doubleUsed) {
        vy = 24;
        doubleUsed = true;
        jumps++;
      }
    }
    if (input.swipe == 2 || input.dirY == 1) {
      if (y > 0.5) {
        vy = math.min(vy, -20);
      } else {
        slide = 42;
      }
    }
    if ((input.swipe == 1 || input.dirX == 1) && slashCd == 0) {
      slash = 14;
      slashCd = 28;
    }
    if (slide > 0) slide--;
    if (slash > 0) slash--;
    if (slashCd > 0) slashCd--;
    // physics
    speed += level.accel;
    if (level.length == 0) speed = math.min(speed, 24);
    dist += speed;
    final overPit = _pitUnder();
    if (y > 0 || vy > 0 || overPit) {
      y += vy;
      vy -= 1.7;
      if (y <= 0 && !overPit) {
        y = 0;
        vy = 0;
      }
    }
    if (overPit && y < -120) {
      hit();
      _respawnAfterPit();
    }
    score = (dist / 10).round() + coinCount * 10 + slashed * 50;
    // enemies move toward the runner
    for (final o in obs) {
      if (o.type == obNinja && !o.dead) o.pos -= 3;
      if (o.type == obStar && !o.dead) o.pos -= 9;
    }
    _collide();
    _coins();
    obs.removeWhere((o) => o.pos + o.w < dist - 400);
    _fill();
    if (level.length > 0 && dist >= level.length) win();
  }

  bool _pitUnder() {
    final x = dist + kRunnerX;
    for (final o in obs) {
      if (o.type == obPit && x > o.pos + 18 && x < o.pos + o.w - 18) return true;
    }
    return false;
  }

  void _respawnAfterPit() {
    final x = dist + kRunnerX;
    for (final o in obs) {
      if (o.type == obPit && x > o.pos - 50 && x < o.pos + o.w + 50) {
        dist = o.pos + o.w + 10 - kRunnerX;
      }
    }
    y = 0;
    vy = 0;
  }

  void _collide() {
    final x0 = dist + kRunnerX - 28, x1 = dist + kRunnerX + 28;
    for (final o in obs) {
      if (o.dead) continue;
      // slash reach
      if (slash > 8 && (o.type == obNinja || o.type == obStar) && o.pos > x1 - 20 && o.pos < x1 + 190) {
        o.dead = true;
        slashed++;
        lastEvent = 2;
        continue;
      }
      if (o.pos > x1 || o.pos + o.w < x0) {
        if (!o.passed && o.pos + o.w < x0) {
          o.passed = true;
          obstaclesCleared++;
        }
        continue;
      }
      bool hitIt;
      switch (o.type) {
        case obSpike:
          hitIt = y < 55;
        case obPit:
          hitIt = false;
        case obBar:
          hitIt = !sliding && y < 200; // bar from 90 up to 260
        case obWall:
          hitIt = y < 160;
        case obNinja:
          hitIt = y < 120;
        default: // shuriken at head height 100..140
          hitIt = !sliding && y < 150 && y + height > 95;
      }
      if (hitIt) {
        o.dead = true;
        lastEvent = 4;
        hit();
      }
    }
  }

  void _coins() {
    final x = dist + kRunnerX;
    for (var i = coins.length - 1; i >= 0; i--) {
      if (coins[i] < dist - 300) {
        coins.removeAt(i);
        coinY.removeAt(i);
        continue;
      }
      if ((coins[i] - x).abs() < 50 && (coinY[i] - (y + height / 2)).abs() < 90) {
        coins.removeAt(i);
        coinY.removeAt(i);
        coinCount++;
        lastEvent = 1;
      }
    }
  }

  @override
  void onLifeLost() {
    slide = 0;
  }

  @override
  bool useBooster() {
    if (over) return false;
    shield = 360;
    return true;
  }

  @override
  double get progress => level.length > 0 ? dist / level.length : 0;

  @override
  String get goalText =>
      level.length > 0 ? '${(dist / 100).floor()}/${(level.length / 100).floor()}m' : '${(dist / 100).floor()}m';

  @override
  Map<String, int> get stats => {
    'distance_m': (dist / 100).floor(),
    'coins': coinCount,
    'ninjas_slashed': slashed,
    'obstacles_cleared': obstaclesCleared,
  };

  @override
  int get stars => lifeStars(this, 3);
}

/// Autopilot: reacts to the next obstacle at a speed-dependent distance.
ArcadeInput runBotInput(ArcadeSim sim) {
  final g = sim as RunSim;
  final x = g.dist + kRunnerX;
  Obstacle? next;
  for (final o in g.obs) {
    if (o.dead || o.pos + o.w < x - 30) continue;
    if (next == null || o.pos < next.pos) next = o;
  }
  if (next == null) return ArcadeInput.idle;
  final ahead = next.pos - x;
  final v = g.speed + (next.type == obNinja ? 3 : (next.type == obStar ? 9 : 0));
  final ticksTo = ahead / v;
  switch (next.type) {
    case obNinja:
    case obStar:
      if (ahead < 170 && ahead > 0 && g.slashCd == 0) return const ArcadeInput(swipe: 1);
      if (next.type == obStar && ticksTo < 8 && g.y <= 0.5 && !g.sliding) return const ArcadeInput(swipe: 2);
      return ArcadeInput.idle;
    case obBar:
      if (ticksTo < 10 && ticksTo > -3 && !g.sliding) {
        return g.y > 0.5 ? const ArcadeInput(swipe: 2) : const ArcadeInput(swipe: 2);
      }
      if (g.sliding && g.slide < 6 && ahead + next.w > -30) return const ArcadeInput(swipe: 2);
      return ArcadeInput.idle;
    default:
      // jump so that the apex is over the obstacle centre
      final airTicks = 2 * 27 / 1.7;
      final need = (ahead + next.w / 2) / g.speed;
      if (g.y <= 0.5 && need < airTicks / 2 + 1 && ahead > -10) return const ArcadeInput(tap: true);
      if (g.y > 0.5 &&
          !g.doubleUsed &&
          next.type == obPit &&
          g.vy < 0 &&
          (next.pos + next.w - x) / g.speed > (g.y + 40) / math.max(1.0, -g.vy)) {
        return const ArcadeInput(tap: true);
      }
      return ArcadeInput.idle;
  }
}
