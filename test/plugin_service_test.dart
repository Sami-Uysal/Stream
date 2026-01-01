import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream/core/services/plugin_service.dart';
import 'package:stream/features/plugins/models/stream_request.dart';

void main() {
  late PluginService pluginService;

  setUp(() {
    pluginService = PluginService();
  });

  tearDown(() {
    pluginService.dispose();
  });

  test('PluginService loads mock plugin and extracts streams', () async {
    // 1. Initialize
    try {
      await pluginService.init();
    } catch (e) {
      if (e.toString().contains('quickjs_c_bridge.dll')) {
        print('Skipping JS Runtime test: Native library not found (Expected in CLI/Test environment).');
        return;
      }
      rethrow;
    }

    // 2. Read Mock JS
    final file = File('test/fixtures/mock_plugin.js');
    final jsCode = await file.readAsString();

    // 3. Load Plugin
    final manifest = await pluginService.loadPlugin(jsCode);
    
    expect(manifest.id, 'mock.plugin.v1');
    expect(manifest.name, 'Mock Provider');

    // 4. Request Streams
    final request = StreamRequest(
      type: 'movie',
      ids: {'imdb': 'tt12345'},
      title: 'Big Buck Bunny', // Matches the mock logic
      year: 2008
    );

    final streams = await pluginService.extractStreams(request);

    // 5. Verify Results
    expect(streams.isNotEmpty, true);
    expect(streams.first.name, '4K | Mock');
    expect(streams.first.url, contains('BigBuckBunny.mp4'));
  });
}
