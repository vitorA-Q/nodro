import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'ui/screens/play_screen.dart';
import 'ui/theme/nodro_theme.dart';

void main() => runApp(const NodroApp());

/// Stage A of the UI: a single screen holding a single puzzle.
///
/// Dark mode ships from the first screen rather than being retrofitted — the
/// greyscale accessibility rule has to hold in both, and adding a second
/// palette later would mean re-deriving it against a constraint the first one
/// was already built around.
class NodroApp extends StatelessWidget {
  const NodroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildNodroTheme(Brightness.light),
      darkTheme: buildNodroTheme(Brightness.dark),
      home: const PlayScreen(),
    );
  }
}
