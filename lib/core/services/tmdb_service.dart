import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:stream/core/tmdb/tmdb_constants.dart';
import 'package:stream/features/home/models/tmdb_media.dart';

class TmdbService {
  final Dio _dio = Dio();

  TmdbService() {
    _dio.options.baseUrl = TmdbConstants.baseUrl;
    // Workaround for cloudfront IP direct access
    _dio.options.headers['Host'] = 'api.themoviedb.org';
    _dio.options.queryParameters = {
      'api_key': TmdbConstants.apiKey,
      'language': TmdbConstants.defaultLanguage,
    };
  }

  Future<List<TmdbMedia>> getPlatformCatalog({
    required int providerId,
    String type = 'movie',
    String region = TmdbConstants.defaultRegion,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/discover/$type',
        queryParameters: {
          'with_watch_providers': providerId,
          'watch_region': region,
          'sort_by': 'popularity.desc',
          'page': page,
        },
      );

      final List results = response.data['results'];
      return results.map((json) => TmdbMedia.fromJson(json, type)).toList();
    } catch (e) {
      debugPrint('Error fetching catalog for provider $providerId: $e');
      return [];
    }
  }

  Future<List<TmdbMedia>> getTrending({String type = 'movie', String timeWindow = 'week'}) async {
    try {
      final response = await _dio.get('/trending/$type/$timeWindow');
      final List results = response.data['results'];
      return results.map((json) => TmdbMedia.fromJson(json, type)).toList();
    } catch (e) {
      debugPrint('Error fetching trending: $e');
      return [];
    }
  }
}
