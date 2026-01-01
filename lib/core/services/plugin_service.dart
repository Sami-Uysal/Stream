import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:stream/features/plugins/models/plugin.dart';
import 'package:stream/features/plugins/models/plugin_manifest.dart';
import 'package:stream/features/plugins/models/stream_request.dart';
import 'package:stream/features/plugins/models/stream_response.dart';

class PluginService {
  late JavascriptRuntime _runtime;
  final Dio _dio = Dio();
  final List<Plugin> _plugins = [];

  bool _isInitialized = false;

  List<Plugin> get plugins => List.unmodifiable(_plugins);

  PluginService();

  Future<void> init() async {
    if (_isInitialized) return;

    _runtime = getJavascriptRuntime();
    _setupBridge();

    // Load base environment
    final setupResult = await _runtime.evaluateAsync(_baseJsEnv);
    if (setupResult.isError) {
      throw Exception('Failed to initialize JS Environment: ${setupResult.stringResult}');
    }

    await _loadInstalledPlugins();

    _isInitialized = true;
  }

  void _setupBridge() {
    _runtime.onMessage('console_log', (dynamic args) {
      if (kDebugMode) {
        // print('JS [LOG]: $args');
      }
    });

    _runtime.onMessage('console_error', (dynamic args) {
      if (kDebugMode) {
        print('JS [ERROR]: $args');
      }
    });

    _runtime.onMessage('http_request', (dynamic args) async {
      try {
        final map = args as Map<dynamic, dynamic>;
        final String url = map['url'];
        final String method = map['method'] ?? 'GET';
        final Map<String, dynamic>? headers =
            (map['headers'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>();

        // Handle body if present (e.g. for POST)
        final dynamic body = map['body'];

        final response = await _dio.request(
          url,
          data: body,
          options: Options(
            method: method,
            headers: headers,
            responseType: ResponseType.plain, 
            validateStatus: (status) => true, // Let JS handle errors
          ),
        );

        return {
          'status': response.statusCode,
          'data': response.data,
          'headers': response.headers.map.map((k, v) => MapEntry(k, v.join(','))),
        };
      } catch (e) {
        return {
          'status': 500,
          'error': e.toString(),
        };
      }
    });
  }

  Future<void> _loadInstalledPlugins() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pluginsDir = Directory(path.join(appDir.path, 'plugins'));

      if (!await pluginsDir.exists()) {
        await pluginsDir.create(recursive: true);
        return;
      }

      final files = pluginsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.js'));
      
      for (final file in files) {
        try {
          final jsCode = await file.readAsString();
          final manifest = await _parseManifest(jsCode);
          _plugins.add(Plugin(
            manifest: manifest,
            filePath: file.path,
            isEnabled: true, // Default to true for now
          ));
        } catch (e) {
          print('Failed to load plugin from ${file.path}: $e');
        }
      }
    } catch (e) {
      print('Error loading plugins: $e');
    }
  }

  Future<PluginManifest> _parseManifest(String jsCode) async {
    // We create a temporary runtime to parse the manifest safely without polluting the main runtime yet
    // Or we can just use regex if we want to be fast, but evaluating is safer for validity.
    // For now, let's assume we can evaluate it in the main runtime but wrapped in a scope or just check the variable.
    // A cleaner way for isolation is creating a quick temporary runtime.
    
    final tempRuntime = getJavascriptRuntime();
    try {
      final res = await tempRuntime.evaluateAsync(jsCode);
      if (res.isError) throw Exception(res.stringResult);
      
      final manifestJs = await tempRuntime.evaluateAsync('JSON.stringify(pluginManifest)');
      if (manifestJs.isError) throw Exception('pluginManifest not found');
      
      return PluginManifest.fromJson(jsonDecode(manifestJs.stringResult));
    } finally {
      tempRuntime.dispose();
    }
  }

  Future<void> installPlugin(String url) async {
    try {
      final response = await _dio.get(url);
      final jsCode = response.data.toString();

      // Validate by parsing
      final manifest = await _parseManifest(jsCode);

      // Save to disk
      final appDir = await getApplicationDocumentsDirectory();
      final pluginsDir = Directory(path.join(appDir.path, 'plugins'));
      if (!await pluginsDir.exists()) await pluginsDir.create(recursive: true);

      final filePath = path.join(pluginsDir.path, '${manifest.id}.js');
      await File(filePath).writeAsString(jsCode);

      // Add to memory
      // Check if already exists, update if so
      _plugins.removeWhere((p) => p.id == manifest.id);
      _plugins.add(Plugin(
        manifest: manifest,
        filePath: filePath,
        isEnabled: true,
      ));
      
      print('Installed plugin: ${manifest.name}');
    } catch (e) {
      print('Failed to install plugin: $e');
      rethrow;
    }
  }

