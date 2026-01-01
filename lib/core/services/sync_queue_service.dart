import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream/core/services/sync_service.dart';
import 'package:stream/core/providers/library_provider.dart';
import 'package:stream/features/home/models/tmdb_media.dart';

enum SyncOperationType { addToWatchlist, removeFromWatchlist, markWatched, removeFromHistory, setRating, removeRating, updateStatus, enrichMedia }

class SyncOperation {
  final SyncOperationType operationType;
  final int mediaId;
  final String mediaType;
  final String mediaTitle;
  final int? rating;
  final String? status;
  final DateTime? watchedAt;
  final DateTime timestamp;

  SyncOperation({
    required this.operationType,
    required this.mediaId,
    required this.mediaType,
    required this.mediaTitle,
    this.rating,
    this.status,
    this.watchedAt,
    required this.timestamp,
  });

  String get id => '${mediaId}_${mediaType}_${operationType.name}_${timestamp.millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
    'operationType': operationType.index,
    'mediaId': mediaId,
    'mediaType': mediaType,
    'mediaTitle': mediaTitle,
    'rating': rating,
    'status': status,
    'watchedAt': watchedAt?.toIso8601String(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    operationType: SyncOperationType.values[json['operationType']],
    mediaId: json['mediaId'],
    mediaType: json['mediaType'],
    mediaTitle: json['mediaTitle'],
    rating: json['rating'],
    status: json['status'],
    watchedAt: json['watchedAt'] != null ? DateTime.parse(json['watchedAt']) : null,
    timestamp: DateTime.parse(json['timestamp']),
  );

  TmdbMedia toMedia() => TmdbMedia(
    id: mediaId,
    title: mediaTitle,
    posterPath: '',
    backdropPath: '',
    overview: '',
    releaseDate: '',
    voteAverage: 0,
    type: mediaType,
  );

  LibraryStatus? get libraryStatus {
    if (status == null) return null;
    return LibraryStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => LibraryStatus.planned,
    );
  }
}

class SyncQueueService {
  static const String _queueKey = 'sync_queue';
  static const String _lastSyncKey = 'last_sync_time';

  static Future<List<SyncOperation>> getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_queueKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => SyncOperation.fromJson(e)).toList();
    } catch (e) {
      debugPrint('SyncQueue: Error loading queue: $e');
      return [];
    }
  }

  static Future<void> addOperation(SyncOperation operation) async {
    final operations = await getPendingOperations();
    operations.add(operation);
    await _saveQueue(operations);
  }

  static Future<void> removeOperation(String id) async {
    final operations = await getPendingOperations();
    operations.removeWhere((op) => op.id == id);
    await _saveQueue(operations);
  }

  static Future<void> _saveQueue(List<SyncOperation> operations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = operations.map((e) => e.toJson()).toList();
    await prefs.setString(_queueKey, json.encode(jsonList));
  }

  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  static Future<int> processPendingOperations(SyncService syncService) async {
    final operations = await getPendingOperations();
    if (operations.isEmpty) return 0;

    int processed = 0;
    for (final op in operations) {
      bool success = false;
      final media = op.toMedia();
      try {
        switch (op.operationType) {
          case SyncOperationType.addToWatchlist:
            success = await syncService.addToWatchlist(media);
            break;
          case SyncOperationType.removeFromWatchlist:
            success = await syncService.removeFromWatchlist(media);
            break;
          case SyncOperationType.markWatched:
            success = await syncService.markAsWatched(media, watchedAt: op.watchedAt);
            break;
          case SyncOperationType.removeFromHistory:
            success = await syncService.removeFromHistory(media);
            break;
          case SyncOperationType.setRating:
            success = await syncService.setRating(media, op.rating ?? 0);
            break;
          case SyncOperationType.removeRating:
            success = await syncService.removeRating(media);
            break;
          case SyncOperationType.updateStatus:
            if (op.libraryStatus != null) {
              success = await syncService.setStatus(media, op.libraryStatus!);
            }
            break;
          case SyncOperationType.enrichMedia:
            success = true;
            break;
        }

        if (success) {
          await removeOperation(op.id);
          processed++;
        }
      } catch (e) {
        debugPrint('SyncQueue: Error processing operation ${op.id}: $e');
      }
    }

    return processed;
  }

  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  static Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  static String generateOperationId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
