import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stream/core/services/sync_service.dart';
import 'package:stream/core/services/simkl_auth_service.dart';
import 'package:stream/core/providers/library_provider.dart';
import 'package:stream/features/home/models/tmdb_media.dart';

class SimklSyncService implements SyncService {
  final Dio _dio = Dio();
  
  static const String _baseUrl = 'https://api.simkl.com';
  String get _clientId => dotenv.env['SIMKL_CLIENT_ID'] ?? '';

  Options _authOptions(String token) => Options(
    headers: {
      'Content-Type': 'application/json',
      'simkl-api-key': _clientId,
      'Authorization': 'Bearer $token',
    },
  );

  @override
  Future<List<SyncItem>> getWatchlist() async {
    try {
      final token = await SimklAuthService.getValidAccessToken();
      if (token == null) return [];

      final response = await _dio.get(
        '$_baseUrl/sync/all-items',
        queryParameters: {'status': 'plantowatch'},
        options: _authOptions(token),
      );

      final items = <SyncItem>[];
      final data = response.data;

      if (data['movies'] != null) {
        for (final movie in data['movies']) {
          items.add(SyncItem(
            tmdbId: movie['ids']?['tmdb'] ?? 0,
            imdbId: movie['ids']?['imdb'],
            title: movie['title'] ?? '',
            mediaType: 'movie',
            status: 'plantowatch',
          ));
        }
      }

      if (data['shows'] != null) {
        for (final show in data['shows']) {
          items.add(SyncItem(
            tmdbId: show['ids']?['tmdb'] ?? 0,
            imdbId: show['ids']?['imdb'],
            title: show['title'] ?? '',
            mediaType: 'tv',
            status: 'plantowatch',
          ));
        }
      }

      return items;
    } catch (e) {
      debugPrint('Simkl getWatchlist error: $e');
      return [];
    }
  }

  @override
  Future<List<SyncItem>> getWatchedHistory() async {
    try {
      final token = await SimklAuthService.getValidAccessToken();
      if (token == null) return [];

      final response = await _dio.get(
        '$_baseUrl/sync/all-items',
        queryParameters: {'status': 'completed'},
        options: _authOptions(token),
      );

      final items = <SyncItem>[];
      final data = response.data;

      if (data['movies'] != null) {
        for (final movie in data['movies']) {
          items.add(SyncItem(
            tmdbId: movie['ids']?['tmdb'] ?? 0,
            imdbId: movie['ids']?['imdb'],
            title: movie['title'] ?? '',
            mediaType: 'movie',
            status: 'completed',
            watchedAt: movie['last_watched_at'] != null 
                ? DateTime.tryParse(movie['last_watched_at']) 
                : null,
          ));
        }
      }

      if (data['shows'] != null) {
        for (final show in data['shows']) {
          items.add(SyncItem(
            tmdbId: show['ids']?['tmdb'] ?? 0,
            imdbId: show['ids']?['imdb'],
            title: show['title'] ?? '',
            mediaType: 'tv',
            status: 'completed',
            watchedAt: show['last_watched_at'] != null 
                ? DateTime.tryParse(show['last_watched_at']) 
                : null,
          ));
        }
      }

      return items;
    } catch (e) {
      debugPrint('Simkl getWatchedHistory error: $e');
      return [];
    }
  }

  @override
  Future<List<SyncItem>> getRatings() async {
    try {
      final token = await SimklAuthService.getValidAccessToken();
      if (token == null) return [];

      final response = await _dio.get(
        '$_baseUrl/sync/ratings',
        options: _authOptions(token),
      );

      final items = <SyncItem>[];
      final data = response.data;

      if (data['movies'] != null) {
        for (final movie in data['movies']) {
          items.add(SyncItem(
            tmdbId: movie['ids']?['tmdb'] ?? 0,
            imdbId: movie['ids']?['imdb'],
            title: movie['title'] ?? '',
            mediaType: 'movie',
            rating: movie['rating'],
          ));
        }
      }

      if (data['shows'] != null) {
        for (final show in data['shows']) {
          items.add(SyncItem(
            tmdbId: show['ids']?['tmdb'] ?? 0,
            imdbId: show['ids']?['imdb'],
            title: show['title'] ?? '',
            mediaType: 'tv',
            rating: show['rating'],
          ));
        }
      }

      return items;
    } catch (e) {
      debugPrint('Simkl getRatings error: $e');
      return [];
    }
  }

  Map<String, dynamic> _buildMediaObject(TmdbMedia media, {String? status, int? rating}) {
    final type = media.isMovie ? 'movies' : 'shows';
    final item = <String, dynamic>{
      'ids': {
        'tmdb': media.id,
        if (media.imdbId != null) 'imdb': media.imdbId,
      },
      'title': media.title,
    };
    if (status != null) item['to'] = status;
    if (rating != null) item['rating'] = rating;
    return {type: [item]};
  }

