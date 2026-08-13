import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'data/progress_repository.dart';
import 'data/puzzle_library.dart';
import 'l10n/app_localizations.dart';
import 'ui/screens/select_screen.dart';
import 'ui/theme/nodro_theme.dart';

void main() {
  // Clean paths rather than a hash fragment. Search engines treat everything
  // after a # as the same page, and the static site links into the app by path.
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  runApp(const NodroApp());
}

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

  /// Read from stored settings rather than from `Theme.of`.
  ///
  /// An earlier version asked `Theme.of(context)` from this State, which sits
  /// ABOVE the MaterialApp — that lookup returns Flutter's default theme, so it
  /// always reported "light" and the toggle worked exactly once per session.
  ThemeMode get _themeMode => switch (_progress?.flag(Flags.themeMode)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Locale? get _locale => switch (_progress?.flag(Flags.locale)) {
        'pt' => const Locale('pt'),
        'en' => const Locale('en'),
        _ => null, // follow the browser or the device
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
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
            onSettingsChanged: () => setState(() {}),
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
