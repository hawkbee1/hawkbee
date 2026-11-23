// A headless MCP server for any `.fscene` scene, over stdio.
//
// Upstream's `dart run flutter_scene_mcp <scene>` loads one scene for the
// whole connection. This server starts with no scene and adds the
// open_document, save_document and new_document tools, so the one server in
// .mcp.json serves every scene an agent meets. Edits stay in memory until
// save_document. The other tools (describe_scene, get_node, search_commands,
// run_command, run_query, ...) are upstream's. The server is headless, so it
// has no screenshot or render tools.
//
// It is not a workspace member: fscene_mcp.sh runs it against the
// packages/flutter_scene submodule's package config, so the root analyzer
// excludes this folder.
//
// Usage: tool/fscene_mcp/fscene_mcp.sh [scene.fscene]
import 'dart:io';

import 'package:dart_mcp/stdio.dart';
import 'package:flutter_scene_editor_core/flutter_scene_editor_core.dart';
import 'package:flutter_scene_mcp/flutter_scene_mcp.dart';

Future<void> main(List<String> args) async {
  EditorSession? session;
  String? scenePath;

  Future<void> open(String path) async {
    final file = File(path).absolute;
    try {
      session = EditorSession.fromFscene(await file.readAsString());
    } on Object catch (e) {
      // The surface reports a FormatException to the agent as a tool error.
      throw FormatException('Cannot open ${file.path}: $e');
    }
    scenePath = file.path;
  }

  Future<String> save({String? path}) async {
    final current = session;
    if (current == null) {
      throw const ToolError('No document is open');
    }
    final target = path ?? scenePath;
    if (target == null) {
      throw const FormatException(
        'save_document needs a "path" the first time',
      );
    }
    final file = File(target).absolute;
    await file.writeAsString(current.toFscene());
    scenePath = file.path;
    return file.path;
  }

  if (args.isNotEmpty) await open(args.first);

  final server = serveOverChannel(
    stdioChannel(input: stdin, output: stdout),
    EditorToolSurface(
      () => session,
      newDocument: () async {
        session = EditorSession.empty();
        scenePath = null;
      },
      openDocument: open,
      saveDocument: save,
    ),
  );
  await server.done;
}
