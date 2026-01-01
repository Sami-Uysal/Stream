import 'package:stream/features/plugins/models/plugin_manifest.dart';

class Plugin {
  final PluginManifest manifest;
  final String filePath;
  bool isEnabled;

  Plugin({
    required this.manifest,
    required this.filePath,
    this.isEnabled = true,
  });

  String get id => manifest.id;
  String get name => manifest.name;
}
