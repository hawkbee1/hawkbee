// Copies packages/hawkbee_schema into every Dart function under
// backend/functions/<name>/vendor/hawkbee_schema.
//
// The Appwrite CLI uploads only a function's own folder, so a `path:`
// dependency pointing outside it would not resolve on the server. The copy is
// git-ignored and regenerated before every analyze, test and deploy.
//
// Usage: dart run tool/vendor_schema.dart [--pub-get]
import 'dart:io';

const _schemaDir = 'packages/hawkbee_schema';
const _functionsDir = 'backend/functions';

Future<void> main(List<String> args) async {
  final runPubGet = args.contains('--pub-get');
  final schemaLib = Directory('$_schemaDir/lib');
  final schemaPubspec = File('$_schemaDir/pubspec.yaml');

  final functions = Directory(_functionsDir)
      .listSync()
      .whereType<Directory>()
      .where((dir) => File('${dir.path}/pubspec.yaml').existsSync());

  for (final function in functions) {
    final target = Directory('${function.path}/vendor/hawkbee_schema');
    if (target.existsSync()) target.deleteSync(recursive: true);
    target.createSync(recursive: true);

    _copyDirectory(schemaLib, Directory('${target.path}/lib'));
    File(
      '${target.path}/pubspec.yaml',
    ).writeAsStringSync(_standalonePubspec(schemaPubspec.readAsStringSync()));
    stdout.writeln('Vendored hawkbee_schema into ${function.path}');

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

/// Drops `resolution: workspace` and `dev_dependencies`, which only make
/// sense inside the monorepo's pub workspace.
String _standalonePubspec(String pubspec) {
  final output = StringBuffer();
  var skipping = false;
  for (final line in pubspec.split('\n')) {
    final isTopLevelKey = line.isNotEmpty && !line.startsWith(RegExp(r'\s'));
    if (isTopLevelKey) skipping = line.startsWith('dev_dependencies:');
    if (skipping || line.trim() == 'resolution: workspace') continue;
    output.writeln(line);
  }
  return '${output.toString().trimRight()}\n';
}

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
