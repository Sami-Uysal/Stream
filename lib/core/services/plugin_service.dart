import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:stream/features/plugins/models/plugin_manifest.dart';
import 'package:stream/features/plugins/models/stream_request.dart';
import 'package:stream/features/plugins/models/stream_response.dart';

class PluginService {
  late JavascriptRuntime _runtime;
  final Dio _dio = Dio();
  final List<PluginManifest> _loadedManifests = [];

  bool _isInitialized = false;

  PluginService();

  Future<void> init() async {
    if (_isInitialized) return;

    _runtime = getJavascriptRuntime();

    _runtime.onMessage('console_log', (dynamic args) {
      if (kDebugMode) {
        print('JS [LOG]: $args');
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

        final response = await _dio.request(
          url,
          options: Options(
            method: method,
            headers: headers,
            responseType: ResponseType.plain, 
          ),
        );

        return {
          'status': response.statusCode,
          'data': response.data,
          'headers': response.headers.map,
        };
      } catch (e) {
        return {
          'status': 500,
          'error': e.toString(),
        };
      }
    });

    final setupResult = await _runtime.evaluateAsync(_baseJsEnv);
    if (setupResult.isError) {
      throw Exception('Failed to initialize JS Environment: ${setupResult.stringResult}');
    }

    _isInitialized = true;
  }


  Future<PluginManifest> loadPlugin(String jsCode) async {
    if (!_isInitialized) await init();

    final result = await _runtime.evaluateAsync(jsCode);
    if (result.isError) {
      throw Exception('JS Execution Error: ${result.stringResult}');
    }


    final manifestJs = await _runtime.evaluateAsync('JSON.stringify(pluginManifest)');
    if (manifestJs.isError) {
       throw Exception('Plugin did not define "pluginManifest".');
    }

    try {
      final jsonMap = jsonDecode(manifestJs.stringResult);
      final manifest = PluginManifest.fromJson(jsonMap);
      _loadedManifests.add(manifest);
      return manifest;
    } catch (e) {
      throw Exception('Failed to parse plugin manifest: $e');
    }
  }

  Future<List<StreamResponse>> extractStreams(StreamRequest request) async {
    if (!_isInitialized) await init();

    final requestJson = jsonEncode(request.toJson());
    
    
    final code = 'getStreams($requestJson)';
    final result = await _runtime.evaluateAsync(code);

    if (result.isError) {
      print('JS Error in getStreams: ${result.stringResult}');
      return [];
    }

    final safeCode = '''
      (async () => {
        try {
          const res = await getStreams($requestJson);
          return JSON.stringify(res);
        } catch (e) {
          console.error(e);
          return "[]";
        }
      })();
    ''';
    
    final jsonResult = await _runtime.evaluateAsync(safeCode);
    
    if (jsonResult.isError) return [];

    try {
      final List<dynamic> rawList = jsonDecode(jsonResult.stringResult);
      return rawList.map((e) => StreamResponse.fromJson(e)).toList();
    } catch (e) {
      print('Error parsing stream response: $e');
      return [];
    }
  }

  void dispose() {
    if (_isInitialized) {
      _runtime.dispose();
    }
  }

  static const String _baseJsEnv = '''
    // Polyfill console
    var console = {
      log: function(msg) { sendMessage('console_log', JSON.stringify(msg)); },
      error: function(msg) { sendMessage('console_error', JSON.stringify(msg)); }
    };

    // Bridge Fetch API (simplified)
    async function fetch(url, options = {}) {
      const response = await sendMessage('http_request', {
        url: url,
        method: options.method || 'GET',
        headers: options.headers || {}
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
