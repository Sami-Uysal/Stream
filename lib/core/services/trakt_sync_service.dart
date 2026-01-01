import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stream/core/services/sync_service.dart';
import 'package:stream/core/services/trakt_auth_service.dart';
import 'package:stream/core/providers/library_provider.dart';
import 'package:stream/features/home/models/tmdb_media.dart';

class TraktSyncService implements SyncService {
  final Dio _dio = Dio();
  
  static const String _baseUrl = 'https://api.trakt.tv';
  String get _clientId => dotenv.env['TRAKT_CLIENT_ID'] ?? '';

  Options _authOptions(String token) => Options(
    headers: {
      'Content-Type': 'application/json',
      'trakt-api-version': '2',
      'trakt-api-key': _clientId,
      'Authorization': 'Bearer $token',
    },
  );

  @override
  Future<List<SyncItem>> getWatchlist() async {
    try {
      final token = await TraktAuthService.getValidAccessToken();
      if (token == null) return [];

      final movies = await _dio.get(
        '$_baseUrl/sync/watchlist/movies',
        options: _authOptions(token),
      );
      final shows = await _dio.get(
        '$_baseUrl/sync/watchlist/shows',
        options: _authOptions(token),
      );

      final items = <SyncItem>[];
      
      for (final item in movies.data) {
        final movie = item['movie'];
        items.add(SyncItem(
          tmdbId: movie['ids']['tmdb'] ?? 0,
          imdbId: movie['ids']['imdb'],
          title: movie['title'] ?? '',
          mediaType: 'movie',
        ));
      }
      
      for (final item in shows.data) {
        final show = item['show'];
        items.add(SyncItem(
          tmdbId: show['ids']['tmdb'] ?? 0,
          imdbId: show['ids']['imdb'],
          title: show['title'] ?? '',
          mediaType: 'tv',
        ));
      }

      return items;
    } catch (e) {
      debugPrint('Trakt getWatchlist error: $e');
      return [];
    }
  }

  @override
  Future<List<SyncItem>> getWatchedHistory() async {
    try {
      final token = await TraktAuthService.getValidAccessToken();
      if (token == null) return [];

      final movies = await _dio.get(
        '$_baseUrl/sync/watched/movies',
        options: _authOptions(token),
      );
      final shows = await _dio.get(
        '$_baseUrl/sync/watched/shows',
        options: _authOptions(token),
      );

      final items = <SyncItem>[];
      
      for (final item in movies.data) {
        final movie = item['movie'];
        items.add(SyncItem(
          tmdbId: movie['ids']['tmdb'] ?? 0,
          imdbId: movie['ids']['imdb'],
          title: movie['title'] ?? '',
          mediaType: 'movie',
          watchedAt: item['last_watched_at'] != null 
              ? DateTime.parse(item['last_watched_at']) 
              : null,
        ));
      }
      
      for (final item in shows.data) {
        final show = item['show'];
        items.add(SyncItem(
          tmdbId: show['ids']['tmdb'] ?? 0,
          imdbId: show['ids']['imdb'],
          title: show['title'] ?? '',
          mediaType: 'tv',
          watchedAt: item['last_watched_at'] != null 
              ? DateTime.parse(item['last_watched_at']) 
              : null,
        ));
      }

      return items;
    } catch (e) {
      debugPrint('Trakt getWatchedHistory error: $e');
      return [];
    }
  }

  @override
  Future<List<SyncItem>> getRatings() async {
    try {
      final token = await TraktAuthService.getValidAccessToken();
      if (token == null) return [];

      final movies = await _dio.get(
        '$_baseUrl/sync/ratings/movies',
        options: _authOptions(token),
      );
      final shows = await _dio.get(
        '$_baseUrl/sync/ratings/shows',
        options: _authOptions(token),
      );

      final items = <SyncItem>[];
      
      for (final item in movies.data) {
        final movie = item['movie'];
        items.add(SyncItem(
          tmdbId: movie['ids']['tmdb'] ?? 0,
          imdbId: movie['ids']['imdb'],
          title: movie['title'] ?? '',
          mediaType: 'movie',
          rating: item['rating'],
        ));
      }
      
      for (final item in shows.data) {
        final show = item['show'];
        items.add(SyncItem(
          tmdbId: show['ids']['tmdb'] ?? 0,
          imdbId: show['ids']['imdb'],
          title: show['title'] ?? '',
          mediaType: 'tv',
          rating: item['rating'],
        ));
      }

      return items;
    } catch (e) {
      debugPrint('Trakt getRatings error: $e');
      return [];
    }
  }

  Map<String, dynamic> _buildMediaObject(TmdbMedia media) {
    final type = media.isMovie ? 'movies' : 'shows';
    final item = {
      'ids': {
        'tmdb': media.id,
        if (media.imdbId != null) 'imdb': media.imdbId,
      }
    };
    return {type: [item]};
  }

