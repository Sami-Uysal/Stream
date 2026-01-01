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

  Future<TmdbMedia?> getMovieDetails({
    required int id,
    String type = 'movie',
    String? language,
  }) async {
    try {
      final response = await _dio.get(
        '/$type/$id',
        queryParameters: {
          'append_to_response': 'external_ids,credits',
          if (language != null) 'language': language,
        },
      );
      return TmdbMedia.fromJson(response.data, type);
    } catch (e) {
      debugPrint('Error fetching details for $id: $e');
      return null;
    }
  }

  Future<List<TmdbMedia>> search(String query) async {
    try {
      final response = await _dio.get(
        '/search/multi',
        queryParameters: {
          'query': query,
        },
      );

      final List results = response.data['results'];
      return results
          .where((item) => item['media_type'] == 'movie' || item['media_type'] == 'tv')
          .map((item) => TmdbMedia.fromJson(item, item['media_type']))
          .toList();
    } catch (e) {
      debugPrint('Error searching: $e');
      return [];
    }
  }

  /// Şu an vizyonda olan filmler
  Future<List<TmdbMedia>> getNowPlaying({String region = TmdbConstants.defaultRegion}) async {
    try {
      final response = await _dio.get(
        '/movie/now_playing',
        queryParameters: {
          'region': region,
        },
      );
      final List results = response.data['results'];
      return results.map((json) => TmdbMedia.fromJson(json, 'movie')).toList();
    } catch (e) {
      debugPrint('Error fetching now playing: $e');
      return [];
    }
  }

  /// Yakında gelecek filmler
  Future<List<TmdbMedia>> getUpcoming({String region = TmdbConstants.defaultRegion}) async {
    try {
      final response = await _dio.get(
        '/movie/upcoming',
        queryParameters: {
          'region': region,
        },
      );
      final List results = response.data['results'];
      return results.map((json) => TmdbMedia.fromJson(json, 'movie')).toList();
    } catch (e) {
      debugPrint('Error fetching upcoming: $e');
      return [];
    }
  }

  /// En çok oy alan içerikler
  Future<List<TmdbMedia>> getTopRated({String type = 'movie'}) async {
    try {
      final response = await _dio.get('/$type/top_rated');
      final List results = response.data['results'];
      return results.map((json) => TmdbMedia.fromJson(json, type)).toList();
    } catch (e) {
      debugPrint('Error fetching top rated: $e');
      return [];
    }
  }

  /// Popüler içerikler
  Future<List<TmdbMedia>> getPopular({String type = 'movie'}) async {
    try {
      final response = await _dio.get('/$type/popular');
      final List results = response.data['results'];
      return results.map((json) => TmdbMedia.fromJson(json, type)).toList();
    } catch (e) {
      debugPrint('Error fetching popular: $e');
      return [];
    }
  }
}
