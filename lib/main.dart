import 'package:flutter/material.dart';

import 'data/progress_repository.dart';
import 'data/puzzle_library.dart';
import 'l10n/app_localizations.dart';
import 'ui/screens/select_screen.dart';
import 'ui/theme/nodro_theme.dart';

void main() => runApp(const NodroApp());

/// Loads the shipped bank and the player's history, then hands off to the hub.
///
/// Dark mode ships from the first screen rather than being retrofitted: the
/// greyscale accessibility rule has to hold in both, and adding a second
/// palette later would mean re-deriving it against a constraint the first was
/// already built around.
class NodroApp extends StatefulWidget {
  const NodroApp({super.key, this.progressOverride});

  /// Lets tests supply an in-memory repository instead of platform storage.
  final ProgressRepository? progressOverride;

  @override
  State<NodroApp> createState() => _NodroAppState();
}

class _NodroAppState extends State<NodroApp> {
  ThemeMode _themeMode = ThemeMode.system;
  PuzzleLibrary? _library;
  ProgressRepository? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final progress =
          widget.progressOverride ?? SharedPrefsProgressRepository();
      await progress.load();
      final library = await PuzzleLibrary.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _progress = progress;
        _library = library;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  /// Flips the theme.
  ///
  /// It deliberately does NOT ask `Theme.of(context)`: this State sits ABOVE
  /// the MaterialApp, so that lookup returns Flutter's default theme rather
  /// than the app's. It always reported "light", so the button switched to dark
  /// once and then did nothing for the rest of the session. The mode is tracked
  /// here instead, and "system" resolves against the platform brightness.
  void _toggleTheme() {
    setState(() {
      _themeMode = switch (_themeMode) {
        ThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark
              ? ThemeMode.light
              : ThemeMode.dark,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.light,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildNodroTheme(Brightness.light),
      darkTheme: buildNodroTheme(Brightness.dark),
      themeMode: _themeMode,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          final palette = NodroPalette.of(context);
          final library = _library;
          final progress = _progress;

          if (_error != null) {
            return _Splash(
                palette: palette, text: '${l10n.loadFailed}\n\n$_error');
          }
          if (library == null || progress == null) {
            return _Splash(palette: palette, text: l10n.loadingBank);
          }
          return SelectScreen(
            library: library,
            progress: progress,
            onToggleTheme: _toggleTheme,
          );
        },
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({required this.palette, required this.text});

  final NodroPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.paper,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.ink, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
