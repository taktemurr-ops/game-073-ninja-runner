import 'package:flutter/material.dart';

import '../app/arcade_stage.dart';
import '../app/game_api.dart';
import '../core/game_rules.dart';
import 'runner_engine.dart';
import 'run_view.dart';
import 'rules.dart';

final gameConfig = GameConfig(
  gameId: 'game-073-ninja-runner',
  title: const ['Ninja Koşucu', 'Ninja Runner', 'Ninja-Läufer', 'Corredor Ninja', 'Coureur Ninja'],
  tagline: const ['Zıpla, kay, biç: durmadan koş!', 'Jump, slide, slash – never stop running!', 'Springen, rutschen, schlagen!', '¡Salta, deslízate, corta!', 'Sautez, glissez, tranchez !'],
  seedColor: const Color(0xFF1D3557),
  icon: Icons.directions_run,
  rules: NinjaRules(),
  buildPlay: (ctx) => ArcadeStage(
    ctx: ctx,
    create: () => RunSim((ctx.generated as GeneratedLevel<RunLevel>).puzzle),
    paint: paintRun,
    sound: runSound,
    boosterIcon: Icons.shield,
    boosterLabel: (l) => l == 'tr' ? 'Kalkan' : 'Shield',
    howTo: const ['Dokun: zıpla (havada tekrar: çift zıplama). Aşağı kaydır: kay. Sağa kaydır: kılıç darbesi.', 'Tap to jump (again in the air to double jump). Swipe down to slide, right to slash.', 'Tippen: springen. Nach unten: rutschen. Nach rechts: Schlag.', 'Toca: salta. Abajo: desliza. Derecha: corta.', 'Touchez : saut. Bas : glisser. Droite : trancher.'],
  ),
  tutorial: const [
    TutorialStep(Icons.north, ['Dikenlerin ve uçurumların üstünden zıpla.', 'Jump over spikes and pits.', 'Über Stacheln springen.', 'Salta pinchos y fosos.', 'Sautez les pics.']),
    TutorialStep(Icons.south, ['Alçak kirişlerin ve shurikenlerin altından kay.', 'Slide under bars and shuriken.', 'Unter Balken rutschen.', 'Deslízate bajo barras.', 'Glissez sous les barres.']),
    TutorialStep(Icons.east, ['Ninjaları sağa kaydırarak biç.', 'Swipe right to slash ninjas.', 'Nach rechts wischen: Ninjas schlagen.', 'Desliza a la derecha: corta.', 'Glissez à droite : trancher.']),
  ],
);
