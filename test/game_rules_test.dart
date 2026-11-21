import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:game_073_ninja_runner/game/rules.dart';
import 'package:game_073_ninja_runner/game/runner_engine.dart';

void main() {
  final rules = NinjaRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  RunSim clear() {
    final s = RunSim(rules.build(planner.spec(1)).puzzle);
    s.obs.clear();
    s.coins.clear();
    s.coinY.clear();
    s.nextAt = 1e9;
    return s;
  }

  test('running into a spike costs a life, jumping clears it', () {
    final a = clear();
    a.obs.add(Obstacle(obSpike, a.dist + kRunnerX + 40, 70));
    for (var i = 0; i < 30; i++) {
      a.tick(ArcadeInput.idle);
    }
    expect(a.lives, 2);
    final b = clear();
    b.obs.add(Obstacle(obSpike, b.dist + kRunnerX + 160, 70));
    b.tick(const ArcadeInput(tap: true));
    for (var i = 0; i < 40; i++) {
      b.tick(ArcadeInput.idle);
    }
    expect(b.lives, 3);
  });

  test('sliding passes under a bar, slashing removes a ninja', () {
    final a = clear();
    a.obs.add(Obstacle(obBar, a.dist + kRunnerX + 80, 120));
    a.tick(const ArcadeInput(swipe: 2));
    for (var i = 0; i < 25; i++) {
      a.tick(ArcadeInput.idle);
    }
    expect(a.lives, 3);
    final b = clear();
    b.obs.add(Obstacle(obNinja, b.dist + kRunnerX + 120, 70));
    b.tick(const ArcadeInput(swipe: 1));
    b.tick(ArcadeInput.idle);
    expect(b.slashed, 1);
  });

  test('falling into a pit costs a life and respawns after it', () {
    final s = clear();
    s.obs.add(Obstacle(obPit, s.dist + kRunnerX + 20, 240));
    for (var i = 0; i < 120 && s.lives == 3; i++) {
      s.tick(ArcadeInput.idle);
    }
    expect(s.lives, 2);
    expect(s.y, 0);
  });
}
