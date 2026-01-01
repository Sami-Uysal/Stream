import 'package:flutter_test/flutter_test.dart';
import 'package:stream/core/services/plugin_service.dart';

void main() {
  late PluginService pluginService;

  setUp(() {
    pluginService = PluginService();
  });

  tearDown(() {
    pluginService.dispose();
  });

  test('PluginService loads mock plugin and extracts streams', () async {
  });
}