  @override
  Future<bool> addToWatchlist(TmdbMedia media) async {
    try {
      final token = await SimklAuthService.getValidAccessToken();
      if (token == null) return false;

      await _dio.post(
        '$_baseUrl/sync/add-to-list',
        data: _buildMediaObject(media, status: 'plantowatch'),
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Simkl addToWatchlist error: $e');
      return false;
    }
  }

  @override
  Future<bool> removeFromWatchlist(TmdbMedia media) async {
    try {
      final token = await SimklAuthService.getValidAccessToken();
      if (token == null) return false;

      final type = media.isMovie ? 'movies' : 'shows';
      await _dio.post(
        '$_baseUrl/sync/history/remove',
        data: {
          type: [
            {'ids': {'tmdb': media.id}}
          ]
        },
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Simkl removeFromWatchlist error: $e');
      return false;
    }
  }

  @override
  Future<bool> markAsWatched(TmdbMedia media, {DateTime? watchedAt}) async {
    try {
      final token = await SimklAuthService.getValidAccessToken();
      if (token == null) return false;

      await _dio.post(
        '$_baseUrl/sync/add-to-list',
        data: _buildMediaObject(media, status: 'completed'),
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Simkl markAsWatched error: $e');
      return false;
    }
  }

  @override
  Future<bool> removeFromHistory(TmdbMedia media) async {
    return removeFromWatchlist(media);
  }

  @override
  Future<bool> setRating(TmdbMedia media, int rating) async {
    try {
      final token = await SimklAuthService.getValidAccessToken();
      if (token == null) return false;

      await _dio.post(
        '$_baseUrl/sync/ratings',
        data: _buildMediaObject(media, rating: rating),
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Simkl setRating error: $e');
      return false;
    }
  }

  @override
  Future<bool> removeRating(TmdbMedia media) async {
    try {
      final token = await SimklAuthService.getValidAccessToken();
      if (token == null) return false;

      final type = media.isMovie ? 'movies' : 'shows';
      await _dio.post(
        '$_baseUrl/sync/ratings/remove',
        data: {
          type: [
            {'ids': {'tmdb': media.id}}
          ]
        },
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Simkl removeRating error: $e');
      return false;
    }
  }

  @override
  Future<List<SyncItem>> getAllItems() async {
    try {
      final token = await SimklAuthService.getValidAccessToken();
      if (token == null) return [];

      final response = await _dio.get(
        '$_baseUrl/sync/all-items',
        options: _authOptions(token),
      );

      final items = <SyncItem>[];
      final data = response.data;

      if (data['movies'] != null) {
        for (final movie in data['movies']) {
          items.add(SyncItem(
            tmdbId: movie['ids']?['tmdb'] ?? 0,
            imdbId: movie['ids']?['imdb'],
            title: movie['title'] ?? '',
            mediaType: 'movie',
            status: movie['status'],
            rating: movie['user_rating'],
            watchedAt: movie['last_watched_at'] != null 
                ? DateTime.tryParse(movie['last_watched_at']) 
                : null,
          ));
        }
      }

      if (data['shows'] != null) {
        for (final show in data['shows']) {
          items.add(SyncItem(
            tmdbId: show['ids']?['tmdb'] ?? 0,
            imdbId: show['ids']?['imdb'],
            title: show['title'] ?? '',
            mediaType: 'tv',
            status: show['status'],
            rating: show['user_rating'],
            watchedAt: show['last_watched_at'] != null 
                ? DateTime.tryParse(show['last_watched_at']) 
                : null,
          ));
        }
      }

      return items;
    } catch (e) {
      debugPrint('Simkl getAllItems error: $e');
      return [];
    }
  }

  String _libraryStatusToSimkl(LibraryStatus status) {
    switch (status) {
      case LibraryStatus.planned:
        return 'plantowatch';
      case LibraryStatus.watching:
        return 'watching';
      case LibraryStatus.completed:
        return 'completed';
      case LibraryStatus.onHold:
        return 'hold';
      case LibraryStatus.dropped:
        return 'dropped';
    }
  }

  @override
  Future<bool> setStatus(TmdbMedia media, LibraryStatus status) async {
    try {
      final token = await SimklAuthService.getValidAccessToken();
      if (token == null) return false;

      final simklStatus = _libraryStatusToSimkl(status);
      await _dio.post(
        '$_baseUrl/sync/add-to-list',
        data: _buildMediaObject(media, status: simklStatus),
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Simkl setStatus error: $e');
      return false;
    }
  }
}
