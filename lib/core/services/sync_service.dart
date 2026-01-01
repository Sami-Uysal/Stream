import 'package:stream/features/home/models/tmdb_media.dart';
import 'package:stream/core/providers/library_provider.dart';

enum SyncProvider { none, trakt, simkl }

class SyncItem {
  final int tmdbId;
  final String? imdbId;
  final String title;
  final String mediaType;
  final DateTime? watchedAt;
  final int? rating;
  final String? status;

  SyncItem({
    required this.tmdbId,
    this.imdbId,
    required this.title,
    required this.mediaType,
    this.watchedAt,
    this.rating,
    this.status,
  });

  SyncItem copyWith({
    int? tmdbId,
    String? imdbId,
    String? title,
    String? mediaType,
    DateTime? watchedAt,
    int? rating,
    String? status,
  }) {
    return SyncItem(
      tmdbId: tmdbId ?? this.tmdbId,
      imdbId: imdbId ?? this.imdbId,
      title: title ?? this.title,
      mediaType: mediaType ?? this.mediaType,
      watchedAt: watchedAt ?? this.watchedAt,
      rating: rating ?? this.rating,
      status: status ?? this.status,
    );
  }

  LibraryStatus? toLibraryStatus() {
    if (status == null) return null;
    switch (status!.toLowerCase()) {
      case 'watching':
      case 'currently_watching':
        return LibraryStatus.watching;
      case 'completed':
      case 'watched':
        return LibraryStatus.completed;
      case 'on_hold':
      case 'hold':
        return LibraryStatus.onHold;
      case 'dropped':
        return LibraryStatus.dropped;
      case 'plantowatch':
      case 'plan_to_watch':
      case 'watchlist':
        return LibraryStatus.planned;
      default:
        return null;
    }
  }

  static String fromLibraryStatus(LibraryStatus status) {
    switch (status) {
      case LibraryStatus.watching:
        return 'watching';
      case LibraryStatus.completed:
        return 'completed';
      case LibraryStatus.onHold:
        return 'on_hold';
      case LibraryStatus.dropped:
        return 'dropped';
      case LibraryStatus.planned:
        return 'plantowatch';
    }
  }
}

abstract class SyncService {
  Future<List<SyncItem>> getWatchlist();
  Future<List<SyncItem>> getWatchedHistory();
  Future<List<SyncItem>> getRatings();
  Future<List<SyncItem>> getAllItems();
  Future<bool> addToWatchlist(TmdbMedia media);
  Future<bool> removeFromWatchlist(TmdbMedia media);
  Future<bool> markAsWatched(TmdbMedia media, {DateTime? watchedAt});
  Future<bool> removeFromHistory(TmdbMedia media);
  Future<bool> setRating(TmdbMedia media, int rating);
  Future<bool> removeRating(TmdbMedia media);
  Future<bool> setStatus(TmdbMedia media, LibraryStatus status);
}