  Future<List<StreamResponse>> getAllStreams(StreamRequest request) async {
    if (!_isInitialized) await init();

    final List<StreamResponse> allStreams = [];
    final requestJson = jsonEncode(request.toJson());

    // We execute plugins sequentially or parallel? 
    // JS Runtime is single threaded usually unless we have multiple runtimes. 
    // Using one runtime implies sequential execution if we load all code into it.
    // Ideally, we load the plugin code, run it, then maybe unload or just keep it if names don't collide.
    // To avoid collision, plugins should probably be wrapped or we reload the runtime.
    // For this prototype, let's assume plugins don't collide or we use a fresh runtime for the "Session".
    
    // Better approach for stability: Create a fresh runtime for this extraction session
    // Or, simpler: Load one plugin, run, reload runtime, load next.
    // Let's try: One runtime, but we wrap plugin code in a function scope if possible.
    // OR: Just re-initialize the runtime for the batch.
    
    // Let's use the existing _runtime but be careful.
    // Actually, loading all plugins into one global scope is risky if they use same global vars.
    // Let's create a ephemeral runtime for each plugin execution to be safe and robust.
    
    // However, creating runtimes is expensive.
    // Optimization: Plugins should be modules.
    
    // For this MVP: Iterate and use a new runtime for each plugin to ensure isolation.
    
    final enabledPlugins = _plugins.where((p) => p.isEnabled).toList();
    
    // Run in parallel? flutter_js runtimes are isolated.
    final futures = enabledPlugins.map((plugin) async {
      JavascriptRuntime? runner;
      try {
        runner = getJavascriptRuntime();
        
        // Setup bridge for this runner
        runner.onMessage('http_request', (args) async {
           // ... (same bridge logic)
           // Duplication is bad, but unavoidable if we want isolation without complex factory
           // For brevity, I will just copy the bridge logic or make it a static helper, 
           // but `runner` instance is needed.
           // Let's keep it simple: Use the main _runtime but risk collisions? 
           // No, risk of collision is high with 3rd party scripts.
           // I'll inline the bridge logic for now or refactor slightly.
           return _handleJsHttpRequest(args);
        });
        
        runner.onMessage('console_log', (args) { if (kDebugMode) print('[${plugin.name}] $args'); });
        runner.onMessage('console_error', (args) { if (kDebugMode) print('[${plugin.name} ERROR] $args'); });

        await runner.evaluateAsync(_baseJsEnv);
        
        // Load plugin code
        final code = await File(plugin.filePath).readAsString();
        await runner.evaluateAsync(code);
        
        // Execute
        final safeCode = '''
          (async () => {
            try {
              if (typeof getStreams !== 'function') return "[]";
              const res = await getStreams($requestJson);
              return JSON.stringify(res);
            } catch (e) {
              console.error(e.message);
              return "[]";
            }
          })();
        ''';
        
        final result = await runner.evaluateAsync(safeCode);
        if (result.isError) return <StreamResponse>[];
        
        final List<dynamic> raw = jsonDecode(result.stringResult);
        return raw.map((e) => StreamResponse.fromJson(e)).toList();

      } catch (e) {
        print('Error running plugin ${plugin.name}: $e');
        return <StreamResponse>[];
      } finally {
        runner?.dispose();
      }
    });

    final results = await Future.wait(futures);
    for (var list in results) {
      allStreams.addAll(list);
    }

    return allStreams;
  }

  Future<Map<String, dynamic>> _handleJsHttpRequest(dynamic args) async {
    try {
        final map = args as Map<dynamic, dynamic>;
        final String url = map['url'];
        final String method = map['method'] ?? 'GET';
        final Map<String, dynamic>? headers =
            (map['headers'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>();
        final dynamic body = map['body'];

        final response = await _dio.request(
          url,
          data: body,
          options: Options(
            method: method,
            headers: headers,
            responseType: ResponseType.plain, 
            validateStatus: (status) => true,
          ),
        );

        return {
          'status': response.statusCode,
          'data': response.data,
          'headers': response.headers.map.map((k, v) => MapEntry(k, v.join(','))),
        };
      } catch (e) {
        return {
          'status': 500,
          'error': e.toString(),
        };
      }
  }

  void dispose() {
    if (_isInitialized) {
      _runtime.dispose();
    }
  }

  static const String _baseJsEnv = '''
    var console = {
      log: function(msg) { sendMessage('console_log', JSON.stringify(msg)); },
      error: function(msg) { sendMessage('console_error', JSON.stringify(msg)); }
    };

    async function fetch(url, options = {}) {
      const response = await sendMessage('http_request', {
        url: url,
        method: options.method || 'GET',
        headers: options.headers || {},
        body: options.body
      });
      
      if (response.error) throw new Error(response.error);
      
      return {
        ok: response.status >= 200 && response.status < 300,
        status: response.status,
        text: () => Promise.resolve(response.data),
        json: () => Promise.resolve(JSON.parse(response.data))
      };
    }
  ''';
}