  @override
  Future<bool> addToWatchlist(TmdbMedia media) async {
    try {
      final token = await TraktAuthService.getValidAccessToken();
      if (token == null) return false;

      await _dio.post(
        '$_baseUrl/sync/watchlist',
        data: _buildMediaObject(media),
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Trakt addToWatchlist error: $e');
      return false;
    }
  }

  @override
  Future<bool> removeFromWatchlist(TmdbMedia media) async {
    try {
      final token = await TraktAuthService.getValidAccessToken();
      if (token == null) return false;

      await _dio.post(
        '$_baseUrl/sync/watchlist/remove',
        data: _buildMediaObject(media),
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Trakt removeFromWatchlist error: $e');
      return false;
    }
  }

  @override
  Future<bool> markAsWatched(TmdbMedia media, {DateTime? watchedAt}) async {
    try {
      final token = await TraktAuthService.getValidAccessToken();
      if (token == null) return false;

      final type = media.isMovie ? 'movies' : 'shows';
      final item = {
        'ids': {
          'tmdb': media.id,
          if (media.imdbId != null) 'imdb': media.imdbId,
        },
        if (watchedAt != null) 'watched_at': watchedAt.toUtc().toIso8601String(),
      };

      await _dio.post(
        '$_baseUrl/sync/history',
        data: {type: [item]},
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Trakt markAsWatched error: $e');
      return false;
    }
  }

  @override
  Future<bool> removeFromHistory(TmdbMedia media) async {
    try {
      final token = await TraktAuthService.getValidAccessToken();
      if (token == null) return false;

      await _dio.post(
        '$_baseUrl/sync/history/remove',
        data: _buildMediaObject(media),
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Trakt removeFromHistory error: $e');
      return false;
    }
  }

  @override
  Future<bool> setRating(TmdbMedia media, int rating) async {
    try {
      final token = await TraktAuthService.getValidAccessToken();
      if (token == null) return false;

      final type = media.isMovie ? 'movies' : 'shows';
      final item = {
        'ids': {
          'tmdb': media.id,
          if (media.imdbId != null) 'imdb': media.imdbId,
        },
        'rating': rating,
      };

      await _dio.post(
        '$_baseUrl/sync/ratings',
        data: {type: [item]},
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Trakt setRating error: $e');
      return false;
    }
  }

  @override
  Future<bool> removeRating(TmdbMedia media) async {
    try {
      final token = await TraktAuthService.getValidAccessToken();
      if (token == null) return false;

      await _dio.post(
        '$_baseUrl/sync/ratings/remove',
        data: _buildMediaObject(media),
        options: _authOptions(token),
      );
      return true;
    } catch (e) {
      debugPrint('Trakt removeRating error: $e');
      return false;
    }
  }

  @override
  Future<List<SyncItem>> getAllItems() async {
    try {
      final token = await TraktAuthService.getValidAccessToken();
      if (token == null) return [];

      final watchlist = await getWatchlist();
      final watched = await getWatchedHistory();
      final ratings = await getRatings();

      final Map<String, SyncItem> itemMap = {};

      for (final item in watchlist) {
        final key = '${item.mediaType}_${item.tmdbId}';
        itemMap[key] = item.copyWith(status: 'watchlist');
      }

      for (final item in watched) {
        final key = '${item.mediaType}_${item.tmdbId}';
        if (itemMap.containsKey(key)) {
          itemMap[key] = itemMap[key]!.copyWith(
            status: 'completed',
            watchedAt: item.watchedAt,
          );
        } else {
          itemMap[key] = item.copyWith(status: 'completed');
        }
      }

      for (final item in ratings) {
        final key = '${item.mediaType}_${item.tmdbId}';
        if (itemMap.containsKey(key)) {
          itemMap[key] = itemMap[key]!.copyWith(rating: item.rating);
        } else {
          itemMap[key] = item;
        }
      }

      return itemMap.values.toList();
    } catch (e) {
      debugPrint('Trakt getAllItems error: $e');
      return [];
    }
  }

  @override
  Future<bool> setStatus(TmdbMedia media, LibraryStatus status) async {
    try {
      switch (status) {
        case LibraryStatus.planned:
          await removeFromHistory(media);
          return await addToWatchlist(media);
        case LibraryStatus.watching:
          await removeFromWatchlist(media);
          return await addToWatchlist(media);
        case LibraryStatus.completed:
          await removeFromWatchlist(media);
          return await markAsWatched(media);
        case LibraryStatus.onHold:
          return await addToWatchlist(media);
        case LibraryStatus.dropped:
          await removeFromWatchlist(media);
          await removeFromHistory(media);
          return true;
      }
    } catch (e) {
      debugPrint('Trakt setStatus error: $e');
      return false;
    }
  }
}
