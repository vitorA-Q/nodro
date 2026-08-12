import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'ui/painters/star_battle_painter.dart';
import 'ui/screens/play_screen.dart';

void main() => runApp(const NodroApp());

/// Stage A of the UI: a single screen holding a single puzzle.
///
/// No routing, no navigation, no state management package. All of that is real
/// work that becomes much easier to get right once there is something playable
/// to react to — so it waits.
class NodroApp extends StatelessWidget {
  const NodroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: StarBattlePainter.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: StarBattlePainter.ink,
          surface: StarBattlePainter.paper,
        ),
      ),
      home: const PlayScreen(),
    );
  }
}
