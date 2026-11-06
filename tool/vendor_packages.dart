// Copies into every Dart function under backend/functions/<name>/vendor/ the
// packages its pubspec takes from there (`path: vendor/<package>`).
//
// The Appwrite CLI uploads only a function's own folder, so a `path:`
// dependency pointing outside it would not resolve on the server. The
// copies are committed (stack decision 7) and regenerated before every
// analyze, test and deploy; `melos run backend:vendor:check` fails when one
// is out of date.
//
// - A package of `packages/<package>`: its `lib/` and a standalone pubspec.
//   Its dependencies on other packages of `packages/` point at their own
//   copies (`path: ../<dep>`), vendored too.
// - `plan_data`: the Battle Team plan's data files (`apps/battle_team/plan/
//   data/*.yaml` and `milestones/economy.yaml`) as Dart string constants,
//   for the functions that apply the rules (stack decision 8).
//
// Usage: dart run tool/vendor_packages.dart [--pub-get]
import 'dart:io';

const _packagesDir = 'packages';
const _functionsDir = 'backend/functions';
const _planDataDir = 'apps/battle_team/plan/data';
// economy.yaml lives with the milestones (owner, 2026-11-01).
const _planEconomy = 'apps/battle_team/plan/milestones/economy.yaml';
const _planData = 'plan_data';

Future<void> main(List<String> args) async {
  final runPubGet = args.contains('--pub-get');
  final functions = Directory(_functionsDir)
      .listSync()
      .whereType<Directory>()
      .where((dir) => File('${dir.path}/pubspec.yaml').existsSync());

  for (final function in functions) {
    final vendor = Directory('${function.path}/vendor');
    if (vendor.existsSync()) vendor.deleteSync(recursive: true);
    final wanted = _vendored(
      File('${function.path}/pubspec.yaml').readAsStringSync(),
    ).toList();
    final done = <String>{};
    while (wanted.isNotEmpty) {
      final name = wanted.removeLast();
      if (!done.add(name)) continue;
      if (name == _planData) {
        _writePlanData(Directory('${vendor.path}/$_planData'));
      } else {
        wanted.addAll(_vendorPackage(name, vendor));
      }
      stdout.writeln('Vendored $name into ${function.path}');
    }

    if (runPubGet) {
      final result = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: function.path);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode != 0) exit(result.exitCode);
    }
  }
}

/// The packages a pubspec takes from `vendor/`.
Iterable<String> _vendored(String pubspec) =>
    RegExp(r'path:\s*vendor/(\w+)')
        .allMatches(pubspec)
        .map((match) => match.group(1)!);

/// Copies `packages/<name>` into [vendor] and gives the packages of
/// `packages/` it depends on.
List<String> _vendorPackage(String name, Directory vendor) {
  final source = Directory('$_packagesDir/$name');
  final target = Directory('${vendor.path}/$name')..createSync(recursive: true);
  _copyDirectory(
    Directory('${source.path}/lib'),
    Directory('${target.path}/lib'),
  );
  final siblings = <String>[];
  File('${target.path}/pubspec.yaml').writeAsStringSync(
    _standalonePubspec(
      File('${source.path}/pubspec.yaml').readAsStringSync(),
      siblings,
    ),
  );
  return siblings;
}

/// Drops `resolution: workspace` and `dev_dependencies`, which only make
/// sense inside the monorepo's pub workspace, and points the dependencies
/// on packages of `packages/` at their vendored copies, adding them to
/// [siblings].
String _standalonePubspec(String pubspec, List<String> siblings) {
  final output = StringBuffer();
  var section = '';
  for (final line in pubspec.split('\n')) {
    final isTopLevelKey = line.isNotEmpty && !line.startsWith(RegExp(r'\s'));
    if (isTopLevelKey) section = line;
    if (section.startsWith('dev_dependencies:') ||
        line.trim() == 'resolution: workspace') {
      continue;
    }
    final dependency = RegExp(r'^  (\w+):\s*\^').firstMatch(line);
    if (section.startsWith('dependencies:') &&
        dependency != null &&
        Directory('$_packagesDir/${dependency.group(1)}').existsSync()) {
      final name = dependency.group(1)!;
      siblings.add(name);
      output
        ..writeln('  $name:')
        ..writeln('    path: ../$name');
      continue;
    }
    output.writeln(line);
  }
  return '${output.toString().trimRight()}\n';
}

/// Writes the `plan_data` package: one constant per data file.
void _writePlanData(Directory target) {
  final lib = Directory('${target.path}/lib')..createSync(recursive: true);
  File('${target.path}/pubspec.yaml').writeAsStringSync('''
name: $_planData
description: The Battle Team plan's data files, vendored by tool/vendor_packages.dart.
version: 0.1.0
publish_to: none

environment:
  sdk: ^3.13.0
''');
  final files = [
    ...Directory(_planDataDir)
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.yaml')),
    File(_planEconomy),
  ]..sort((a, b) => a.uri.pathSegments.last.compareTo(b.uri.pathSegments.last));
  final output = StringBuffer()
    ..writeln('/// The Battle Team plan\'s data files, as their YAML text.')
    ..writeln('/// Generated by tool/vendor_packages.dart: do not edit.')
    ..writeln('library;');
  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.yaml', '');
    final text = file.readAsStringSync();
    if (text.contains("'''")) {
      throw StateError('${file.path} holds three quotes');
    }
    output
      ..writeln()
      ..writeln('/// `$name.yaml`.')
      ..writeln("const ${_camel(name)}Yaml = r'''")
      ..write(text)
      ..writeln("''';");
  }
  File('${lib.path}/$_planData.dart').writeAsStringSync(output.toString());
}

String _camel(String name) => name.replaceAllMapped(
  RegExp('_(.)'),
  (match) => match.group(1)!.toUpperCase(),
);

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync()) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (entity is Directory) {
      _copyDirectory(entity, Directory('${destination.path}/$name'));
    } else if (entity is File) {
      entity.copySync('${destination.path}/$name');
    }
  }
}
