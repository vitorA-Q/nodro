import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// R5 as an executable rule, not a promise.
///
/// The engine layer must be pure Dart. If it ever needs Flutter, the design is
/// wrong — and the failure mode is silent: someone imports `material.dart` for
/// one colour, and six months later the engine cannot run in a plain Dart
/// isolate, in a benchmark script, or in the bank generator.
void main() {
  test('engine/ imports nothing from package:flutter', () {
    final engineDir = Directory('lib/engine');
    expect(engineDir.existsSync(), isTrue,
        reason: 'lib/engine must exist; the whole architecture rests on it');

    final offenders = <String>[];
    final dartFiles = engineDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (!line.startsWith('import ') && !line.startsWith('export ')) {
          continue;
        }
        if (line.contains('package:flutter/') ||
            line.contains('package:flutter_test/') ||
            line.contains('dart:ui')) {
          offenders.add('${file.path}:${i + 1}  $line');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'engine/ must stay pure Dart (R5). Offending imports:\n'
            '${offenders.join('\n')}');
  });

  test('engine/ contains at least the expected core contracts', () {
    // Guards against the test above passing vacuously if the directory is
    // emptied or moved.
    for (final path in <String>[
      'lib/engine/core/deduction.dart',
      'lib/engine/core/puzzle_type.dart',
      'lib/engine/core/deterministic_random.dart',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
    }
  });
}
