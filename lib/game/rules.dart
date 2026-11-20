import '../core/arcade.dart';
import '../core/level_plan.dart';
import '../core/missions.dart';
import '../core/stats.dart';
import 'runner_engine.dart';

class NinjaRules extends ArcadeRules<RunLevel> {
  @override
  String get gameId => 'game-073-ninja-runner';

  @override
  List<String> get optionalMechanics => const ['ninjas', 'stars'];

  @override
  List<GameStat> get gameStats => const [
        GameStat('distance_m', 'Koşulan mesafe (m)', 'Distance run (m)', scale: 5000),
        GameStat('coins', 'Toplanan altın', 'Coins collected', scale: 500),
        GameStat('ninjas_slashed', 'Biçilen ninja', 'Ninjas slashed', scale: 60),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('distance_m', 'distance_m', [1250, 2500, 5000]),
        MissionTemplate('coins', 'coins', [62, 125, 250], coinReward: 80),
      ];

  @override
  RunLevel generate(LevelSpec spec) => generateRun(spec);

  @override
  ArcadeMeta metaOf(RunLevel l) => l.meta;

  @override
  ArcadeSim createSim(RunLevel l) => RunSim(l);

  @override
  ArcadeInput bot(ArcadeSim sim) => runBotInput(sim);
}

ArcadeRules createRules() => NinjaRules();
