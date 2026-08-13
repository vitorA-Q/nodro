import 'package:flutter/material.dart';

import '../../data/progress_repository.dart';
import '../../l10n/app_localizations.dart';
import '../game/play_grid.dart';
import '../theme/nodro_theme.dart';

/// Everything adjustable, gathered in one place.
///
/// The automatic-marking control also lives inside the puzzle, because that is
/// where a player realises they want it. Having it in both places is not
/// duplication — it is the difference between a setting people find and one
/// they do not.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.progress,
    required this.onChanged,
    required this.onReplayTutorial,
  });

  final ProgressRepository progress;
  final VoidCallback onChanged;
  final VoidCallback onReplayTutorial;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _set(String key, String? value) async {
    await widget.progress.setFlag(key, value);
    if (mounted) {
      setState(() {});
      widget.onChanged();
    }
  }

  /// Two confirmations, deliberately. Erasing is the only action here that
  /// destroys something the player spent weeks building.
  Future<void> _erase() async {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);

    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.paper,
        title: Text(l10n.settingsEraseAll,
            style: TextStyle(color: palette.ink)),
        content: Text(l10n.settingsEraseWarning,
            style: TextStyle(color: palette.inkSoft)),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.settingsEraseConfirm,
                  style: TextStyle(color: palette.danger))),
        ],
      ),
    );
    if (first != true || !mounted) {
      return;
    }

    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.paper,
        title: Text(l10n.settingsEraseReally,
            style: TextStyle(color: palette.ink)),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.settingsEraseConfirm,
                  style: TextStyle(color: palette.danger))),
        ],
      ),
    );
    if (second != true || !mounted) {
      return;
    }

    await widget.progress.eraseAll();
    if (!mounted) {
      return;
    }
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsErased),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);
    final progress = widget.progress;

    final themeMode = progress.flag(Flags.themeMode) ?? 'system';
    final level = AutoMarkLevel.fromKey(progress.autoMark());
    final showTimer = progress.flag(Flags.showTimer) != 'off';
    final haptics = progress.flag(Flags.haptics) != 'off';
    final locale = progress.flag(Flags.locale) ?? 'system';

    return Scaffold(
      backgroundColor: palette.paper,
      appBar: AppBar(
        backgroundColor: palette.paper,
        foregroundColor: palette.ink,
        elevation: 0,
        title: Text(l10n.settingsTitle,
            style: TextStyle(
                color: palette.ink, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: <Widget>[
                _Section(palette: palette, title: l10n.settingsTheme),
                for (final option in <(String, String)>[
                  ('system', l10n.themeSystem),
                  ('light', l10n.themeLight),
                  ('dark', l10n.themeDark),
                ])
                  _Choice(
                    palette: palette,
                    label: option.$2,
                    selected: themeMode == option.$1,
                    onTap: () => _set(Flags.themeMode, option.$1),
                  ),

                _Section(palette: palette, title: l10n.autoMarkTitle),
                for (final option in <(AutoMarkLevel, String, String)>[
                  (AutoMarkLevel.off, l10n.autoMarkOff, l10n.autoMarkOffBody),
                  (
                    AutoMarkLevel.neighbours,
                    l10n.autoMarkNeighbours,
                    l10n.autoMarkNeighboursBody
                  ),
                  (AutoMarkLevel.full, l10n.autoMarkFull, l10n.autoMarkFullBody),
                ])
                  _Choice(
                    palette: palette,
                    label: option.$2,
                    subtitle: option.$3,
                    selected: level == option.$1,
                    onTap: () async {
                      await progress.setAutoMark(option.$1.storageKey);
                      if (mounted) {
                        setState(() {});
                        widget.onChanged();
                      }
                    },
                  ),

                _Section(palette: palette, title: l10n.settingsLanguage),
                for (final option in <(String, String)>[
                  ('system', l10n.languageSystem),
                  ('pt', 'Português'),
                  ('en', 'English'),
                ])
                  _Choice(
                    palette: palette,
                    label: option.$2,
                    selected: locale == option.$1,
                    onTap: () => _set(Flags.locale, option.$1),
                  ),

                const SizedBox(height: 18),
                SwitchListTile(
                  value: showTimer,
                  onChanged: (value) =>
                      _set(Flags.showTimer, value ? 'on' : 'off'),
                  title: Text(l10n.settingsTimer,
                      style: TextStyle(color: palette.ink, fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: haptics,
                  onChanged: (value) =>
                      _set(Flags.haptics, value ? 'on' : 'off'),
                  title: Text(l10n.settingsHaptics,
                      style: TextStyle(color: palette.ink, fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.school_outlined, color: palette.ink),
                  title: Text(l10n.openTutorial,
                      style: TextStyle(color: palette.ink, fontSize: 14)),
                  onTap: widget.onReplayTutorial,
                ),

                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.delete_forever_outlined, color: palette.danger),
                  title: Text(l10n.settingsEraseAll,
                      style: TextStyle(color: palette.danger, fontSize: 14)),
                  onTap: _erase,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.palette, required this.title});

  final NodroPalette palette;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          color: palette.inkSoft,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final NodroPalette palette;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? palette.accent : palette.inkSoft,
      ),
      title: Text(label,
          style: TextStyle(
              color: palette.ink,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              style: TextStyle(color: palette.inkSoft, fontSize: 11.5)),
    );
  }
}
